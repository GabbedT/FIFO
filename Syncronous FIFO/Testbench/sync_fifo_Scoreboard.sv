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
// FILE NAME : sync_fifo_Scoreboard.sv
// DEPARTMENT : 
// AUTHOR : Gabriele Tripi
// AUTHOR'S EMAIL : tripi.gabriele2002@gmail.com
// ------------------------------------------------------------------------------------
// RELEASE HISTORY
// VERSION : 1.0 
// DESCRIPTION : The scoreboard is responsible for data checking. It compares the data
//               recived from the monitor with a golden model.
// ------------------------------------------------------------------------------------
// KEYWORDS : new, tasks, main
// ------------------------------------------------------------------------------------
// DEPENDENCIES: sync_fifo_Transaction.sv
// ------------------------------------------------------------------------------------
// PARAMETERS
//
// PARAM NAME : RANGE : DESCRIPTION                 : DEFAULT
// ------------------------------------------------------------------------------------
// DATA_WIDTH :   /   : I/O number of bits          : 32
// FIFO_DEPTH :   /   : Total word stored           : 32
// FWFT       : [1:0] : Use FWFT config or standard : 1
// DEBUG      : [1:0] : Enable debug messages       : 1
// ------------------------------------------------------------------------------------

`ifndef SCOREBOARD_SV
  `define SCOREBOARD_SV

`include "sync_fifo_Transaction.sv"

class sync_fifo_Scoreboard #(int DATA_WIDTH = 32, int FIFO_DEPTH = 32, int FWFT = 1, int DEBUG = 1);

  mailbox mon2scb_mbx;

  int total_errors = 0;
  int error = 0;
  int error_time[$];

  // Fifo reference
  bit [DATA_WIDTH - 1:0] fifo_ref[$];
  bit [DATA_WIDTH - 1:0] data_read;

  sync_fifo_Trx #(DATA_WIDTH) pkt, drv_pkt_i;

//-------------//
// CONSTRUCTOR //
//-------------//

  function new(input mailbox mon2scb_mbx);
    if (mon2scb_mbx == null) begin 
      $display("[Scoreboard] Error: mailbox scoreboard -> monitor not connected!");
      $finish;
    end else begin 
      this.mon2scb_mbx = mon2scb_mbx;

      pkt = new(0);
      drv_pkt_i = new(0);
    end
  endfunction : new

//-------//
// TASKS //
//-------//

  function void emptyCheck();
    assert(fifo_ref.size() == 0) begin  
      $display("[Scoreboard] [%0dns] PASS! FIFO is empty", $time);
    end else begin 
      $display("[Scoreboard] [%0dns] FAIL! Reference size: %0d, DUT: %0s", $time, fifo_ref.size(), pkt.empty_o ? "EMPTY" : "NOT EMPTY");
      ++error;
    end
  endfunction : emptyCheck
  
  function void fullCheck();
    assert(fifo_ref.size() >= FIFO_DEPTH) begin
      $display("[Scoreboard] [%0dns] PASS! FIFO is full", $time);
    end else begin 
      $display("[Scoreboard] [%0dns] FAIL! Reference size: %0d, DUT: %0s", $time, fifo_ref.size(), pkt.full_o ? "FULL" : "NOT FULL");
      ++error;
    end
  endfunction : fullCheck

  function void dataReadCheck();
    assert(data_read == pkt.rd_data_o)  
      $display("[Scoreboard] [%0dns] PASS! Read match", $time);
    else begin 
      $display("[Scoreboard] [%0dns] FAIL! Read mismatch", $time);
      $display("[Scoreboard] Expected: 0x%h", data_read);
      $display("[Scoreboard] DUT: 0x%h", pkt.rd_data_o);
      ++error;
    end
  endfunction : dataReadCheck

//--------//
//  MAIN  //
//--------//

  task main();
    $display("[Scoreboard] [%0dns] Starting...", $time);
      
    forever begin
      mon2scb_mbx.get(pkt);

      if (DEBUG) begin
        $display("[Scoreboard] [%0dns] Monitor packet:", $time);
        pkt.toString("Scoreboard");
      end

      // Empty logic check
      if (pkt.empty_o) begin 
        emptyCheck();
      end else if (pkt.full_o) begin 
        fullCheck();
      end

      if (pkt.write_i && pkt.read_i) begin 
        $display("[Scoreboard] [%0dns] Writing and reading...", $time); 
        fifo_ref.push_front(pkt.wr_data_i);

        // Read logic check
        if (FWFT) begin
          data_read = fifo_ref.pop_back();
          dataReadCheck();
        end else begin 
          // Don't immediatly update data read since it contains the last value (data comes after 1 clock cycle)
          dataReadCheck();
          data_read = fifo_ref.pop_back();
        end
      end else if (pkt.write_i) begin 
        $display("[Scoreboard] [%0dns] Writing...", $time);
        fifo_ref.push_front(pkt.wr_data_i);
      end else if (pkt.read_i) begin 
        $display("[Scoreboard] [%0dns] Reading...", $time);
          
        // Read logic check
        if (FWFT) begin
          data_read = fifo_ref.pop_back();
          dataReadCheck();
        end else begin 
          // Don't update data read since it contains the last value (data comes after 1 clock cycle)
          dataReadCheck();
          data_read = fifo_ref.pop_back();
        end
      end else begin 
        $display("[Scoreboard] [%0dns] Idle...", $time);
      end

      if (error != 0) begin 
        ++total_errors;
        error_time.push_front($time());
      end

      error = 0;
      $display("\n");
    end
  endtask : main 

endclass : sync_fifo_Scoreboard 

`endif
