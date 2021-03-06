`timescale 1ns / 1ps

/*************************************************************************/
// Module       : RAM
// Description  : Register files simulate SRAM's behavior actually, 
//                but can be synthesised as block RAM in FPGA.
//                  
// Date         : 01/26/19
// Author       : Kuan-Yu Chen   
// Modified     : Chi-Sheng Yang (modified to single-port sram)
/*************************************************************************/
`ifndef sys_defs_header
`define sys_defs_header
    `include "sys_defs.vh"
`endif

`ifndef _RAM_V_
`define _RAM_V_

module ram
#(
   parameter DATA_WIDTH  = 16, 
   parameter MEM_SIZE    = 1024,
   parameter ADDR_WIDTH = (MEM_SIZE==1)? 1 : $clog2(MEM_SIZE)
)
(
   input                                        clk,
   input                                        enable_write,
   input                                        enable_read,
   input                                        ctrl_write,
   input                  [ADDR_WIDTH - 1 : 0]  addr,
   input          [DATA_WIDTH - 1 : 0]  data_write,
   output logic   [DATA_WIDTH - 1 : 0]  data_read
);

`ifdef FPGA
   (* ram_style = "block" *) logic signed [DATA_WIDTH - 1 : 0] mem [MEM_SIZE - 1 : 0];
`else
   logic  [DATA_WIDTH - 1 : 0] mem [MEM_SIZE - 1 : 0];
`endif

   always @(posedge clk) begin
      if (enable_write) begin
         if (ctrl_write) begin
               mem[addr] <= #1 data_write;
         end
      end
   end

   always @(posedge clk) begin
      if (enable_read) begin
         data_read <=   #1 mem[addr];
      end
   end

endmodule

`endif
