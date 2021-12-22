// MIT License
//
// Copyright (c) 2021 Gabriele Tripi
// 
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
// ------------------------------------------------------------------------------------
// ------------------------------------------------------------------------------------
// FILE NAME : sync_FIFO_buffer_tb.sv
// DEPARTMENT : 
// AUTHOR : Gabriele Tripi
// AUTHOR'S EMAIL : tripi.gabriele2002@gmail.com
// ------------------------------------------------------------------------------------
// RELEASE HISTORY
// VERSION : 1.0 
// DESCRIPTION : Top level testbench module where the test and the DUT are instantiated 
// ------------------------------------------------------------------------------------
// KEYWORDS : 
// ------------------------------------------------------------------------------------
// DEPENDENCIES: sync_fifo_interface.sv, sync_fifo_Test.sv
// ------------------------------------------------------------------------------------
// PARAMETERS
// ------------------------------------------------------------------------------------

`timescale 1ns/1ps
`include "sync_fifo_Test.sv"
`include "sync_fifo_interface.sv"

module sync_FIFO_buffer_tb ();
  
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