module ID_EX_Reg(clk, rst, Flush,
                 RegWrite_In,  MemWrite_In,  ResultSrc_In,
                 Branch_In,    ALUSrc_In,    ALUControl_In,
                 RD1_In,       RD2_In,       PC_In,
                 Imm_Ext_In,   RS1_In,       RS2_In,   RD_In,
                 RegWrite_Out, MemWrite_Out, ResultSrc_Out,
                 Branch_Out,   ALUSrc_Out,   ALUControl_Out,
                 RD1_Out,      RD2_Out,      PC_Out,
                 Imm_Ext_Out,  RS1_Out,      RS2_Out,  RD_Out);

    input        clk, rst, Flush;
    input        RegWrite_In, MemWrite_In, ResultSrc_In, Branch_In, ALUSrc_In;
    input [2:0]  ALUControl_In;
    input [31:0] RD1_In, RD2_In, PC_In, Imm_Ext_In;
    input [4:0]  RS1_In, RS2_In, RD_In;

    output reg        RegWrite_Out, MemWrite_Out, ResultSrc_Out, Branch_Out, ALUSrc_Out;
    output reg [2:0]  ALUControl_Out;
    output reg [31:0] RD1_Out, RD2_Out, PC_Out, Imm_Ext_Out;
    output reg [4:0]  RS1_Out, RS2_Out, RD_Out;

    always @(posedge clk) begin
        if (~rst || Flush) begin
            RegWrite_Out   <= 1'b0;  MemWrite_Out   <= 1'b0;
            ResultSrc_Out  <= 1'b0;  Branch_Out     <= 1'b0;
            ALUSrc_Out     <= 1'b0;  ALUControl_Out <= 3'b0;
            RD1_Out        <= 32'b0; RD2_Out        <= 32'b0;
            PC_Out         <= 32'b0; Imm_Ext_Out    <= 32'b0;
            RS1_Out        <= 5'b0;  RS2_Out        <= 5'b0;
            RD_Out         <= 5'b0;
        end else begin
            RegWrite_Out   <= RegWrite_In;   MemWrite_Out   <= MemWrite_In;
            ResultSrc_Out  <= ResultSrc_In;  Branch_Out     <= Branch_In;
            ALUSrc_Out     <= ALUSrc_In;     ALUControl_Out <= ALUControl_In;
            RD1_Out        <= RD1_In;        RD2_Out        <= RD2_In;
            PC_Out         <= PC_In;         Imm_Ext_Out    <= Imm_Ext_In;
            RS1_Out        <= RS1_In;        RS2_Out        <= RS2_In;
            RD_Out         <= RD_In;
        end
    end
endmodule