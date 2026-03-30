module tb_top;
    reg clk, rst;
    reg [7:0] instr;
    wire [255:0] cycle_count;

    top uut (.clk(clk), .rst(rst), .instr(instr), .cycle_count(cycle_count));

    always #5 clk = ~clk;

    initial begin
        clk = 0; rst = 1; instr = 8'h00;
        #100 rst = 0; // Hold reset long enough for everything to settle

        // --- Initialize Memory with x={2, 1}, y={4, 4, 1} ---
        uut.mem_inst.mem[0] = 8'd2; uut.mem_inst.mem[1] = 8'd1;
        uut.mem_inst.mem[64] = 8'd4; uut.mem_inst.mem[65] = 8'd4; uut.mem_inst.mem[66] = 8'd1;

        $display("\nTime | Cycle | n | x[n] | y[n] | h[n]");
        $display("----------------------------------------");

        #20 instr = 8'h01; // Send START
        #10 instr = 8'h00; // Release START pulse

        // Monitor loop: Wait for state transitions and print results
        while (uut.n < 3 && uut.cycle_count < 1000) begin
            @(posedge clk);
            if (uut.state == 12) begin
                #1; // Delay 1ns to ensure alu_out has updated for display
                $display("%0t | %0d | %0d | %d | %d | %d", 
                         $time, cycle_count, uut.n, uut.mem_inst.mem[uut.n], 
                         uut.mem_inst.mem[64+uut.n], uut.alu_out[7:0]);
                wait(uut.state == 13);
            end
        end

        $display("----------------------------------------");
        $display("Final Sequence h[0..2]: %d, %d, %d", 
                 uut.mem_inst.mem[128], uut.mem_inst.mem[129], uut.mem_inst.mem[130]);
        $finish;
    end
endmodule
