module MEM_WB_Reg(clk, rst,
                  RegWrite_In,  ResultSrc_In,  ALUResult_In,  ReadData_In,  RD_In,
                  RegWrite_Out, ResultSrc_Out, ALUResult_Out, ReadData_Out, RD_Out);

    input        clk, rst;
    input        RegWrite_In, ResultSrc_In;
    input [31:0] ALUResult_In, ReadData_In;
    input [4:0]  RD_In;

    output reg        RegWrite_Out, ResultSrc_Out;
    output reg [31:0] ALUResult_Out, ReadData_Out;
    output reg [4:0]  RD_Out;

    always @(posedge clk) begin
        if (~rst) begin
            RegWrite_Out   <= 1'b0;  ResultSrc_Out  <= 1'b0;
            ALUResult_Out  <= 32'b0; ReadData_Out   <= 32'b0;
            RD_Out         <= 5'b0;
        end else begin
            RegWrite_Out   <= RegWrite_In;   ResultSrc_Out  <= ResultSrc_In;
            ALUResult_Out  <= ALUResult_In;  ReadData_Out   <= ReadData_In;
            RD_Out         <= RD_In;
        end
    end
endmodule