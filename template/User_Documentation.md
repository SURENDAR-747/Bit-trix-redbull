Team Redbull     Documentation

Instruction set table


Mnemonic
Binary Opcode
ALU Operation (alu_op)
Hardware Action
MAC
0001
00
Rd = (Rd \times Rs2) + Rd
LDW
0010
N/A
Rd = RAM[Rs2]
STW
0011
N/A
RAM[Rs2] = Rs1
SUB
0100
01
Rd = Rd - Rs2
DIV
0101
10
Rd = Rd / Rs2
CLR
0110
N/A
Rd = 0
MOV
0111
N/A
Rd = Rs2




1. Datapath Explanation
The datapath is designed as a bus-oriented architecture that facilitates the movement of 8-bit data between the Synchronous RAM, a 4-slot Register File, and a multi-function ALU.
Instruction Fetch & Decode: The instr_decoder receives an 8-bit instruction and splits it into a 4-bit opcode and two 2-bit register addresses (rd, rs1, rs2).
Operand Routing: The Register File (rf_inst) outputs two operands (rs1_data, rs2_data) based on the decoder's addresses . these are fed directly into the ALU.
Arithmetic Execution: The ALU performs operations (MAC, SUB, DIV) based on the alu_op signal. For MAC operations, it specifically uses a third input c (typically the current write data or an accumulator value).
Result Writeback: The ALU output is truncated to 8 bits and can be written back into the Register File or stored directly into RAM at the address specified by the FSM.

2. Register Usage Strategy
The system utilizes a 4-register file (R0 to R3) to manage the recursive variables required for the deconvolution algorithm.
R0 (Constant/Divisor): Typically reserved for x[0]. Since every h[n] calculation requires division by $x[0]$, keeping it in a register avoids redundant RAM reads.
R1 (Accumulator): Acts as the primary "Sum" register for the summation sum h[n-k]x[k]. It is cleared at the start of each n iteration.
R2 (Input/Buffer): Used to hold the current y[n] sample fetched from RAM. During the MAC loop, it may temporarily store h[n-k] values.
R3 (Temporary/Intermediate): Used to store intermediate x[k] values during the loop or the result of the (y[n] - \text{Sum}) subtraction before the final division.

3. Memory Access Strategy
The system employs a Synchronous RAM strategy with defined address offsets to prevent data collisions during recursion.
Address Partitioning:
0–63: Input Signal x[n].
64–127: Input Signal y[n].
128–255: Output/Computed Signal h[n].
Synchronous Latency Handling: Because the RAM is clocked, an address set in State A only produces valid data in State B. The FSM in top.v accounts for this by using intermediate states to "wait" for the RAM read data before writing it to a register.
Recursive Retrieval: To compute h[n], the datapath fetches x[k] from the lower bank and $h[n-k]$ from the upper bank (128+) simultaneously within the summation loop.

4. Overflow and Saturation Documentation
The arithmetic units are designed for 8-bit wrap-around logic, which requires careful software-side data scaling.
MAC Overflow: The MAC unit calculates (a \times b) + c. While the internal multiplication of two 8-bit numbers results in a 16-bit value, the final result stored is the lower 8 bits.
Subtraction Underflow: The sub_res performs standard 8-bit subtraction. If y[n] < \text{Sum}, the result will wrap around (e.g., 0 - 1 = 255) rather than saturating at zero.
Division Constraints:
Zero-Check: The ALU includes a hardware check to prevent division by zero; if the divisor (b) is 0, the output is forced to 0.
Precision: Division is integer-based (truncating the remainder).
Mitigation Strategy: Users must scale input sequences x[n] and y[n] such that intermediate sums and final h[n] values remain within the [0, 255] range to avoid invalid results caused by wrap-around.
5. Execution trace for sample input


Microarchitecture Explanation
The microarchitecture of this system is based on a Harvard-style inspired bus architecture designed for high-throughput digital signal processing, specifically recursive deconvolution. It centers around a centralized Controller (FSM) that orchestrates data movement between a synchronous memory bank, a localized register file, and a specialized arithmetic logic unit (ALU).
1. Control Unit (FSM & Decoder)
The "brain" of the microarchitecture is the Finite State Machine (FSM) within the top.v module.
Instruction Fetch: The system fetches an 8-bit instruction (instr) which is immediately processed by the instr_decoder.
Instruction Decoding: The decoder breaks the 8-bit word into a 4-bit opcode and two 2-bit register identifiers (rd, rs1, rs2).
State Orchestration: The FSM manages the multi-cycle nature of complex operations. For example, it handles the synchronous RAM latency by implementing "wait" states, ensuring that data requested from RAM in one clock cycle is only latched into registers in the subsequent cycle.
2. Execution Core (ALU)
The ALU is a specialized execution unit designed to handle the specific mathematical requirements of deconvolution.
Three-Operand MAC: Unlike standard ALUs, this core includes a Multiply-Accumulate (MAC) unit that accepts three inputs (a, b, and c) to compute (a \times b) + c in a single operation. This is critical for the sum h[n-k]x[k] portion of the algorithm.
Pipelined-like Logic: While the ALU itself is combinatorial for its arithmetic blocks (MAC, Subtractor, Divider), the result is latched into the out register on the positive edge of the clock, providing stable data for the next state.
Resource Sharing: A single division block is used, which is the most hardware-intensive part of the core, to perform the final step of the deconvolution (Result / x[0]).
3. Storage Hierarchy (Registers & RAM)
The system uses a two-tier storage strategy to balance speed and capacity.
Register File (L1 Storage): A small, high-speed 4x8-bit register file (rf_inst) provides immediate operands to the ALU. It allows two simultaneous reads (rs1_data, rs2_data) and one write per clock cycle.
Synchronous RAM (L2 Storage): A 256-byte RAM (mem_inst) stores the bulk of the data. It is partitioned into three logical segments: Input x (0–63), Input y (64–127), and Output h (128–255).
Data Bus: A common 8-bit internal data bus (wr_data) connects the RAM's output, the ALU's output, and the Register File's input, allowing the FSM to route data based on the current execution state.
4. Data Path Interconnect
The datapath is governed by the following flow:
RAM to RF: Data is fetched from a specific memory address (like y[n] or x[k]) and stored in a register (R0-$R3).
RF to ALU: Two registers provide operands A and B, while the wr_data bus or a third register provides operand C for MAC operations.
ALU to RF/RAM: The calculated result (such as a partial sum or a final h[n] value) is either written back to a register for further accumulation or stored in the h section of the RAM.


