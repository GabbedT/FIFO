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
// KEYWORDS : new, fifoPop, fifoPush, main
// ------------------------------------------------------------------------------------
// DEPENDENCIES: sync_fifo_Transaction.sv
// ------------------------------------------------------------------------------------
// PARAMETERS
// PARAM NAME : RANGE : DESCRIPTION                 : DEFAULT
// DATA_WIDTH :   /   : I/O number of bits          : 32
// FIFO_DEPTH :   /   : Total word stored           : 32
// ------------------------------------------------------------------------------------

`ifndef SCOREBOARD_SV
  `define SCOREBOARD_SV

`include "sync_fifo_Transaction.sv"

class sync_fifo_Scoreboard #(int DATA_WIDTH = 32, int FIFO_DEPTH = 32);

  mailbox mon2scb_mbx;
  int errorCount = 0;

  // Fifo reference
  bit [DATA_WIDTH - 1:0] fifo_ref [$:FIFO_DEPTH];
  bit [DATA_WIDTH - 1:0] data_read;

  sync_fifo_Trx #(DATA_WIDTH) pkt;

/////////////////
// CONSTRUCTOR //
/////////////////

  function new(input mailbox mon2scb_mbx);
    if (mon2scb_mbx == null) begin 
      $display("[Scoreboard] Error: mailbox scoreboard -> monitor not connected!");
      $finish;
    end else begin 
      this.mon2scb_mbx = mon2scb_mbx;

      // Initialize the queue
      for (int i = 0; i < FIFO_DEPTH; i++) begin 
        fifo_ref.insert(i, 0);
      end
    end
  endfunction : new

////////////
//  MAIN  //
////////////

  task main();
    $display("[Scoreboard] [%0tns] Starting...", $time);
    pkt = new();
      
    forever begin
      // Get the complete transaction from the monitor 
      mon2scb_mbx.get(pkt);

      // Check the empty/full logic before writing/reading the fifo
      // since it would compromise the size of the fifo reference
      if (pkt.empty_o) begin 
        assert(fifo_ref.size() == 0)  
          $display("[Scoreboard] [%0tns] PASS! FIFO is empty", $time);
        else begin 
          $display("[Scoreboard] [%0tns] FAIL! Reference size: %0d, DUT: %0s", $time, fifo_ref.size(), pkt.empty_o ? "EMPTY" : "NOT EMPTY");
          errorCount++;
        end
      end else if (pkt.full_o) begin 
        assert(fifo_ref.size() == FIFO_DEPTH)  
          $display("[Scoreboard] [%0tns] PASS! FIFO is full", $time);
        else begin 
          $display("[Scoreboard] [%0tns] FAIL! Reference size: %0d, DUT: %0s", $time, fifo_ref.size(), pkt.full_o ? "FULL" : "NOT FULL");
          errorCount++;
        end
      end

      if (pkt.write_i & pkt.read_i) begin  
        $display("[Scoreboard] [%0tns] Writing and reading...", $time);
        fifo_ref.push_front(pkt.wr_data_i);
        data_read = fifo_ref.pop_back();

        assert(data_read == pkt.rd_data_o)  
          $display("[Scoreboard] [%0tns] PASS! Read match", $time);
        else begin 
          $display("[Scoreboard] [%0tns] FAIL! Read mismatch", $time);
          $display("[Scoreboard] Expected: %0h", data_read);
          $display("[Scoreboard] DUT: %0h", pkt.rd_data_o);
          errorCount++;
        end
      end else if (pkt.write_i) begin 
        $display("[Scoreboard] [%0tns] Writing...", $time);
        fifo_ref.push_front(pkt.wr_data_i);
      end else if (pkt.read_i) begin 
        $display("[Scoreboard] [%0tns] Reading...", $time);
        data_read = fifo_ref.pop_back();

        assert(data_read == pkt.rd_data_o)  
          $display("[Scoreboard] [%0tns] PASS! Read match", $time);
        else begin 
          $display("[Scoreboard] [%0tns] FAIL! Read mismatch", $time);
          $display("[Scoreboard] Expected: %0h", data_read);
          $display("[Scoreboard] DUT: %0h", pkt.rd_data_o);
          errorCount++;
        end
      end else begin 
        $display("[Scoreboard] [%0tns] Idle...", $time);
      end

      $display("\n");
    end
  endtask : main 

endclass : sync_fifo_Scoreboard 

`endif
