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
// FILE NAME : sync_fifo_Monitor.sv
// DEPARTMENT : 
// AUTHOR : Gabriele Tripi
// AUTHOR'S EMAIL : tripi.gabriele2002@gmail.com
// ------------------------------------------------------------------------------------
// RELEASE HISTORY
// VERSION : 1.0 
// DESCRIPTION : The monitor control the DUT's interface and send the data to the 
//               scoreboard for data checking
// ------------------------------------------------------------------------------------
// KEYWORDS : new, main
// ------------------------------------------------------------------------------------
// DEPENDENCIES: sync_fifo_Transaction.sv, sync_fifo_interface.sv
// ------------------------------------------------------------------------------------
// PARAMETERS
//
// PARAM NAME : RANGE : DESCRIPTION                 : DEFAULT
// ------------------------------------------------------------------------------------
// DATA_WIDTH :   /   : I/O number of bits          : 32
// FWFT       : [1:0] : Use FWFT config or standard : 1
// DEBUG      : [1:0] : Enable debug messages       : 1
// ------------------------------------------------------------------------------------

`ifndef FIFO_MONITOR_SV
  `define FIFO_MONITOR_SV

`include "sync_fifo_Transaction.sv"
`include "sync_fifo_interface.sv" 

class sync_fifo_Monitor #(int DATA_WIDTH = 32, int FWFT = 1, int DEBUG = 1);

  virtual sync_fifo_interface fifo_vif;
  
  mailbox mon2scb_mbx;
  mailbox mon2gen_mbx;

  event drvDone_ev;

  sync_fifo_Trx #(DATA_WIDTH) pkt;

//-------------//
// CONSTRUCTOR //
//-------------//

  function new(input virtual sync_fifo_interface fifo_vif, input mailbox mon2scb_mbx, input mailbox mon2gen_mbx, input event drvDone_ev);
    // Didn't connect
    if (mon2scb_mbx == null) begin 
      $display("[Monitor] Error: mailbox monitor -> scoreboard not connected!");
      $finish;
    end else if (this.fifo_vif.DATA_WIDTH != fifo_vif.DATA_WIDTH) begin 
      $display("[Monitor] Error: interfaces parameters mismatch!");
      $finish;
    end else begin 
      this.mon2scb_mbx = mon2scb_mbx;
      this.fifo_vif = fifo_vif;
      this.mon2gen_mbx = mon2gen_mbx;
      this.drvDone_ev = drvDone_ev;

      pkt = new(0);
    end
  endfunction : new

//---------//
//  TASKS  //
//---------//

  function printInputsMon();
    $display("[Monitor] [%0dns] Sampled inputs!", $time);
    pkt.printInputs("Monitor");
  endfunction : printInputsMon

  function printOutputsMon();
    $display("[Monitor] [%0dns] Sampled outputs!", $time);

    if (FWFT) begin
      pkt.printOutputs("Monitor");
    end else begin 
      $display("[Monitor] [%0dns] Previous read data = 0x%h Empty = %0b Full = %0b", $time, pkt.rd_data_o, pkt.empty_o, pkt.full_o);
    end
  endfunction : printOutputsMon

//--------//
//  MAIN  //
//--------//

  task main();
    $display("[Monitor] [%0dns] Starting...", $time); 
    
    forever begin
      // Wait for the driver to finish driving transaction
      $display("[Monitor] [%0dns] Waiting the driver...", $time);
      wait(drvDone_ev.triggered);
      
      // Get inputs
      pkt.write_i = fifo_vif.write_i;
      pkt.read_i = fifo_vif.read_i;
      pkt.wr_data_i = fifo_vif.wr_data_i; 

      if (DEBUG) begin
        $display("[Monitor] [%0dns] Interface inputs: ", $time);   
        printInputsMon();
      end

      // Get outputs
      pkt.empty_o = fifo_vif.empty_o;
      pkt.full_o = fifo_vif.full_o;
      pkt.rd_data_o = fifo_vif.rd_data_o;

      if (DEBUG) begin
        $display("[Monitor] [%0dns] Interface outputs: ", $time);   
        printOutputsMon();
      end

      $display("[Monitor] [%0dns] Packet filled, sending to scoreboard and generator");

      // Send to the scoreboard and the generator
      mon2scb_mbx.put(pkt);
      mon2gen_mbx.put(pkt);

      @(posedge fifo_vif.clk_i);
    end
  endtask : main

endclass : sync_fifo_Monitor
  
`endif
