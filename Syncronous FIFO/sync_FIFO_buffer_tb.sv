`timescale 1ns/1ps
`include "sync_fifo_Test.sv"
`include "sync_fifo_Interface.sv"

module FIFO_buffer_sync_tb();
  
  localparam DATA_WIDTH = 32;
  localparam FIFO_DEPTH = 32;
  localparam FWFT = 0;
  
  // Clock generation
  bit clk_i;
  always #5 clk_i = !clk_i;

  sync_fifo_interface #(DATA_WIDTH) fifo_if(clk_i);

  sync_fifo_Test t1(fifo_if);

  // DUT instantiation
  sync_FIFO_buffer #(DATA_WIDTH, FIFO_DEPTH, FWFT) dut (fifo_if.DEVICE);

endmodule