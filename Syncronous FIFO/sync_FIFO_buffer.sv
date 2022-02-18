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
// FILE NAME : FIFO_buffer_sync.sv
// DEPARTMENT : 
// AUTHOR : Gabriele Tripi
// AUTHOR'S EMAIL : tripi.gabriele2002@gmail.com
// ------------------------------------------------------------------------------------
// RELEASE HISTORY
// VERSION : 1.0 
// DESCRIPTION : This is a parametrizable syncronous FIFO buffer, it is implemented as 
//               a circular queue using two pointers for read and write operation. 
//               It is composed by two parts: the controller and the memory.
//               The operation are: READ and WRITE, it's possible to simultaneusly
//               read and write. The "read_i" signal mustn't be asserted when the signal
//               "empty_o" is true and the "write_i" signal mustn't be asserted when the
//               signal "full_o" is true. Note that empty/full signal are asserted 
//               immediatly as the control signal arrives, not in the next clock cycle!
// ------------------------------------------------------------------------------------
// KEYWORDS : FWFT_configuration, standard_configuration, status_register, 
//            next_state_logic
// ------------------------------------------------------------------------------------
// DEPENDENCIES: sync_fifo_interface.sv 
// ------------------------------------------------------------------------------------
// PARAMETERS
//
// PARAM NAME : RANGE : DESCRIPTION                 : DEFAULT VALUE
// ------------------------------------------------------------------------------------
// FIFO_DEPTH :   /   : Total word stored           : 32
// FWFT       : [1:0] : Use FWFT config or standard : 1
// ------------------------------------------------------------------------------------

`include "sync_fifo_interface.sv"

module sync_FIFO_buffer #(
  // Total word stored in memory
  parameter int FIFO_DEPTH = 32,

  // Use FWFT configuration or standard.
  // In FWFT (First Word Fall Through) the head of
  // the FIFO is available in the read port as soon
  // as the "read_i" signal is asserted 
  parameter int FWFT = 1
) 
( sync_fifo_interface intf ); 
  
//------------//
// PARAMETERS //
//------------//

  // Current and next 
  localparam CRT = 0;
  localparam NXT = 1;

  // Address bits for fifo memory
  localparam ADDR_BITS = $clog2(FIFO_DEPTH);

  // FIFO access mode
  localparam logic [1:0] READ  = 2'b01;
  localparam logic [1:0] WRITE = 2'b10;
  localparam logic [1:0] BOTH  = 2'b11;

//--------------//
// MEMORY LOGIC //
//--------------//

  // Write and read address, they are driven by the controller pointers
  // Assignment in line 161/162
  logic [ADDR_BITS - 1:0] wr_addr, rd_addr;

  // Fifo status
  logic [NXT:CRT] full, empty;

  // Assignment in line 157/159
  logic write_en, read_en;

  // Memory block
  logic [intf.DATA_WIDTH - 1:0] FIFO_memory [FIFO_DEPTH - 1:0];

  // The syncronous fifo write a word on positive edge of the clock, the 
  // read depends on the FWFT parameters.
  generate

    if (FWFT == 1) begin : FWFT_configuration
      always_ff @(posedge intf.clk_i) begin 
        if (write_en) begin 
          // Write a word in memory
          FIFO_memory[wr_addr] <= intf.wr_data_i; 
        end
      end

      // The read is asyncronous
      assign intf.rd_data_o = FIFO_memory[rd_addr];
    end : FWFT_configuration

    else begin : standard_configuration
      // The read is syncronous
      always_ff @(posedge intf.clk_i) begin 
        if (write_en & read_en) begin 
          // Both write and read
          FIFO_memory[wr_addr] <= intf.wr_data_i; 
          intf.rd_data_o <= FIFO_memory[rd_addr];
        end else if (read_en) begin 
          // Read a word at the positive edge of clock 
          intf.rd_data_o <= FIFO_memory[rd_addr];
        end else if (write_en) begin 
          // Write a word in memory
          FIFO_memory[wr_addr] <= intf.wr_data_i; 
        end
      end
    end : standard_configuration

  endgenerate

//------------------//
// CONTROLLER LOGIC //
//------------------//

  // Pointers declaration
  logic [NXT:CRT][ADDR_BITS - 1:0] write_ptr, read_ptr;
  // Incremented pointer
  logic [ADDR_BITS - 1:0] write_ptr_inc, read_ptr_inc;

  // Enable the write only when the fifo is not full
  assign write_en = intf.write_i & !full[CRT];
  // Enable the read only when the fifo is not empty
  assign read_en = intf.read_i & !empty[CRT];

  assign wr_addr = write_ptr[CRT];
  assign rd_addr = read_ptr[CRT];

      always_ff @(posedge intf.clk_i) begin : status_register
        if (!intf.rst_n_i) begin 
          write_ptr[CRT] <= 'b0;
          read_ptr[CRT] <= 'b0;
          full[CRT] <= 1'b0;
          empty[CRT] <= 1'b1;
        end else begin 
          write_ptr[CRT] <= write_ptr[NXT];
          read_ptr[CRT] <= read_ptr[NXT];
          full[CRT] <= full[NXT];
          empty[CRT] <= empty[NXT];
        end
      end : status_register

  assign write_ptr_inc = write_ptr[CRT] + 1;
  assign read_ptr_inc = read_ptr[CRT] + 1;

      always_comb begin : next_state_logic
        // Keep the preceedings values (default values)
        write_ptr[NXT] = write_ptr[CRT];
        read_ptr[NXT] = read_ptr[CRT];
        empty[NXT] = empty[CRT];
        full[NXT] = full[CRT];
          
        case ({intf.write_i, intf.read_i})
          READ: begin 
                  if (!empty[CRT]) begin 
                    // Increment the read pointer
                    read_ptr[NXT] = read_ptr_inc;

                    // If there's only a read the fifo won't never be full
                    full[NXT] = 1'b0;

                    // Since this fifo is a circular queue, when we read and
                    // the two pointers are equals it means that the fifo is empty
                    empty[NXT] = (write_ptr[CRT] == read_ptr_inc);
                    write_ptr[NXT] = write_ptr[CRT];
                  end 
                end

          WRITE:  begin 
                    if (!full[CRT]) begin 
                      // Increment the write pointer
                      write_ptr[NXT] = write_ptr_inc;
                        
                      // If there's only a write the fifo won't never be empty
                      empty[NXT] = 1'b0;
                      
                      // Since this fifo is a circular queue, when we write and
                      // the two pointers are equals it means that the fifo is full
                      full[NXT] = (read_ptr[CRT] == write_ptr_inc);
                      read_ptr[NXT] = read_ptr[CRT];
                    end 
                  end

          BOTH: begin 
                  // Increment the write and read pointer
                  write_ptr[NXT] = write_ptr_inc;
                  read_ptr[NXT] = read_ptr_inc;
                end
        endcase
      end : next_state_logic
  
  assign intf.full_o = full[CRT];
  assign intf.empty_o = empty[CRT];

endmodule
