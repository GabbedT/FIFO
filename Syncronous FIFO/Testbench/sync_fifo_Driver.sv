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
// PARAMETERS
// PARAM NAME : RANGE : DESCRIPTION                 : DEFAULT
// DATA_WIDTH :   /   : I/O number of bits          : 32
// ------------------------------------------------------------------------------------

`ifndef DRIVER_SV
  `define DRIVER_SV

`include "sync_fifo_Transaction.sv"

class sync_fifo_Driver #(parameter DATA_WIDTH = 32, parameter FWFT = 0);

  virtual sync_fifo_interface.DRIVER fifo_vif;

  // Connect the generator with the driver
  mailbox gen2drv;

  event drvDone_ev;
  event monDone_ev;

  // Transaction driven
  int trxCount = 0;

  sync_fifo_Trx #(DATA_WIDTH) pkt;

  // Connect interface and mailbox
  function new(input virtual sync_fifo_interface fifo_vif, input mailbox gen2drv, input event drvDone_ev);
    if (this.DATA_WIDTH != fifo_vif.DATA_WIDTH) begin 
      $display("[Driver] Error: interfaces parameters mismatch!");
      $finish;
    end else if (gen2drv == null) begin 
      $display("[Driver] Error: mailbox generator -> driver not connected!");
      $finish; 
    end else begin 
      this.fifo_vif = fifo_vif;
      this.gen2drv = gen2drv;
      this.drvDone_ev = drvDone_ev;
    end     
  endfunction

  // Reset fifo task
  task reset();
    $display("[Driver] Resetting fifo...");
    fifo_vif.driver_ckb.rst_n_i <= 1'b0;

    // Wait then deassert reset signal
    repeat (2) @(posedge fifo_vif.clk_i);
    fifo_vif.driver_ckb.rst_n_i <= 1'b1;
      
    wait(fifo_vif.driver_ckb.rst_n_i);
    $display("[Driver] Reset completed! \n");
  endtask

  // Drive transaction
  task main();
    $display("[Driver] [%0tns] Starting...", $time);
    @(posedge fifo_vif.clk_i);
    pkt = new(); 
      
    forever begin 
      $display("[Driver] [%0tns] Waiting transaction...", $time);

      // Recieve the transaction from the generator
      gen2drv.get(pkt);
      $display("[Driver] [%0tns] Transaction acquired!", $time);
      $display("[Driver] [%0tns] Transaction number %0d", $time, ++trxCount);

      // Pass the transaction to the DUT
      fifo_vif.driver_ckb.write_i <= pkt.write_i;
      fifo_vif.driver_ckb.read_i <= pkt.read_i;
      fifo_vif.driver_ckb.wr_data_i <= pkt.wr_data_i;

      if (pkt.read_i && pkt.write_i) begin 
        // Write and read simultaneously
        $display("[Driver] [%0tns] Writing data...", $time);
        $display("[Driver] [%0tns] Reading data...", $time);
      end else if (pkt.write_i) begin 
        // Write data into fifo
        $display("[Driver] [%0tns] Writing data...", $time);
      end else if (pkt.read_i) begin 
        // Retrive data from fifo
        $display("[Driver] [%0tns] Reading data...", $time);  
      end else begin 
        $display("[Driver] [%0tns] No operation!", $time);
      end

      // Wait the transaction to be elaborated
      @(posedge fifo_vif.clk_i);
      -> drvDone_ev;  
    end

    $display("[Driver] [%0tns] Finish!", $time);
  endtask

endclass 

`endif 
