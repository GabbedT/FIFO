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
// FILE NAME : sync_fifo_Transaction.sv
// DEPARTMENT : 
// AUTHOR : Gabriele Tripi
// AUTHOR'S EMAIL : tripi.gabriele2002@gmail.com
// ------------------------------------------------------------------------------------
// RELEASE HISTORY
// VERSION : 1.0 
// DESCRIPTION : A generic fifo transaction with the correct constraints
// ------------------------------------------------------------------------------------
// KEYWORDS : read_c, write_c, new, printInputs, printOutputs, toString, copy
// ------------------------------------------------------------------------------------
// DEPENDENCIES: 
// ------------------------------------------------------------------------------------
// PARAMETERS
//
// PARAM NAME : RANGE : DESCRIPTION                 : DEFAULT
// ------------------------------------------------------------------------------------
// DATA_WIDTH :   /   : I/O number of bits          : 32
// ------------------------------------------------------------------------------------

`ifndef TRANSACTION_SV
  `define TRANSACTION_SV
  
class sync_fifo_Trx #(int DATA_WIDTH = 32);

  // Inputs
  rand bit [DATA_WIDTH - 1:0] wr_data_i;
  rand bit                    read_i;
  rand bit                    write_i;

  // Outputs
  bit      [DATA_WIDTH - 1:0] rd_data_o;
  bit                         full_o;
  bit                         empty_o;

//------------//
// CONSTRAINT //
//------------//

  // Don't read if fifo is empty 
  constraint read_c { 
    (empty_o) -> read_i == 1'b0;
  };

  // Don't write if fifo is full
  constraint write_c { 
    (full_o) -> write_i == 1'b0; 
  };

//------//
// DATA //
//------//

  // Total number of transactions
  static int trx_count = 1;

  // Id of transaction
  int trx_id;

//-------------//
// CONSTRUCTOR //
//-------------//

  function new(input bit increment = 0);
    if (increment) begin
      // Increment the number of transaction created every time
      // the testbench instantiate an object and assign the transaction
      // an unique id
      trx_id = trx_count++;
    end

    // Input/Output variables
    wr_data_i = 0;
    read_i = 0;
    write_i = 0;
    rd_data_o = 0;
    full_o = 0;
    empty_o = 1;
  endfunction : new

//-----------//
// FUNCTIONS //
//-----------//

  function void printInputs(string tag);
    $display("[%0s] [%0dns] Write data = 0x%h Read = %0b Write = %0b", tag, $time, wr_data_i, read_i, write_i);
  endfunction : printInputs

  function void printOutputs(string tag);
    $display("[%0s] [%0dns] Read data = 0x%h Empty = %0b Full = %0b", tag, $time, rd_data_o, empty_o, full_o);
  endfunction : printOutputs

  function void toString(string tag);
    $display("[%s] [%0dns] Inputs:", tag, $time);
    printInputs(tag);
    $display("[%s] [%0dns] Outputs", tag, $time);
    printOutputs(tag);
  endfunction : toString

  // Copy the inputs and outputs except for the ID
  function void copy(input sync_fifo_Trx obj);
    // Inputs
    this.wr_data_i = obj.wr_data_i;
    this.read_i = obj.read_i;
    this.write_i = obj.write_i;

    // Outputs
    this.rd_data_o = obj.rd_data_o;
    this.full_o = obj.full_o;
    this.empty_o = obj.empty_o;
  endfunction : copy

endclass : sync_fifo_Trx

`endif
