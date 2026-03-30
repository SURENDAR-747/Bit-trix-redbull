module instr_decoder (
    input  [7:0] instr,
    output reg [3:0] opcode,
    output reg [1:0] rd, rs1, rs2,
    output reg reg_wr_en, ram_wr_en,
    output reg [1:0] alu_op // 00:MAC, 01:SUB, 10:DIV
);
    always @(*) begin
        opcode = instr[7:4];
        rd     = instr[3:2];
        rs1    = instr[3:2];
        rs2    = instr[1:0];

        reg_wr_en = 0; ram_wr_en = 0; alu_op = 2'b00;

        case (opcode)
            4'b0001: begin // MAC
                reg_wr_en = 1; alu_op = 2'b00; 
            end
            4'b0010: reg_wr_en = 1; // LDW
            4'b0011: ram_wr_en = 1; // STW
            4'b0100: begin // SUB
                reg_wr_en = 1; alu_op = 2'b01; 
            end
            4'b0101: begin // DIV
                reg_wr_en = 1; alu_op = 2'b10; 
            end
            4'b0110: reg_wr_en = 1; // CLR (handled by Top setting wr_data=0)
            4'b0111: reg_wr_en = 1; // MOV
            default: ;
        endcase
    end
endmodule
