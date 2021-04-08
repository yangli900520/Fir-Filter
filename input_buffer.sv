`timescale 1ns / 1ps

`ifndef sys_defs_header
`define sys_defs_header
    `include "sys_defs.vh"
`endif

module input_buffer (
   input           clk,
   input           rst_n,
   input  DATA_BUS data_in,
   output DATA_BUS data_out
);


   logic [15:0][31:0] buffer, buffer_w;
   logic [3:0]  read_ptr, read_ptr_w;
   logic [3:0]  write_ptr, write_ptr_w;
   logic [15:0] valid_chain;

   assign data_out.data = buffer[read_ptr];
   assign data_out.valid = valid_chain[15];

   always_comb begin
         buffer_w = buffer;
         valid_chain[0] = 0;
         write_ptr_w = write_ptr;
      if (data_in.valid == 1) begin
         valid_chain[0] = 1;
         write_ptr_w = write_ptr + 1;
         buffer_w[write_ptr] = data_in.data;
      end
   end
 
   assign read_ptr_w = (valid_chain[15] == 1) ? read_ptr + 1 : read_ptr;

   integer i;

   always_ff @ (posedge clk) begin
      if (rst_n == 0) begin
         buffer <= 0;
         write_ptr <= 0;
         read_ptr <= 0;
         for (i = 1; i < 16; i = i + 1) begin
            valid_chain[i]  <= 0;
         end
      end
      else begin
         buffer <= #1 buffer_w;
         write_ptr <= #1 write_ptr_w;
         read_ptr <= #1 read_ptr_w;
         for (i = 1; i < 16; i = i + 1) begin
            valid_chain[i]  <= #1 valid_chain[i-1];
         end
      end
   end


endmodule 
