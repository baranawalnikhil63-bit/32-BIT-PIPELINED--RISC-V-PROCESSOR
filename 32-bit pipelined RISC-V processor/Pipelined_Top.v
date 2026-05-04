`include "PC_Module.v"
`include "PC_Adder.v"
`include "Instruction_Memory.v"
`include "IF_ID_Reg.v"
`include "Register_File.v"
`include "Sign_Extend.v"
`include "Control_Unit_Top.v"
`include "ID_EX_Reg.v"
`include "ALU.v"
`include "Mux.v"
`include "Forwarding_Unit.v"
`include "EX_MEM_Reg.v"
`include "Data_Memory.v"
`include "MEM_WB_Reg.v"
`include "Hazard_Unit.v"

module Pipelined_Top(clk, rst);
    input clk, rst;

    // ── IF stage wires ───────────────────────────────────────────────────
    wire [31:0] PC_F, PCPlus4_F, Instr_F, PC_Next_F;

    // ── IF/ID register outputs ───────────────────────────────────────────
    wire [31:0] PC_D, Instr_D;

    // ── ID stage wires ───────────────────────────────────────────────────
    wire [31:0] RD1_D, RD2_D, Imm_Ext_D;
    wire        RegWrite_D, ALUSrc_D, MemWrite_D, ResultSrc_D, Branch_D;
    wire [1:0]  ImmSrc_D;
    wire [2:0]  ALUControl_D;

    // ── ID/EX register outputs ───────────────────────────────────────────
    wire [31:0] PC_E, RD1_E, RD2_E, Imm_Ext_E;
    wire [4:0]  RS1_E, RS2_E, RD_E;
    wire        RegWrite_E, ALUSrc_E, MemWrite_E, ResultSrc_E, Branch_E;
    wire [2:0]  ALUControl_E;

    // ── EX stage wires ───────────────────────────────────────────────────
    wire [31:0] SrcA_E, SrcB_E, SrcB_pre_E, ALUResult_E, PC_Branch_E;
    wire        Zero_E;
    wire [1:0]  ForwardA_E, ForwardB_E;

    // ── EX/MEM register outputs ──────────────────────────────────────────
    wire [31:0] ALUResult_M, WriteData_M, PC_Branch_M;
    wire [4:0]  RD_M;
    wire        RegWrite_M, MemWrite_M, ResultSrc_M, Branch_M, Zero_M;

    // ── MEM stage wires ──────────────────────────────────────────────────
    wire [31:0] ReadData_M;

    // ── MEM/WB register outputs ──────────────────────────────────────────
    wire [31:0] ALUResult_W, ReadData_W, Result_W;
    wire [4:0]  RD_W;
    wire        RegWrite_W, ResultSrc_W;

    // ── Hazard / stall / flush signals ───────────────────────────────────
    wire        Stall_IF, Stall_ID, Flush_ID, Flush_EX;
    wire        BranchTaken;

    assign BranchTaken = Branch_M & Zero_M;

    // ════════════════════════════════════════════════════════════════════
    // IF — Instruction Fetch
    // ════════════════════════════════════════════════════════════════════
    Mux PC_Mux(
        .a(PCPlus4_F),
        .b(PC_Branch_M),
        .s(BranchTaken),
        .c(PC_Next_F)
    );

    PC_Module PC(
        .clk(clk), .rst(rst),
        .EN(~Stall_IF),
        .PC(PC_F),
        .PC_Next(PC_Next_F)
    );

    PC_Adder PC_Plus4(
        .a(PC_F), .b(32'd4), .c(PCPlus4_F)
    );

    Instruction_Memory IMEM(
        .rst(rst), .A(PC_F), .RD(Instr_F)
    );

    IF_ID_Reg IF_ID(
        .clk(clk), .rst(rst),
        .EN(~Stall_ID),
        .Flush(BranchTaken),
        .PC_In(PC_F),      .Instr_In(Instr_F),
        .PC_Out(PC_D),     .Instr_Out(Instr_D)
    );

    // ════════════════════════════════════════════════════════════════════
    // ID — Instruction Decode & Register Read
    // ════════════════════════════════════════════════════════════════════
    Control_Unit_Top CU(
        .Op(Instr_D[6:0]),
        .RegWrite(RegWrite_D),
        .ImmSrc(ImmSrc_D),
        .ALUSrc(ALUSrc_D),
        .MemWrite(MemWrite_D),
        .ResultSrc(ResultSrc_D),
        .Branch(Branch_D),
        .funct3(Instr_D[14:12]),
        .funct7(Instr_D[31:25]),
        .ALUControl(ALUControl_D)
    );

    Register_File RF(
        .clk(clk), .rst(rst),
        .WE3(RegWrite_W),
        .WD3(Result_W),
        .A1(Instr_D[19:15]),
        .A2(Instr_D[24:20]),
        .A3(RD_W),
        .RD1(RD1_D),
        .RD2(RD2_D)
    );

    Sign_Extend SE(
        .In(Instr_D),
        .ImmSrc(ImmSrc_D),
        .Imm_Ext(Imm_Ext_D)
    );

    ID_EX_Reg ID_EX(
        .clk(clk), .rst(rst),
        .Flush(Flush_EX),
        .RegWrite_In(RegWrite_D),   .RegWrite_Out(RegWrite_E),
        .MemWrite_In(MemWrite_D),   .MemWrite_Out(MemWrite_E),
        .ResultSrc_In(ResultSrc_D), .ResultSrc_Out(ResultSrc_E),
        .Branch_In(Branch_D),       .Branch_Out(Branch_E),
        .ALUSrc_In(ALUSrc_D),       .ALUSrc_Out(ALUSrc_E),
        .ALUControl_In(ALUControl_D),.ALUControl_Out(ALUControl_E),
        .RD1_In(RD1_D),             .RD1_Out(RD1_E),
        .RD2_In(RD2_D),             .RD2_Out(RD2_E),
        .PC_In(PC_D),               .PC_Out(PC_E),
        .Imm_Ext_In(Imm_Ext_D),     .Imm_Ext_Out(Imm_Ext_E),
        .RS1_In(Instr_D[19:15]),     .RS1_Out(RS1_E),
        .RS2_In(Instr_D[24:20]),     .RS2_Out(RS2_E),
        .RD_In(Instr_D[11:7]),       .RD_Out(RD_E)
    );

    // ════════════════════════════════════════════════════════════════════
    // EX — Execute
    // ════════════════════════════════════════════════════════════════════
    Forwarding_Unit FWD(
        .RS1_EX(RS1_E),       .RS2_EX(RS2_E),
        .RD_MEM(RD_M),        .RD_WB(RD_W),
        .RegWrite_MEM(RegWrite_M), .RegWrite_WB(RegWrite_W),
        .ForwardA(ForwardA_E), .ForwardB(ForwardB_E)
    );

    // SrcA mux: 00=RD1, 01=WB result, 10=MEM result
    Mux3 SrcA_Mux(
        .a(RD1_E),
        .b(Result_W),
        .c(ALUResult_M),
        .s(ForwardA_E),
        .y(SrcA_E)
    );

    // SrcB pre-mux: forwarding before ALUSrc mux
    Mux3 SrcB_Fwd_Mux(
        .a(RD2_E),
        .b(Result_W),
        .c(ALUResult_M),
        .s(ForwardB_E),
        .y(SrcB_pre_E)
    );

    // ALUSrc mux: choose between forwarded register or immediate
    Mux SrcB_Mux(
        .a(SrcB_pre_E),
        .b(Imm_Ext_E),
        .s(ALUSrc_E),
        .c(SrcB_E)
    );

    ALU ALU(
        .A(SrcA_E), .B(SrcB_E),
        .Result(ALUResult_E),
        .ALUControl(ALUControl_E),
        .OverFlow(), .Carry(),
        .Zero(Zero_E), .Negative()
    );

    // Branch target adder
    PC_Adder Branch_Adder(
        .a(PC_E), .b(Imm_Ext_E), .c(PC_Branch_E)
    );

    EX_MEM_Reg EX_MEM(
        .clk(clk), .rst(rst),
        .RegWrite_In(RegWrite_E),    .RegWrite_Out(RegWrite_M),
        .MemWrite_In(MemWrite_E),    .MemWrite_Out(MemWrite_M),
        .ResultSrc_In(ResultSrc_E),  .ResultSrc_Out(ResultSrc_M),
        .Branch_In(Branch_E),        .Branch_Out(Branch_M),
        .ALUResult_In(ALUResult_E),  .ALUResult_Out(ALUResult_M),
        .WriteData_In(SrcB_pre_E),   .WriteData_Out(WriteData_M),
        .PC_Branch_In(PC_Branch_E),  .PC_Branch_Out(PC_Branch_M),
        .Zero_In(Zero_E),            .Zero_Out(Zero_M),
        .RD_In(RD_E),                .RD_Out(RD_M)
    );

    // ════════════════════════════════════════════════════════════════════
    // MEM — Memory Access
    // ════════════════════════════════════════════════════════════════════
    Data_Memory DMEM(
        .clk(clk), .rst(rst),
        .WE(MemWrite_M),
        .WD(WriteData_M),
        .A(ALUResult_M),
        .RD(ReadData_M)
    );

    MEM_WB_Reg MEM_WB(
        .clk(clk), .rst(rst),
        .RegWrite_In(RegWrite_M),   .RegWrite_Out(RegWrite_W),
        .ResultSrc_In(ResultSrc_M), .ResultSrc_Out(ResultSrc_W),
        .ALUResult_In(ALUResult_M), .ALUResult_Out(ALUResult_W),
        .ReadData_In(ReadData_M),   .ReadData_Out(ReadData_W),
        .RD_In(RD_M),               .RD_Out(RD_W)
    );

    // ════════════════════════════════════════════════════════════════════
    // WB — Writeback
    // ════════════════════════════════════════════════════════════════════
    Mux WB_Mux(
        .a(ALUResult_W),
        .b(ReadData_W),
        .s(ResultSrc_W),
        .c(Result_W)
    );

    // ════════════════════════════════════════════════════════════════════
    // Hazard Unit
    // ════════════════════════════════════════════════════════════════════
    Hazard_Unit HZD(
        .RS1_ID(Instr_D[19:15]),
        .RS2_ID(Instr_D[24:20]),
        .RS1_EX(RS1_E),
        .RS2_EX(RS2_E),
        .RD_EX(RD_E),
        .RD_MEM(RD_M),
        .ResultSrc_EX(ResultSrc_E),
        .Branch_MEM(Branch_M),
        .Zero_MEM(Zero_M),
        .Stall_IF(Stall_IF),
        .Stall_ID(Stall_ID),
        .Flush_ID(Flush_ID),
        .Flush_EX(Flush_EX),
        .ForwardA_EX(),
        .ForwardB_EX()
    );

endmodule