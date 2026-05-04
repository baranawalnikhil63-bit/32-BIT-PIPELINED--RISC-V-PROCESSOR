module IF_ID_Reg(clk, rst, EN, Flush,
                 PC_In,   Instr_In,
                 PC_Out,  Instr_Out);
    input         clk, rst, EN, Flush;
    input  [31:0] PC_In, Instr_In;
    output [31:0] PC_Out, Instr_Out;
    reg    [31:0] PC_Out, Instr_Out;

    always @(posedge clk) begin
        if (~rst || Flush) begin
            PC_Out    <= 32'b0;
            Instr_Out <= 32'b0;
        end else if (EN) begin
            PC_Out    <= PC_In;
            Instr_Out <= Instr_In;
        end
    end
endmodule