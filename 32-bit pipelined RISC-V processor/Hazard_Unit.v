module Hazard_Unit(
    RS1_ID, RS2_ID,
    RS1_EX, RS2_EX, RD_EX,
    RD_MEM,
    ResultSrc_EX,
    Branch_MEM, Zero_MEM,
    Stall_IF, Stall_ID,
    Flush_ID, Flush_EX,
    ForwardA_EX, ForwardB_EX);

    input [4:0]  RS1_ID, RS2_ID;
    input [4:0]  RS1_EX, RS2_EX, RD_EX, RD_MEM;
    input        ResultSrc_EX;
    input        Branch_MEM, Zero_MEM;

    output       Stall_IF, Stall_ID, Flush_ID, Flush_EX;
    output [1:0] ForwardA_EX, ForwardB_EX;

    wire LoadStall;
    wire BranchTaken;

    // Load-use hazard: if EX stage is a load and its dest matches ID source
    assign LoadStall = ResultSrc_EX &
                       ((RD_EX == RS1_ID) | (RD_EX == RS2_ID));

    assign BranchTaken = Branch_MEM & Zero_MEM;

    // Stall PC and IF/ID register; flush ID/EX register (insert bubble)
    assign Stall_IF = LoadStall;
    assign Stall_ID = LoadStall;
    assign Flush_EX = LoadStall;
    assign Flush_ID = BranchTaken;

    // EX forwarding from MEM stage (EX-EX path)
    // ForwardA: 00=reg file, 10=EX/MEM forward, 01=MEM/WB forward
    assign ForwardA_EX = (RS1_EX != 5'b0) & (RS1_EX == RD_MEM) ? 2'b10 : 2'b00;
    assign ForwardB_EX = (RS2_EX != 5'b0) & (RS2_EX == RD_MEM) ? 2'b10 : 2'b00;

endmodule