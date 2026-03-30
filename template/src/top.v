module top (
    input clk,
    input rst,
    input [7:0] instr,
    output reg [255:0] cycle_count
);
    reg ram_wr_en, rf_wr_en;
    reg [7:0] ram_addr, ram_wr_data, rf_wr_data;
    reg [1:0] rd_addr, rs1_addr, rs2_addr, alu_op;
    wire [7:0] ram_rd_data, rs1_data, rs2_data;
    wire [15:0] alu_out;
    reg [7:0] n, k;
    reg [3:0] state;

    // Standard Instantiations [cite: 6, 7, 8]
    ram #(.DEPTH(256)) mem_inst (.clk(clk), .wr_en(ram_wr_en), .addr(ram_addr), .wr_data(ram_wr_data), .rd_data(ram_rd_data));
    reg_file rf_inst (.clk(clk), .rst(rst), .wr_en(rf_wr_en), .rd_addr(rd_addr), .rs1_addr(rs1_addr), .rs2_addr(rs2_addr), .wr_data(rf_wr_data), .rs1_data(rs1_data), .rs2_data(rs2_data));
    alu #(.WIDTH(8)) alu_i ( .op_sel(alu_op), .a(rs1_data), .b(rs2_data), .c(rf_wr_data), .out(alu_out));

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= 0; n <= 0; k <= 0; ram_wr_en <= 0; rf_wr_en <= 0;
            cycle_count <= 0;
        end else begin
            cycle_count <= cycle_count + 1;
            case (state)
                0: if (instr == 8'h01) state <= 1; // IDLE [cite: 10]

                // FETCH x[0] -> R0 (Divisor)
                1: begin ram_addr <= 8'd0; ram_wr_en <= 0; state <= 2; end
                2: begin state <= 3; end // WAIT FOR RAM LATENCY 
                3: begin rf_wr_en <= 1; rd_addr <= 2'b00; rf_wr_data <= ram_rd_data; state <= 4; end

                // FETCH y[n] -> R2 and RESET SUM R1
                4: begin rf_wr_en <= 1; rd_addr <= 2'b01; rf_wr_data <= 8'h00; ram_addr <= 8'd64 + n; state <= 5; end
                5: begin rf_wr_en <= 0; state <= 6; end // WAIT FOR RAM LATENCY 
                6: begin rf_wr_en <= 1; rd_addr <= 2'b10; rf_wr_data <= ram_rd_data; k <= 1; state <= (n == 0) ? 10 : 7; end

                // SUMMATION LOOP [cite: 17, 19]
                7: begin rf_wr_en <= 0; ram_addr <= k; state <= 8; end
                8: begin rf_wr_en <= 1; rd_addr <= 2'b11; rf_wr_data <= ram_rd_data; ram_addr <= 8'd128 + (n-k); state <= 9; end
                9: begin 
                    rf_wr_en <= 1; rd_addr <= 2'b10; rf_wr_data <= ram_rd_data; // R2=h[n-k]
                    alu_op <= 2'b00; rs1_addr <= 2'b11; rs2_addr <= 2'b10; // MAC [cite: 43]
                    rd_addr <= 2'b01; rf_wr_data <= alu_out[7:0];
                    if (k < n) begin k <= k + 1; state <= 7; end else state <= 10;
                end

                // h[n] = (y[n] - Sum) / x[0]
                10: begin alu_op <= 2'b01; rs1_addr <= 2'b10; rs2_addr <= 2'b01; state <= 11; end // SUB [cite: 44]
                11: begin 
                    rf_wr_en <= 1; rd_addr <= 2'b11; rf_wr_data <= alu_out[7:0]; // R3 = (y-sum)
                    alu_op <= 2'b10; rs1_addr <= 2'b11; rs2_addr <= 2'b00; // DIV [cite: 45]
                    state <= 12; 
                end
                12: begin 
                    ram_wr_en <= 1; ram_addr <= 8'd128 + n; ram_wr_data <= alu_out[7:0]; // STORE h[n] [cite: 29]
                    state <= 13;
                end
                13: begin 
                    ram_wr_en <= 0; rf_wr_en <= 0;
                    if (n < 3) begin n <= n + 1; state <= 4; end 
                    else state <= 0; // FINISH [cite: 31]
                end
            endcase
        end
    end
endmodule
