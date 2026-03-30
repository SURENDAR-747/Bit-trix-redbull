

# =============================================================================
# Updated opcode_gen.py for Recursive Deconvolution
# =============================================================================

# Instruction Set Architecture (ISA) - Must match instr_decoder.v
OPCODES = {
    "NOP":       "0000",
    "MAC":       "0001", # Rd = (Rs1 * Rs2) + Rd
    "LDW":       "0010", # Load from RAM: Rd = RAM[Rs2]
    "STW":       "0011", # Store to RAM: RAM[Rs2] = Rs1
    "SUB":       "0100", # Rd = Rd - Rs2
    "DIV":       "0101", # Rd = Rd / Rs2
    "CLR":       "0110", # Rd = 0
    "MOV":       "0111", # Rd = Rs2
}
 
# Register table - constant for the 4-register file [cite: 1, 3]
REGS = {
    "R0": "00", # Suggested: Constant x[0]
    "R1": "01", # Suggested: Sum Accumulator
    "R2": "10", # Suggested: y[n] / Temp
    "R3": "11", # Suggested: Temp / h[n]
}
 
# ── Write your deconvolution program here ────────────────────────────────────
# This example sequence computes h[0] = y[0] / x[0]
program = [
    ("LDW", "R0", "R0"), # Load x[0] from RAM[0] into R0
    ("LDW", "R2", "R2"), # Load y[0] from RAM[64] into R2
    ("CLR", "R1", "R0"), # Clear R1 (Sum)
    ("SUB", "R2", "R1"), # R2 = y[0] - Sum
    ("DIV", "R2", "R0"), # R2 = R2 / R0 (h[0])
    ("STW", "R2", "R3"), # Store h[0] to RAM[128]
]
 
# ── Convert and print ────────────────────────────────────────────────────────
print(f"{'PC':<5} {'Mnemonic':<25} {'Binary'}")
print("-" * 45)
 
with open("program.asm", "w") as f:
    for i, (op, r1, r2) in enumerate(program):
        # Construct the 8-bit instruction: 4-bit Opcode + 2-bit R1 + 2-bit R2
        binary = OPCODES[op] + REGS[r1] + REGS[r2]
        print(f"PC={i:<3} {op+' '+r1+','+r2:<25} {binary}")
        f.write(binary + "\n")
 
print("-" * 45)
print(f"Total: {len(program)} instructions written to program.asm")
