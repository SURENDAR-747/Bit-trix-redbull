import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer
 
# ─── Opcode & Register constants ───────────────────────────────────────────
NOP   = 0b00
MAC   = 0b01
LOAD  = 0b10
STORE = 0b11
 
R0 = 0b00
R1 = 0b01
R2 = 0b10
R3 = 0b11
 
# ─── Opcode generator (mirrors opcode_gen.v logic in Python) ───────────────
def gen_instr(op, reg1, reg2):
    opcode_map = {
        NOP:   0b0000,
        MAC:   0b0001,
        LOAD:  0b0010,
        STORE: 0b0011,
    }
    opcode = opcode_map[op]
    instr = (opcode << 4) | (reg1 << 2) | reg2
    return instr
 
# ─── Helper: apply instruction and wait one clock ──────────────────────────
async def send_instr(dut, op, reg1, reg2, label):
    instr = gen_instr(op, reg1, reg2)
    dut.instr.value = instr
    await RisingEdge(dut.clk)
    dut._log.info(f"{label} | instr={instr:08b} ({instr:#04x})")
 
# ─── Main Test ─────────────────────────────────────────────────────────────
@cocotb.test()
async def test_mini_cpu(dut):
    """Full system test: NOP, MAC, STORE, LOAD"""
 
    # Start clock: 10ns period
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
 
    # Reset
    dut.rst.value = 1
    dut.instr.value = 0
    await Timer(20, units="ns")
    dut.rst.value = 0
    await RisingEdge(dut.clk)
 
    dut._log.info("===== Simulation Start =====")
 
    # ── Test 1: NOP ──────────────────────────────────────────────────────
    await send_instr(dut, NOP, R0, R0, "NOP")
    dut._log.info("NOP: No operation expected")
 
    # ── Test 2: MAC R1, R2 ───────────────────────────────────────────────
    # acc = acc + R1 * R2 → registers are 0 after reset so mac_out = 0
    await send_instr(dut, MAC, R1, R2, "MAC R1,R2")
    await RisingEdge(dut.clk)  # wait for MAC to latch
    mac_result = dut.u_mac.acc_out.value.integer
    dut._log.info(f"MAC R1,R2 → acc_out = {mac_result}")
 
    # ── Test 3: MAC R0, R3 ───────────────────────────────────────────────
    await send_instr(dut, MAC, R0, R3, "MAC R0,R3")
    await RisingEdge(dut.clk)
    mac_result = dut.u_mac.acc_out.value.integer
    dut._log.info(f"MAC R0,R3 → acc_out = {mac_result}")
 
    # ── Test 4: STORE R1 → RAM[R0] ───────────────────────────────────────
    await send_instr(dut, STORE, R1, R0, "STORE R1,R0")
    dut._log.info("STORE: R1 value written to RAM[R0 address]")
 
    # ── Test 5: LOAD R3 ← RAM[R0] ────────────────────────────────────────
    await send_instr(dut, LOAD, R3, R0, "LOAD R3,R0")
    await RisingEdge(dut.clk)  # wait for RAM read to propagate
    ram_data = dut.u_ram.rd_data.value.integer
    dut._log.info(f"LOAD R3,R0 → ram_rd_data = {ram_data}")
 
    # ── Test 6: MAC R3, R1 ───────────────────────────────────────────────
    await send_instr(dut, MAC, R3, R1, "MAC R3,R1")
    await RisingEdge(dut.clk)
    mac_result = dut.u_mac.acc_out.value.integer
    dut._log.info(f"MAC R3,R1 → acc_out = {mac_result}")
 
    # ── Test 7: NOP ──────────────────────────────────────────────────────
    await send_instr(dut, NOP, R0, R0, "NOP")
 
    dut._log.info("===== Simulation Complete =====")
