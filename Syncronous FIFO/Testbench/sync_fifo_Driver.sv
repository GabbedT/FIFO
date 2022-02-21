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
// FILE NAME : sync_fifo_Driver.sv
// DEPARTMENT : 
// AUTHOR : Gabriele Tripi
// AUTHOR'S EMAIL : tripi.gabriele2002@gmail.com
// ------------------------------------------------------------------------------------
// RELEASE HISTORY
// VERSION : 1.0 
// DESCRIPTION : The driver drives the transaction into the DUT with the correct timing
// ------------------------------------------------------------------------------------
// KEYWORDS : new, reset, main
// ------------------------------------------------------------------------------------
// DEPENDENCIES: sync_fifo_Transaction.sv
// ------------------------------------------------------------------------------------
// PARAMETERS:
// 
// PARAM NAME : RANGE : DESCRIPTION                 : DEFAULT VALUE
// ------------------------------------------------------------------------------------
// DATA_WIDTH :   /   : I/O number of bits          : 32
// FWFT       : [1:0] : Use FWFT config or standard : 1
// DEBUG      : [1:0] : Enable debug messages       : 1
// ------------------------------------------------------------------------------------

`ifndef FIFO_DRIVER_SV
  `define FIFO_DRIVER_SV

`include "sync_fifo_Transaction.sv"

class sync_fifo_Driver #(int DATA_WIDTH = 32, int FWFT = 1, int DEBUG = 1);

  virtual sync_fifo_interface fifo_vif;

  mailbox gen2drv_mbx;
  mailbox drv2scb_mbx;

  event drvDone_ev;

  sync_fifo_Trx #(DATA_WIDTH) pkt;

//-------------//
// CONSTRUCTOR //
//-------------//

  // Connect interface and mailbox
  function new(input virtual sync_fifo_interface fifo_vif, input mailbox gen2drv_mbx, input event drvDone_ev, input mailbox drv2scb_mbx);
    if (this.DATA_WIDTH != fifo_vif.DATA_WIDTH) begin 
      $display("[Driver] Error: interfaces parameters mismatch!");
      $finish;
    end else if (gen2drv_mbx == null) begin 
      $display("[Driver] Error: mailbox generator -> driver not connected!");
      $finish; 
    end else begin 
      this.fifo_vif = fifo_vif;
      this.gen2drv_mbx = gen2drv_mbx;
      this.drvDone_ev = drvDone_ev;
      this.drv2scb_mbx = drv2scb_mbx;

      pkt = new(0);
    end     
  endfunction : new

//--------//
//  MAIN  //
//--------//

  // Drive transaction
  task main();
    $display("[Driver] [%0dns] Starting...", $time);   
      
    forever begin 
      $display("[Driver] [%0dns] Waiting transaction...", $time);  

      // Receive the transaction from the generator
      gen2drv_mbx.get(pkt);
      $display("[Driver] [%0dns] Transaction number %0d acquired!", $time, pkt.trx_id);

      // Pass the transaction to the DUT
      fifo_vif.write_i <= pkt.write_i;
      fifo_vif.read_i <= pkt.read_i;
      fifo_vif.wr_data_i <= pkt.wr_data_i;

      if (DEBUG) begin
        pkt.printInputs("Driver");
      end

      if (pkt.read_i && pkt.write_i) begin 
        $display("[Driver] [%0dns] Writing data...", $time);
        $display("[Driver] [%0dns] Reading data...", $time);
      end else if (pkt.write_i) begin 
        $display("[Driver] [%0dns] Writing data...", $time);
      end else if (pkt.read_i) begin 
        $display("[Driver] [%0dns] Reading data...", $time);  
      end else begin 
        $display("[Driver] [%0dns] No operation!", $time);
      end

      @(posedge fifo_vif.clk_i);  
      -> drvDone_ev;
    end 

    $display("[Driver] [%0dns] Finish!", $time);
  endtask : main

endclass : sync_fifo_Driver

`endif 
