# FIFO
This repository contains the RTL code and testbench code of both syncronous and asyncronous FIFO buffers. 
They are written and verified in SystemVerilog, the testbench is a "pure SystemVerilog Testbench with classes" so with the classical TB components (Generator, Driver...).

---

## Syncronous FIFO

It's implemented as a [circular queue](https://www.geeksforgeeks.org/circular-queue-set-1-introduction-array-implementation/), composed by two main parts:

  * Memory
  * Control path

The former is the storage of the data, the latter control the various read and write pointers to obtain a FIFO like memory.
The main module can be instantiated in a design with the provided interface: `sync_fifo_interface.sv` to make the instantiaton easier and less verbose (thus less error prone).

### I/O Ports

| Type   | Port Name | Description          |
| ------ | --------- | -------------------- |
| Input  | clk_i     | System clock         |
| Input  | wr_data_i | Data write port      |
| Input  | read_i    | Read control signal  |
| Input  | write_i   | Write control signal |
| Input  | rst_n_i   | Reset active low     | 
|        |           |                      |
| Output | rd_data_o | Data read port       | 
| Output | full_o    | Fifo full signal     | 
| Output | empty_o   | Fifo empty signal    | 

### Parameters

| Parameter Name | Range | Default Value |
| -------------- | ----- | ------------- |
| FIFO_DEPTH     |   \   | 32            |
| FWFT           | [1:0] | 1             |
| DATA_WIDTH     |   \   | 32            |

 * `FIFO_DEPTH` defines the number of words stored.
 * `FWFT` defines the FIFO's configuration (see below).
 * `DATA_WIDTH` define the width of the words stored.

### First Word Fall Through configuration 

In this configuration reading the memory is combinatorial, that means that the data read will appear to the output port `rd_data_o` as soon as `read_i` is asserted.

### Standard configuration

In this configuration reading the memory is syncronous, that means that the data read will appear to the output port `rd_data_o` the clock cycle after `read_i` is asserted. 

