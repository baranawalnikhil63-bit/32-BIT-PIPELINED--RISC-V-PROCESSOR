`include "Pipelined_Top.v"
module Pipelined_Top_Tb();
    reg clk = 1'b1, rst;

    Pipelined_Top DUT(
        .clk(clk),
        .rst(rst)
    );

    initial begin
        $dumpfile("Pipeline.vcd");
        $dumpvars(0, Pipelined_Top_Tb);
    end

    always begin
        clk = ~clk;
        #50;
    end

    initial begin
        rst <= 1'b0;
        #150;
        rst <= 1'b1;
        #1000;
        $finish;
    end
endmodule