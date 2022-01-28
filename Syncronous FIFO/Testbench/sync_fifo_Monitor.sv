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
// PARAM NAME : RANGE : DESCRIPTION                 : DEFAULT
// DATA_WIDTH :   /   : I/O number of bits          : 32
// FWFT       : [1:0] : Use FWFT config or standard : 1
// ------------------------------------------------------------------------------------

`ifndef MONITOR_SV
  `define MONITOR_SV

`include "sync_fifo_Transaction.sv"
`include "sync_fifo_interface.sv" 

class sync_fifo_Monitor #(parameter DATA_WIDTH = 32, parameter FWFT = 0);

  virtual sync_fifo_interface.MONITOR fifo_vif;

  // Connect the monitor to the scoreboard
  mailbox mon2scb_mbx;

  sync_fifo_Trx #(DATA_WIDTH) pkt;

/////////////////
// CONSTRUCTOR //
/////////////////

  function new(input virtual sync_fifo_interface fifo_vif, input mailbox mon2scb_mbx);
    // Didn't connect
    if (mon2scb_mbx == null)
      begin 
        $display("[Monitor] Error: mailbox monitor -> scoreboard not connected!");
        $finish;
      end
    else if (this.fifo_vif.DATA_WIDTH != fifo_vif.DATA_WIDTH)
      begin 
        $display("[Monitor] Error: interfaces parameters mismatch!");
        $finish;
      end
    else
      begin 
        this.mon2scb_mbx = mon2scb_mbx;
        this.fifo_vif = fifo_vif;
      end
  endfunction 

////////////
//  MAIN  //
////////////

  task main();
    $display("[Monitor] Starting...");  
    pkt = new();
      
    forever begin  
      // Get the inputs
      pkt.write_i = fifo_vif.monitor_ckb.write_i;
      pkt.read_i = fifo_vif.monitor_ckb.read_i;
      pkt.wr_data_i = fifo_vif.monitor_ckb.wr_data_i;
      $display("[Monitor] Sampled inputs!");

      if (FWFT)
        // In FWFT design the data arrives as soon as 
        // the "read_i" signal is asserted
        #1;
      else
        // In the standard design the data arrives one
        // clock cycle later 
        @(posedge fifo_vif.clk_i);

      // Get the outputs
      pkt.rd_data_o = fifo_vif.monitor_ckb.rd_data_o;
      pkt.empty_o = fifo_vif.monitor_ckb.empty_o;
      pkt.full_o = fifo_vif.monitor_ckb.full_o;
      $display("[Monitor] Sampled outputs!");
            
      // Send to the scoreboard
      mon2scb_mbx.put(pkt);
    end

    $display("[Monitor] Finish");
  endtask

endclass 
  
`endif