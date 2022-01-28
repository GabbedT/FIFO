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
// FILE NAME : sync_fifo_Environment.sv
// DEPARTMENT : 
// AUTHOR : Gabriele Tripi
// AUTHOR'S EMAIL : tripi.gabriele2002@gmail.com
// ------------------------------------------------------------------------------------
// RELEASE HISTORY
// VERSION : 1.0 
// DESCRIPTION : In the environment the other testbench components are instantiated 
//               and connected
// ------------------------------------------------------------------------------------
// KEYWORDS : new, main
// ------------------------------------------------------------------------------------
// DEPENDENCIES: sync_fifo_Transaction.sv, sync_fifo_Generator.sv, sync_fifo_Driver.sv, 
//               sync_fifo_Monitor.sv, sync_fifo_Scoreboard.sv
// ------------------------------------------------------------------------------------
// PARAMETERS
// PARAM NAME : RANGE : DESCRIPTION                 : DEFAULT
// DATA_WIDTH :   /   : I/O number of bits          : 32
// FIFO_DEPTH :   /   : Total word stored           : 32
// FWFT       : [1:0] : Use FWFT config or standard : 1
// ------------------------------------------------------------------------------------

`ifndef ENVIRONMENT_SV   
  `define ENVIRONMENT_SV 

`include "sync_fifo_Transaction.sv"
`include "sync_fifo_Generator.sv"
`include "sync_fifo_Driver.sv"
`include "sync_fifo_Monitor.sv"
`include "sync_fifo_Scoreboard.sv"

class sync_fifo_Environment #(int DATA_WIDTH = 32, int FIFO_DEPTH = 32, int FWFT = 0);

  sync_fifo_Generator #(DATA_WIDTH) gen;
  sync_fifo_Driver #(DATA_WIDTH, FWFT) drv;
  sync_fifo_Monitor #(DATA_WIDTH, FWFT) mon;
  sync_fifo_Scoreboard #(DATA_WIDTH, FIFO_DEPTH) scb;

  mailbox gen2drv_mbx;
  mailbox mon2scb_mbx;
  mailbox mon2gen_mbx;
    
  event drvDone_ev;

  virtual sync_fifo_interface #(DATA_WIDTH) fifo_vif;

/////////////////
// CONSTRUCTOR //
/////////////////

  function new(input virtual sync_fifo_interface fifo_vif);
    if (this.DATA_WIDTH != fifo_vif.DATA_WIDTH) begin 
      $display("[Environment] Error: interfaces parameters mismatch");
      $finish;
    end else begin 
      this.fifo_vif = fifo_vif;
    end
        
    gen2drv_mbx = new();
    mon2scb_mbx = new();
    mon2gen_mbx = new();

    gen = new(gen2drv_mbx, drvDone_ev, mon2gen_mbx);
    drv = new(fifo_vif, gen2drv_mbx, drvDone_ev);
    mon = new(fifo_vif, mon2scb_mbx, mon2gen_mbx);
    scb = new(mon2scb_mbx);
  endfunction : new

////////////
//  MAIN  //
////////////

  task main();
    // Reset the module
    drv.reset();

    // Run test
    fork
      gen.main();
      drv.main();
      mon.main();
      scb.main();
    join_any
      
    $display("[Testbench] Finished, %0d transactions, %0d errors", gen.countTrx, scb.errorCount);
    $finish;
  endtask : main

endclass : sync_fifo_Environment 

`endif  
