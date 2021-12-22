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

class sync_fifo_Scoreboard #(parameter DATA_WIDTH = 32, parameter FIFO_DEPTH = 32);

  mailbox mon2scb_mbx;
  int trxCount = 0;
  int errorCount = 0;

  bit [DATA_WIDTH - 1:0] fifo_ref [FIFO_DEPTH];
  bit [$clog2(FIFO_DEPTH) - 1:0] wr_ptr = 0;
  bit [$clog2(FIFO_DEPTH) - 1:0] rd_ptr = 0;

  sync_fifo_Trx #(DATA_WIDTH) pkt;

/////////////////
// CONSTRUCTOR //
/////////////////

  function new(input mailbox mon2scb_mbx);
    if (mon2scb_mbx == null)
      begin 
        $display("[Scoreboard] Error: mailbox scoreboard -> monitor not connected!");
        $finish;
      end
    else
      begin 
        this.mon2scb_mbx = mon2scb_mbx;
          
        // Initialize fifo reference
        foreach(fifo_ref[i]) begin 
          fifo_ref[i] = 'b0;
        end
      end
  endfunction 

/////////////
//  TASKS  //
/////////////

  // Read fifo
  task fifoPop();
    // Assert that the design behave like the golden model
    assert (this.pkt.rd_data_o == this.fifo_ref[rd_ptr]) 
    else begin 
      errorCount++;
      $display("[Scoreboard] Error on data read!");
      $display("[Scoreboard] Expected: 0x%0h", this.fifo_ref[rd_ptr]);
      $display("[Scoreboard] DUT: 0x%0h", this.pkt.rd_data_o);
    end
    // Increment the read pointer
    this.rd_ptr++;
  endtask

  // Write fifo
  task fifoPush();
    // Write into the golden model
    this.fifo_ref[wr_ptr] = this.pkt.wr_data_i;
    // Increment the write pointer
    this.wr_ptr++;
  endtask

////////////
//  MAIN  //
////////////

  task main();
    $display("[Scoreboard] Starting...");
    pkt = new();
      
    forever begin 
      // Get the transaction from the scoreboard
      mon2scb_mbx.get(pkt);

      // Golden model
      if (pkt.write_i && pkt.read_i)
        begin 
          $display("[Scoreboard] Reading and Writing...");
          // Read and write the memory 
          fifoPush();
          fifoPush();
        end
      else if (pkt.write_i)
        begin 
          $display("[Scoreboard] Writing...");
          // Write into the memory 
          fifoPush();
        end
      else if (pkt.read_i)
        begin 
          $display("[Scoreboard] Reading...");
          // Read the memory and increment the pointer
          fifoPush();
        end
      else 
        begin 
          $display("[Scoreboard] Idle...");
        end
        
      if (pkt.full_o)
        $display("[Scoreboard] FIFO is full!");
      if (pkt.empty_o)
        $display("[Scoreboard] FIFO is empty");

      $display("\n");

      trxCount++;
    end
  endtask  

endclass   

`endif