# 32-BIT-PIPELINED--RISC-V-PROCESSOR

A fully functional 32-bit pipelined RISC-V processor implemented in Verilog HDL, supporting a subset of the RV32I instruction set. The processor features a classic 5-stage pipeline with full hazard detection, data forwarding, and branch handling. Designed and simulated using Icarus Verilog and GTKWave.

---

## Table of Contents

- [Overview](#overview)
- [Supported Instructions](#supported-instructions)
- [Pipeline Architecture](#pipeline-architecture)
- [Hazard Handling](#hazard-handling)
- [Module Description](#module-description)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
- [Simulation Results](#simulation-results)
- [Waveform Signals](#waveform-signals)
- [Performance Comparison](#performance-comparison)
- [Tools Used](#tools-used)
- [Notes](#notes)

---

## Overview

This project implements a 5-stage pipelined RISC-V processor where up to five instructions execute simultaneously — one in each stage per clock cycle. Compared to a single cycle design, the pipeline dramatically increases throughput by overlapping instruction execution.

The pipeline includes:
- **Full data forwarding** — resolves most data hazards without stalling
- **Load-use hazard detection** — inserts one stall cycle when a load is immediately followed by a dependent instruction
- **Branch hazard handling** — flushes the incorrectly fetched instruction when a branch is taken

---

## Supported Instructions

| Type | Instructions | Opcode |
|---|---|---|
| R-type | ADD, SUB, AND, OR, SLT | `0110011` |
| I-type (Load) | LW | `0000011` |
| S-type (Store) | SW | `0100011` |
| B-type (Branch) | BEQ | `1100011` |

---

## Pipeline Architecture

The processor is divided into five stages separated by pipeline registers:

```
─────────────────────────────────────────────────────────────────────────
 IF            ID              EX              MEM             WB
─────────────────────────────────────────────────────────────────────────
 PC            Control         Forward Unit    Data Memory     WB Mux
 Instr Mem     Reg File        SrcA Mux        EX/MEM Reg      → Reg File
 IF/ID Reg     Sign Extend     SrcB Mux
               ID/EX Reg       ALU
                               Branch Adder
                               MEM/WB Reg
─────────────────────────────────────────────────────────────────────────
                   ▲                               │
                   │        Hazard Unit            │
                   └───────────────────────────────┘
                   ▲                               │
                   │       Forwarding Unit         │
                   └───────────────────────────────┘
```

### Stage Details

| Stage | Name | What happens |
|---|---|---|
| IF | Instruction Fetch | PC sends address to instruction memory, fetches 32-bit instruction |
| ID | Instruction Decode | Control unit decodes opcode, register file is read, immediate is sign-extended |
| EX | Execute | ALU performs operation, branch target is computed, forwarding muxes select correct operands |
| MEM | Memory Access | Data memory is read (load) or written (store), branch decision is made |
| WB | Write Back | Result is written back to register file — either ALU result or memory data |

### Pipeline Registers

| Register | Separates | Contents carried forward |
|---|---|---|
| `IF/ID` | IF → ID | PC, Instruction |
| `ID/EX` | ID → EX | Control signals, RD1, RD2, PC, Imm, RS1, RS2, RD |
| `EX/MEM` | EX → MEM | Control signals, ALUResult, WriteData, PC_Branch, Zero, RD |
| `MEM/WB` | MEM → WB | Control signals, ALUResult, ReadData, RD |

---

## Hazard Handling

### 1. Data Hazards — Solved by Forwarding

When an instruction in EX needs a result that is still in the pipeline from a previous instruction, the forwarding unit routes the correct value directly to the ALU input without waiting.

```
Example (no stall needed):
  ADD x1, x2, x3      ← writes x1 (currently in EX stage)
  SUB x4, x1, x5      ← reads x1 (forwarded from EX/MEM register)
```

Forwarding paths supported:

| Path | Description |
|---|---|
| EX → EX | Result from 1 instruction ago forwarded to ALU input |
| MEM → EX | Result from 2 instructions ago forwarded to ALU input |

### 2. Load-Use Hazard — Solved by Stalling

Forwarding cannot help when a load is immediately followed by a dependent instruction because the data is not available until after the MEM stage. The hazard unit inserts one bubble (NOP) cycle.

```
Example (1 stall inserted automatically):
  LW  x1, 0(x2)       ← data not ready until after MEM stage
  ADD x3, x1, x4      ← needs x1 — must wait 1 cycle
```

The hazard unit responds by:
- Freezing the PC (Stall_IF = 1)
- Freezing the IF/ID register (Stall_ID = 1)
- Flushing the ID/EX register — inserting a NOP bubble (Flush_EX = 1)

### 3. Branch Hazard — Solved by Flushing

Branches resolve in the MEM stage. If a branch is taken, the instruction fetched right after the branch is wrong. The hazard unit flushes the IF/ID register, replacing the bad instruction with a NOP.

```
Example:
  BEQ x1, x2, label   ← branch resolves in MEM stage
  ADD x3, x4, x5      ← wrong instruction if branch taken → flushed automatically
```

---

## Module Description

### Core Modules

#### `ALU.v`
Performs all arithmetic and logic operations on two 32-bit inputs. Controlled by a 3-bit ALUControl signal. Produces Zero, Negative, Carry, and OverFlow status flags.

| ALUControl | Operation |
|---|---|
| `000` | ADD |
| `001` | SUB |
| `010` | AND |
| `011` | OR |
| `101` | SLT (Set Less Than) |

#### `Main_Decoder.v`
Decodes the 7-bit opcode and generates all datapath control signals including RegWrite, ALUSrc, MemWrite, ResultSrc, Branch, ImmSrc, and ALUOp.

#### `ALU_Decoder.v`
Combines ALUOp with funct3 and funct7 fields from the instruction to produce the final 3-bit ALUControl signal sent to the ALU.

#### `Control_Unit_Top.v`
Wrapper module that instantiates both Main_Decoder and ALU_Decoder, providing a single control interface for the ID stage of the pipeline.

#### `Sign_Extend.v`
Sign-extends immediate values to 32 bits. Handles three RISC-V immediate formats by reassembling the scattered immediate bits from the instruction word.

| ImmSrc | Format | Instruction type |
|---|---|---|
| `00` | I-type | Load, ALU immediate |
| `01` | S-type | Store |
| `10` | B-type | Branch |

#### `Register_File.v`
32 general-purpose 32-bit registers (x0–x31). Two asynchronous read ports and one synchronous write port. The write happens on the rising clock edge when RegWrite is high.

#### `Instruction_Memory.v`
Read-only program memory. Uses word addressing `mem[A[31:2]]` to convert byte addresses to word indices. Loaded from `memfile.hex` at simulation start.

#### `Data_Memory.v`
Read/write data memory for load and store instructions. Uses word-aligned addressing `mem[A[11:2]]`. Writes are synchronous (clocked); reads are asynchronous (immediate).

#### `PC_Module.v`
32-bit program counter. Includes an EN (enable) input — when EN goes low during a stall, the PC freezes and the same address is presented to instruction memory next cycle.

#### `PC_Adder.v`
Simple 32-bit adder, used in two places: computing PC+4 for sequential execution, and computing the branch target address PC+Immediate.

#### `Mux.v`
Contains two multiplexer modules in one file:
- `Mux` — 2-to-1, used for PC selection, ALUSrc, and WB result selection
- `Mux3` — 3-to-1, used at ALU inputs for forwarding operand selection

### Pipeline Register Modules

#### `IF_ID_Reg.v`
Separates IF and ID stages. Passes PC and Instruction forward each cycle. Supports EN (stall — freeze in place) and Flush (branch — clear to NOP).

#### `ID_EX_Reg.v`
The largest pipeline register. Carries all control signals and data values the EX stage needs: RegWrite, MemWrite, ResultSrc, Branch, ALUSrc, ALUControl, RD1, RD2, PC, Imm_Ext, RS1, RS2, and RD. Flush input clears everything to zero when a load-use hazard is detected.

#### `EX_MEM_Reg.v`
Separates EX and MEM stages. Carries: RegWrite, MemWrite, ResultSrc, Branch, ALUResult, WriteData, PC_Branch, Zero flag, and destination register number RD.

#### `MEM_WB_Reg.v`
Separates MEM and WB stages. Carries: RegWrite, ResultSrc, ALUResult, ReadData, and destination register number RD.

### Hazard Management Modules

#### `Forwarding_Unit.v`
Detects data hazards by comparing source register numbers in EX with destination register numbers in MEM and WB stages. Generates 2-bit ForwardA and ForwardB select signals for the 3-to-1 muxes at ALU inputs.

| ForwardA / ForwardB | Source selected |
|---|---|
| `00` | Register file output (no hazard) |
| `01` | MEM/WB register result (2 instructions ago) |
| `10` | EX/MEM register result (1 instruction ago) |

#### `Hazard_Unit.v`
Detects load-use hazards and branch hazards. Generates all stall and flush control signals.

| Output signal | Meaning |
|---|---|
| `Stall_IF` | Freezes the PC register |
| `Stall_ID` | Freezes the IF/ID pipeline register |
| `Flush_EX` | Clears ID/EX register — inserts NOP bubble |
| `Flush_ID` | Clears IF/ID register — discards wrong fetch on branch taken |

#### `Pipelined_Top.v`
Top-level datapath module. Instantiates and interconnects all 17 modules. No computation happens here — it only describes the physical wiring between all pipeline stages, registers, forwarding paths, and control units.

---

## Project Structure

```
32-bit-Pipelined-RISCV/
│
├── ALU.v                  # Arithmetic Logic Unit
├── ALU_Decoder.v          # ALU control signal decoder
├── Main_Decoder.v         # Main control signal decoder
├── Control_Unit_Top.v     # Control unit wrapper
├── Sign_Extend.v          # Immediate sign extender (I, S, B types)
├── Register_File.v        # 32 x 32-bit register file
├── Instruction_Memory.v   # Program memory (ROM)
├── Data_Memory.v          # Data memory (RAM)
├── PC_Module.v            # Program counter with stall enable
├── PC_Adder.v             # PC+4 and branch target adder
├── Mux.v                  # 2-to-1 and 3-to-1 multiplexers
├── IF_ID_Reg.v            # IF/ID pipeline register
├── ID_EX_Reg.v            # ID/EX pipeline register
├── EX_MEM_Reg.v           # EX/MEM pipeline register
├── MEM_WB_Reg.v           # MEM/WB pipeline register
├── Forwarding_Unit.v      # EX-EX and MEM-EX data forwarding
├── Hazard_Unit.v          # Stall and flush control logic
├── Pipelined_Top.v        # Top-level datapath
├── Pipelined_Top_Tb.v     # Testbench
└── memfile.hex            # Program instructions in hex format
```

---

## Getting Started

### Prerequisites

- [Icarus Verilog](http://bleyer.org/icarus/) — Verilog compiler and simulator
- [GTKWave](http://gtkwave.sourceforge.net/) — Waveform viewer
- [VS Code](https://code.visualstudio.com/) with the **Verilog HDL** extension by mshr-h (optional, for editing)

### Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/32-bit-Pipelined-RISCV.git
cd 32-bit-Pipelined-RISCV
```

2. Ensure `memfile.hex` is in the same directory as all `.v` files.

### Compilation

All modules are chained using `` `include `` statements. Only the testbench needs to be passed to iverilog — it pulls in everything else automatically:

```bash
iverilog -o pipeline.out Pipelined_Top_Tb.v
```

> **Important:** Never list all `.v` files individually on the command line when using `` `include ``. Doing so causes every module to be declared twice and will produce "already declared" errors.

### Run Simulation

```bash
vvp pipeline.out
```

Expected terminal output:
```
Simulation started
Simulation finished
```

A file called `Pipeline.vcd` will be created in the same directory.

### View Waveforms

```bash
gtkwave Pipeline.vcd
```

In GTKWave:
1. Expand `Pipelined_Top_Tb` → `DUT` in the SST panel on the left
2. Select signals and click **Append**, or drag them into the wave window
3. Press `Ctrl+Shift+F` to zoom and fit the full simulation time

---

## Simulation Results

The default `memfile.hex` contains four instructions designed to exercise all forwarding paths:

```
@00000000
0062E3B3    → OR  x7, x5, x6
0062F433    → AND x8, x5, x6
004282B3    → ADD x5, x5, x4   (tests EX→EX forwarding)
40628133    → SUB x2, x5, x6   (tests MEM→EX forwarding)
```

Register file initialized as:
```
x5 = 0x00000005  (decimal 5)
x6 = 0x00000004  (decimal 4)
```

Expected results:

| Instruction | Operation | Expected Result |
|---|---|---|
| `OR  x7, x5, x6` | `5 \| 4` | `x7 = 0x00000005` |
| `AND x8, x5, x6` | `5 & 4` | `x8 = 0x00000004` |
| `ADD x5, x5, x4` | `5 + 4` | `x5 = 0x00000009` |
| `SUB x2, x5, x6` | `9 - 4` | `x2 = 0x00000005` |

---

## Waveform Signals

Recommended signals to observe in GTKWave:

| Signal | Description |
|---|---|
| `clk` | Clock toggling every 50ns |
| `rst` | Active-low reset — goes high at 150ns |
| `PC_F` | Program counter — advances 0→4→8, freezes on stall |
| `Instr_D` | Instruction word in decode stage |
| `ALUResult_E` | ALU output in execute stage |
| `ForwardA_E` | Forwarding mux select for ALU input A (non-zero = forwarding active) |
| `ForwardB_E` | Forwarding mux select for ALU input B |
| `Stall_IF` | Goes high when load-use hazard is detected |
| `Flush_EX` | Goes high when NOP bubble is inserted |
| `BranchTaken` | Goes high when branch resolves as taken |
| `RegWrite_W` | High when a register is being written in WB stage |
| `Result_W` | Final value written back to the register file |
| `RD_W` | Destination register number being written |

---

## Performance Comparison

| Metric | Single Cycle | 5-Stage Pipeline |
|---|---|---|
| Cycles per instruction | 1 per long cycle | ~1 per short cycle |
| Clock period | Slowest path (all stages) | Slowest single stage only |
| Throughput | 1 instruction per long cycle | Up to 5× higher |
| Stall cycles | None | 1 per load-use hazard |
| Branch penalty | None | 1 cycle per taken branch |
| Hardware cost | Lower | Higher (4 pipeline regs, forwarding, hazard unit) |

---

## Tools Used

| Tool | Version | Purpose |
|---|---|---|
| Icarus Verilog | v10+ | Compilation and simulation |
| GTKWave | v3.3+ | Waveform visualization |
| VS Code | Latest | Code editing |
| Verilog HDL Extension | mshr-h | Syntax highlighting and linting |

---

## Notes

- The processor uses **active-low reset** — hold `rst = 0` to reset, set `rst = 1` to run.
- All pipeline registers reset to zero (NOP state) on reset or flush.
- The forwarding unit checks that the destination register is not `x0` before forwarding, since writes to `x0` should have no effect.
- Branch resolution happens in the MEM stage, causing a 1-cycle penalty on every taken branch.
- Only a subset of RV32I is supported. I-type ALU instructions such as ADDI, ANDI, and ORI are not included in this version.
- All `` `include `` statements are used for module chaining — only pass `Pipelined_Top_Tb.v` to iverilog, never list all files individually on the command line.

---

## License

This project is open source and available under the [MIT License](LICENSE).

