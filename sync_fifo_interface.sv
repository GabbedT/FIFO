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
// FILE NAME : sync_fifo_interface.sv
// DEPARTMENT : 
// AUTHOR : Gabriele Tripi
// AUTHOR'S EMAIL : tripi.gabriele2002@gmail.com
// ------------------------------------------------------------------------------------
// RELEASE HISTORY
// VERSION : 1.0 
// DESCRIPTION : The interface defines ports directions and timings.
// ------------------------------------------------------------------------------------
// KEYWORDS : driver_ckb, monitor_ckb, DEVICE
// ------------------------------------------------------------------------------------
// DEPENDENCIES: 
// ------------------------------------------------------------------------------------
// PARAMETERS
// PARAM NAME : RANGE : DESCRIPTION                 : DEFAULT
// DATA_WIDTH :   /   : I/O number of bits          : 32
// ------------------------------------------------------------------------------------

`ifndef INTERFACE_SV
  `define INTERFACE_SV

`timescale 1ns/1ps

interface sync_fifo_interface #(parameter DATA_WIDTH = 32)
(input logic clk_i);
  // Input
  logic [DATA_WIDTH - 1:0] wr_data_i;
  logic                    read_i;
  logic                    write_i;
  logic                    rst_n_i;
  // Output
  logic [DATA_WIDTH - 1:0] rd_data_o;
  logic                    full_o;
  logic                    empty_o;

  // Clocking blocks define sampling timing and direction of ports

  clocking driver_ckb @(posedge clk_i);
    default input #1 output #1;
    output wr_data_i;
    output read_i;
    output write_i;
    output rst_n_i;

    input  rd_data_o;
    input  full_o;   
    input  empty_o;
  endclocking

  clocking monitor_ckb @(posedge clk_i);
    default input #1 output #1;
    input wr_data_i;
    input read_i;
    input write_i;
    input rst_n_i;
    input rd_data_o;
    input full_o;   
    input empty_o;
  endclocking

  modport DRIVER (clocking driver_ckb, input clk_i);
  modport MONITOR (clocking monitor_ckb, input clk_i);
  
  // For the top level testbench DUT instantiation
  modport DEVICE (
    input  wr_data_i,
    input  read_i,
    input  write_i,
    input  rst_n_i,
    input  clk_i,
    
    output rd_data_o,
    output full_o,
    output empty_o
  );

endinterface 

`endif