@echo off
echo Compiling pipeline...
iverilog -o pipeline.out Pipelined_Top_Tb.v Pipelined_Top.v ^
  ALU.v ALU_Decoder.v Main_Decoder.v Control_Unit_Top.v ^
  Sign_Extend.v PC_Module.v PC_Adder.v Mux.v ^
  Register_File.v Instruction_Memory.v Data_Memory.v ^
  IF_ID_Reg.v ID_EX_Reg.v EX_MEM_Reg.v MEM_WB_Reg.v ^
  Forwarding_Unit.v Hazard_Unit.v

echo Running simulation...
vvp pipeline.out

echo Opening GTKWave...
gtkwave Pipeline.vcd
pause