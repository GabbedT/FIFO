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
// FILE NAME : sync_fifo_Test.sv
// DEPARTMENT : 
// AUTHOR : Gabriele Tripi
// AUTHOR'S EMAIL : tripi.gabriele2002@gmail.com
// ------------------------------------------------------------------------------------
// RELEASE HISTORY
// VERSION : 1.0 
// DESCRIPTION : In this module the environment is instantiated with all the parameters
// ------------------------------------------------------------------------------------
// KEYWORDS : sync_fifo_Environment
// ------------------------------------------------------------------------------------
// DEPENDENCIES: sync_fifo_Environment.sv, sync_fifo_interface.sv
// ------------------------------------------------------------------------------------
// PARAMETERS
// ------------------------------------------------------------------------------------

`ifndef TEST_SV  
  `define TEST_SV 

  `include "sync_fifo_Environment.sv"
  `include "sync_fifo_interface.sv"

program sync_fifo_Test(sync_fifo_interface fifo_if);

///////////////////
// DUT PARAMETER //
///////////////////

  // Read FIFO_buffer_sync.sv
  localparam DATA_WIDTH = 32;
  localparam FIFO_DEPTH = 32;
  localparam FWFT = 1;

//////////////////////////
// TESTBENCH PARAMETERS //
//////////////////////////

  // Number of tests performed
  localparam TEST_NUMBER = 100;

////////////////////
// TESTBENCH BODY //
////////////////////

  sync_fifo_Environment #(DATA_WIDTH, FIFO_DEPTH, FWFT) env;

  initial begin
    env = new(fifo_if);
    env.gen.totalTestGenerated = TEST_NUMBER;
    env.main();
  end

endprogram

`endif