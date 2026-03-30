module alu #(parameter WIDTH = 8) (
    input [1:0] op_sel,      // 00:MAC, 01:SUB, 10:DIV
    input [WIDTH-1:0] a, b, c, 
    output [2*WIDTH-1:0] out
);
    wire [7:0] mac_res = (a * b) + c;
    wire [7:0] sub_res = a - b; 
    wire [7:0] div_res = (b != 0) ? (a / b) : 8'b0; 

    assign out = (op_sel == 2'b00) ? {8'b0, mac_res} :
                 (op_sel == 2'b01) ? {8'b0, sub_res} :
                 (op_sel == 2'b10) ? {8'b0, div_res} : 16'b0; 
endmodule
