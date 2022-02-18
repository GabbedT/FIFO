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
// DESCRIPTION : Top level testbench module where the test and the DUT are instantiated. 
//               This module control all the parameters of the testbench, if you need
//               to modify a parameter, do it exclusively here!
// ------------------------------------------------------------------------------------
// KEYWORDS : 
// ------------------------------------------------------------------------------------
// DEPENDENCIES: sync_fifo_interface.sv, sync_fifo_Test.sv
// ------------------------------------------------------------------------------------
// PARAMETERS
//
// PARAM NAME  : RANGE : DESCRIPTION                 : DEFAULT VALUE
// ------------------------------------------------------------------------------------
// DATA_WIDTH  :   /   : I/O number of bits          : 32
// FIFO_DEPTH  :   /   : Total word stored           : 32
// FWFT        : [1:0] : Use FWFT config or standard : 1
// TEST_NUMBER :   /   : Number of test performed    : 500
// DEBUG       : [1:0] : Enable debug messages       : 1
// ------------------------------------------------------------------------------------

`timescale 1ns/1ps
`include "sync_fifo_Test.sv"
`include "sync_fifo_interface.sv"
      
module sync_FIFO_buffer_tb ();
  
//---------------//
// DUT PARAMETER //
//---------------//

  localparam int DATA_WIDTH = 32;
  localparam int FIFO_DEPTH = 32;
  localparam int FWFT = 1;
  localparam int TEST_NUMBER = 500;
  localparam int DEBUG = 1;
  
//------------------//
// CLOCK GENERATION //
//------------------//

  bit clk_i;
  always #5 clk_i = !clk_i;

  sync_fifo_interface #(DATA_WIDTH) fifo_if(clk_i);

  sync_fifo_Test #(DATA_WIDTH, FIFO_DEPTH, FWFT, TEST_NUMBER, DEBUG) t1 (fifo_if);

//-------------------//
// DUT INSTANTIATION //
//-------------------//

  sync_FIFO_buffer #(FIFO_DEPTH, FWFT) dut (fifo_if);

endmodule
