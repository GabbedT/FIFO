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
// AUTHOR'S EMAIL :
// ------------------------------------------------------------------------------------
// RELEASE HISTORY
// VERSION : 1.0 
// DESCRIPTION : This is a parametrizable syncronous FIFO buffer, it is implemented as 
//               a circular queue using two pointers for read and write operation. 
//               It is composed by two parts: the controller and the memory.
//------------------------------------------------------------------------------------
// KEYWORDS : 
// ------------------------------------------------------------------------------------
// PARAMETERS
// PARAM NAME : RANGE : DESCRIPTION                  : DEFAULT 
// DATA_WIDTH :   /   : I/O number of bits           : 32
// FIFO_DEPTH :   /   : Total word stored            : 32
// FWFT       : [1:0] : Use FWFT config or standard : 1
// ------------------------------------------------------------------------------------

module FIFO_buffer_sync #(

  // Number of bits in a word
  parameter DATA_WIDTH = 32,

  // Total word stored in memory
  parameter FIFO_DEPTH = 32,

  // Use FWFT configuration or standard.
  // In FWFT (First Word Fall Through) the head of
  // the FIFO is automatically available in the 
  // read port.
  parameter FWFT = 0
) 
(
  input  logic [DATA_WIDTH - 1:0] wr_data_i,
  input  logic                    read_i,
  input  logic                    write_i,
  input  logic                    clk_i,
  input  logic                    clk_en_i,
  input  logic                    rst_n_i,

  output logic [DATA_WIDTH - 1:0] rd_data_o,
  output logic                    full_o,
  output logic                    empty_o
);

////////////////
// PARAMETERS //
////////////////

  // Current and next 
  localparam CRT = 0;
  localparam NXT = 1;

  // Address bits for fifo memory
  localparam ADDR_BITS = $clog2(FIFO_DEPTH);

  // FIFO access mode
  localparam logic [1:0] READ  = 2'b01;
  localparam logic [1:0] WRITE = 2'b10;
  localparam logic [1:0] BOTH  = 2'b11;

//////////////////
// MEMORY LOGIC //
//////////////////

  // Write and read address, they are driven by the controller pointers
  // Assignment in line 161/162
  logic [ADDR_BITS - 1:0] wr_addr, rd_addr;

  // Assignment in line 159
  logic write_en;

  // Memory block
  logic [DATA_WIDTH - 1:0] FIFO_memory [FIFO_DEPTH - 1:0];

  // The syncronous fifo write a word on positive edge of the clock, the 
  // read depends on the FWFT parameters.
  generate

    if (FWFT)
      begin : FWFT_CONFIGURATION
        // The read is asyncronous
        always_ff @(posedge clk_i) 
          begin 
            if (clk_en_i & write_en)
              begin 
                // Write a word in memory
                FIFO_memory[wr_addr] <= wr_data_i; 
              end
          end

        // The read doesn't require any control signal
        assign rd_data_o = FIFO_memory[rd_addr];
      end : FWFT_CONFIGURATION
    else
      begin : STANDARD_CONFIGURATION
        // The read is asyncronous
        always_ff @(posedge clk_i) 
          begin 
            if (clk_en_i & write_en)
              begin 
                // Write a word in memory
                FIFO_memory[wr_addr] <= wr_data_i; 
              end
            else if (clk_en_i & read_i)
              begin 
                // Read a word at the positive edge of clock
                rd_data_o <= FIFO_memory[rd_addr];
              end
            else if (clk_en_i & write_en & read_i)
              begin 
                // Both write and read
                FIFO_memory[wr_addr] <= wr_data_i; 
                rd_data_o <= FIFO_memory[rd_addr];
              end
          end
      end : STANDARD_CONFIGURATION

  endgenerate

//////////////////////
// CONTROLLER LOGIC //
//////////////////////

  // Pointers declaration
  logic [NXT:CRT][ADDR_BITS - 1:0] write_ptr, read_ptr;
  // Incremented pointer
  logic [ADDR_BITS - 1:0] write_ptr_inc, read_ptr_inc;

  // Fifo status
  logic [NXT:CRT] full, empty;

  // Enable the write only the fifo is not full
  assign write_en = write_i & !full[CRT];

  assign wr_addr = write_ptr[CRT];
  assign rd_addr = read_ptr[CRT];

      always_ff @(posedge clk_i) 
        begin : STATUS_REGISTER
          if (!rst_n_i)
            begin 
              write_ptr[CRT] <= 'b0;
              read_ptr[CRT] <= 'b0;
              full[CRT] <= 1'b0;
              empty[CRT] <= 1'b0;
            end
          else if (clk_en_i)
            begin 
              write_ptr[CRT] <= write_ptr[NXT];
              read_ptr[CRT] <= read_ptr[NXT];
              full[CRT] <= full[NXT];
              empty[CRT] <= empty[NXT];
            end
        end : STATUS_REGISTER

      always_comb 
        begin : NEXT_STATE_LOGIC
          write_ptr_inc = write_ptr[CRT] + 1;
          read_ptr_inc = read_ptr[CRT] + 1;

          case ({write_i, read_i})
            READ: 
              begin 
                if (!empty[CRT])
                  begin 
                    // Increment the read pointer
                    read_ptr[NXT] = read_ptr_inc;
                    // If there's only a read the fifo won't never be full
                    full[NXT] = 1'b0;
                    // Since this fifo is a circular queue, when we read and
                    // the two pointers are equals it means that th fifo is empty
                    empty[NXT] = (write_ptr[CRT] == read_ptr_inc);
                    write_ptr[NXT] = write_ptr[CRT];
                  end
                else
                  begin 
                    // Keep the preceedings values
                    write_ptr[NXT] = write_ptr[CRT];
                    read_ptr[NXT] = read_ptr[CRT];
                    empty[NXT] = empty[CRT];
                    full[NXT] = full[CRT];
                  end
              end

            WRITE: 
              begin 
                if (!full[CRT])
                  begin 
                    // Increment the write pointer
                    write_ptr[NXT] = write_ptr_inc;
                    // If there's only a write the fifo won't never be empty
                    empty[NXT] = 1'b0;
                    // Since this fifo is a circular queue, when we write and
                    // the two pointers are equals it means that th fifo is full
                    full[NXT] = (read_ptr[CRT] == write_ptr_inc);
                    read_ptr[NXT] = read_ptr[CRT];
                  end
                else
                  begin 
                    // Keep the preceedings values
                    write_ptr[NXT] = write_ptr[CRT];
                    read_ptr[NXT] = read_ptr[CRT];
                    empty[NXT] = empty[CRT];
                    full[NXT] = full[CRT];
                  end
              end

            BOTH:
              begin 
                // Increment the write and read pointer
                write_ptr[NXT] = write_ptr_inc;
                read_ptr[NXT] = read_ptr_inc;
                // Keep the preceedings values
                empty[NXT] = empty[CRT];
                full[NXT] = full[CRT];
              end

            default:
              begin 
                // Keep the preceedings values
                write_ptr[NXT] = write_ptr[CRT];
                read_ptr[NXT] = read_ptr[CRT];
                empty[NXT] = empty[CRT];
                full[NXT] = full[CRT];
              end
          endcase
        end : NEXT_STATE_LOGIC
  
  assign full_o = full[CRT];
  assign empty_o = empty[CRT];

endmodule
