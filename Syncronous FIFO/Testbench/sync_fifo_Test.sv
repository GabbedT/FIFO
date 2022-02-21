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
// DESCRIPTION : In this module the environment is instantiated and the DUT is resetted
// ------------------------------------------------------------------------------------
// KEYWORDS : 
// ------------------------------------------------------------------------------------
// DEPENDENCIES: sync_fifo_Environment.sv, sync_fifo_interface.sv
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

`ifndef FIFO_TEST_SV  
  `define FIFO_TEST_SV 

  `include "sync_fifo_Environment.sv"
  `include "sync_fifo_interface.sv"

program automatic sync_fifo_Test #(int DATA_WIDTH = 32, int FIFO_DEPTH = 32, int FWFT = 1, int TEST_NUMBER = 500, int DEBUG = 1) (sync_fifo_interface fifo_if);

//----------------//
// TESTBENCH BODY //
//----------------//

  sync_fifo_Environment #(DATA_WIDTH, FIFO_DEPTH, FWFT, TEST_NUMBER, DEBUG) env;

  initial begin
    env = new(fifo_if);

    // Reset DUT
    $display("Resetting DUT...");
    fifo_if.rst_n_i <= 1'b0;
    @(posedge fifo_if.clk_i);
    fifo_if.rst_n_i <= 1'b1;
    $display("Reset finished! Starting the test");

    // Run test
    env.main();
  end

endprogram

`endif
