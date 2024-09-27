# HSSL Reader FSM

## Overview
This project implements a **High Speed Serial Link (HSSL) Reader** using a Finite State Machine (FSM). The reader processes data from a high-speed serial link and outputs data words after detecting a specified number of gap bits. The design utilizes **Clock Domain Crossing (CDC)** to synchronize signals between different clock domains.

The project includes:
- **HSSL Reader FSM (hssl_reader_FSM.vhd)**: The core FSM that handles data reception and output.
- **Testbench (HSSL_reader_FSM_tb.vhd)**: A testbench to verify the functionality of the FSM under various conditions.

## Files

### 1. `hssl_reader_FSM.vhd`
This file describes the **HSSL Reader** entity that reads serial data and outputs processed data words. Key features of the module include:
- **Clock Domain Crossing**: Synchronizes the input data with the primary clock and processes it according to the FSM.
- **Finite State Machine (FSM)**: Handles different states such as idle, gap counting, and data reading.
- **Configurable Parameters**:
  - `GAP_BITS`: The number of gap bits between data words.
  - `DATA_WIDTH`: The width of the output data word.

#### Key Signals
- `clk_in`: Main clock input (4x the frequency of `clk_hssl`).
- `clk_hssl`: Clock for the high-speed serial link data.
- `data_hssl_sender`: Serial data input.
- `reset`: Asynchronous reset (active low).
- `output_data`: Data word output.

#### FSM States
1. **IDLE**: Initial state; waits for valid data.
2. **GAP_COUNTING**: Counts gap bits between data words.
3. **DATA_READING**: Reads and collects data bits.
4. **OUTPUT_DATA_S**: Outputs the data word.

### 2. `HSSL_reader_FSM_tb.vhd`
This is the **testbench** for the HSSL Reader FSM. It simulates various scenarios, including normal data transmission, reset conditions, and gap periods between bursts of data.

#### Features:
- Simulation of different bursts of serial data.
- Validation of output data based on different gap and clock settings.
- Ensures the FSM transitions correctly between states and handles errors gracefully.

## How to Run

1. **Synthesize and simulate** the design using a VHDL simulator (e.g., ModelSim or GHDL).
2. **Observe the results** from the testbench, ensuring the FSM transitions and output data are as expected.
3. **Modify parameters** like `GAP_BITS` and `DATA_WIDTH` to test different configurations.
