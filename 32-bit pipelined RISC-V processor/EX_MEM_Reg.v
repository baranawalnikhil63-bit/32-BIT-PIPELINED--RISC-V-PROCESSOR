module EX_MEM_Reg(clk, rst,
                  RegWrite_In,  MemWrite_In,  ResultSrc_In,  Branch_In,
                  ALUResult_In, WriteData_In, PC_Branch_In,  Zero_In,  RD_In,
                  RegWrite_Out, MemWrite_Out, ResultSrc_Out, Branch_Out,
                  ALUResult_Out,WriteData_Out,PC_Branch_Out, Zero_Out, RD_Out);

    input        clk, rst;
    input        RegWrite_In, MemWrite_In, ResultSrc_In, Branch_In, Zero_In;
    input [31:0] ALUResult_In, WriteData_In, PC_Branch_In;
    input [4:0]  RD_In;

    output reg        RegWrite_Out, MemWrite_Out, ResultSrc_Out, Branch_Out, Zero_Out;
    output reg [31:0] ALUResult_Out, WriteData_Out, PC_Branch_Out;
    output reg [4:0]  RD_Out;

    always @(posedge clk) begin
        if (~rst) begin
            RegWrite_Out   <= 1'b0;  MemWrite_Out   <= 1'b0;
            ResultSrc_Out  <= 1'b0;  Branch_Out     <= 1'b0;
            Zero_Out       <= 1'b0;  ALUResult_Out  <= 32'b0;
            WriteData_Out  <= 32'b0; PC_Branch_Out  <= 32'b0;
            RD_Out         <= 5'b0;
        end else begin
            RegWrite_Out   <= RegWrite_In;   MemWrite_Out   <= MemWrite_In;
            ResultSrc_Out  <= ResultSrc_In;  Branch_Out     <= Branch_In;
            Zero_Out       <= Zero_In;       ALUResult_Out  <= ALUResult_In;
            WriteData_Out  <= WriteData_In;  PC_Branch_Out  <= PC_Branch_In;
            RD_Out         <= RD_In;
        end
    end
endmodule