# 32-BIT-PIPELINED--RISC-V-PROCESSOR
A fully functional 32-bit single cycle RISC-V processor implemented in Verilog HDL, supporting a subset of the RV32I instruction set. Designed and simulated using Icarus Verilog and GTKWave.

#Table of Contents

 Overview
 Supported Instructions
 Architecture
 Module Description
 Project Structure
 Getting Started
 Simulation Results
 Waveform Signals
 Tools Used
 
#Overview
This project implements a single cycle RISC-V processor where every instruction completes in exactly one clock cycle. The datapath includes an ALU, register file, instruction memory, data memory, control unit, sign extender, and all necessary multiplexers and adders. Branch instructions are fully supported with a dedicated branch adder and PC mux.
