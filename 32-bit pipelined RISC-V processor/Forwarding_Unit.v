module Forwarding_Unit(
    RS1_EX, RS2_EX,
    RD_MEM, RD_WB,
    RegWrite_MEM, RegWrite_WB,
    ForwardA, ForwardB);

    input [4:0] RS1_EX, RS2_EX, RD_MEM, RD_WB;
    input       RegWrite_MEM, RegWrite_WB;
    output reg [1:0] ForwardA, ForwardB;

    always @(*) begin
        // ForwardA
        if (RegWrite_MEM & (RD_MEM != 5'b0) & (RD_MEM == RS1_EX))
            ForwardA = 2'b10;   // forward from EX/MEM (1 cycle ago)
        else if (RegWrite_WB & (RD_WB != 5'b0) & (RD_WB == RS1_EX))
            ForwardA = 2'b01;   // forward from MEM/WB (2 cycles ago)
        else
            ForwardA = 2'b00;   // use register file output

        // ForwardB
        if (RegWrite_MEM & (RD_MEM != 5'b0) & (RD_MEM == RS2_EX))
            ForwardB = 2'b10;
        else if (RegWrite_WB & (RD_WB != 5'b0) & (RD_WB == RS2_EX))
            ForwardB = 2'b01;
        else
            ForwardB = 2'b00;
    end
endmodule