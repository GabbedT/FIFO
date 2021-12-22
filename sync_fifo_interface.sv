`ifndef INTERFACE_SV
  `define INTERFACE_SV
`timescale 1ns/1ps

interface sync_fifo_interface #(parameter DATA_WIDTH = 32)
(input logic clk_i);
  // Input
  logic [DATA_WIDTH - 1:0] wr_data_i;
  logic                    read_i;
  logic                    write_i;
  logic                    rst_n_i;
  // Output
  logic [DATA_WIDTH - 1:0] rd_data_o;
  logic                    full_o;
  logic                    empty_o;

  // Clocking blocks define sampling timing and direction of ports

  clocking driver_ckb @(posedge clk_i);
    default input #1 output #1;
    output wr_data_i;
    output read_i;
    output write_i;
    output rst_n_i;

    input  rd_data_o;
    input  full_o;   
    input  empty_o;
  endclocking

  clocking monitor_ckb @(posedge clk_i);
    default input #1 output #1;
    input wr_data_i;
    input read_i;
    input write_i;
    input rst_n_i;
    input rd_data_o;
    input full_o;   
    input empty_o;
  endclocking

  modport DRIVER (clocking driver_ckb, input clk_i);
  modport MONITOR (clocking monitor_ckb, input clk_i);
  
  modport DEVICE (
    input  wr_data_i,
    input  read_i,
    input  write_i,
    input  rst_n_i,
    input  clk_i,
    
    output rd_data_o,
    output full_o,
    output empty_o
  );

endinterface 

`endif