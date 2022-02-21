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
// FILE NAME : sync_fifo_Generator.sv
// DEPARTMENT : 
// AUTHOR : Gabriele Tripi
// AUTHOR'S EMAIL : tripi.gabriele2002@gmail.com
// ------------------------------------------------------------------------------------
// RELEASE HISTORY
// VERSION : 1.0 
// DESCRIPTION : The generator generates random transactions with proper constraint
// ------------------------------------------------------------------------------------
// KEYWORDS : new, main
// ------------------------------------------------------------------------------------
// DEPENDENCIES: sync_fifo_Transaction.sv
// ------------------------------------------------------------------------------------
// PARAMETERS
//
// PARAM NAME : RANGE : DESCRIPTION           : DEFAULT VALUES
// ------------------------------------------------------------------------------------
// DATA_WIDTH :   /   : I/O number of bits    : 32
// DEBUG      : [1:0] : Enable debug messages : 1
// ------------------------------------------------------------------------------------

`ifndef FIFO_GENERATOR_SV
  `define FIFO_GENERATOR_SV

`include "sync_fifo_Transaction.sv"

class sync_fifo_Generator #(int DATA_WIDTH = 32, int DEBUG = 1);

  // Transaction
  rand sync_fifo_Trx #(DATA_WIDTH) pkt, mon_pkt;

  // Pass the random transaction to the driver
  mailbox gen2drv_mbx;

  // The monitor send the outputs to the generator
  // so it can generate proper constrained transactions
  mailbox mon2gen_mbx;

  // Number of transaction generated 
  int totalTestGenerated;

//-------------//
// CONSTRUCTOR //
//-------------//

  function new(input mailbox gen2drv_mbx, input mailbox mon2gen_mbx, input int totalTestGenerated);
    if (gen2drv_mbx == null) begin 
      $display("[Generator] Error: mailbox generator -> driver not connected!");
      $finish;
    end else begin
      this.gen2drv_mbx = gen2drv_mbx;
      this.mon2gen_mbx = mon2gen_mbx;
      this.totalTestGenerated = totalTestGenerated;
    end
  endfunction : new

//--------//
//  MAIN  //
//--------//

  task main();
    $display("[Generator] [%0dns] Starting...", $time);
    mon_pkt = new();

    repeat(totalTestGenerated - 1) begin 
      // Create a new transaction every cycle
      pkt = new(1);
      pkt.copy(mon_pkt);
      
      // Initialize transaction
      assert(pkt.randomize()) begin
        $display("[Generator] [%0dns] Generated a new transaction. Id: %0d", $time, pkt.trx_id);

        if (DEBUG) begin
          pkt.toString("Generator");
        end
      end else begin
        $fatal("[Generator] Packet failed to randomize!");
      end
      
      // Send the packet to the driver 
      gen2drv_mbx.put(pkt);
      #10ns;

      // Receive the outputs of the previous transaction from the monitor
      // to generate new proper transaction in case of full/empty signal asserted
      mon2gen_mbx.get(mon_pkt); 
    end

    $display("[Generator] [%0dns] Finish! Generated %0d transaction", $time, pkt.trx_count);
  endtask : main

endclass : sync_fifo_Generator

`endif
