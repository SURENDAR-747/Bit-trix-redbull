; Setup: R0 = x[0] (constant divisor), R1 = Sum Accumulator, R2 = y[n], R3 = Temp
LDW R0, ADDR_X0    ; Load x[0] into R0 once
LOOP_N:
    CLR R1         ; Reset Sum for new n
    LDW R2, ADDR_YN ; Load current y[n] into R2
    
    ; Internal Loop (k=1 to n) - Conceptualized as macro or repeated MACs
    LDW R3, ADDR_XK ; Load x[k]
    LDW R2, ADDR_HK ; Load h[n-k] (uses R2 as temp)
    MAC R1, R2      ; R1 = (R3 * R2) + R1
    
    ; Compute h[n]
    MOV R3, R2      ; Restore y[n] to a working register if needed
    SUB R3, R1      ; R3 = y[n] - Sum
    DIV R3, R0      ; R3 = (y[n] - Sum) / x[0]
    STW R3, ADDR_HN ; Store result h[n] to RAM
