`timescale 1ns / 1ps

`ifndef sys_defs_header
`define sys_defs_header
    `include "sys_defs.vh"
`endif

module tile (
   input            clk,
   input            rst_n,
   input  CONT_TO_TILE cont_to_tile,
   input  TILE_TO_TILE from_prev_tile,
   input  DATA_BUS     from_next_tile,
   output  DATA_BUS    to_prev_tile,
   output TILE_TO_TILE to_next_tile
);

   TILE_TO_PE tile_to_pe [7:0];
   DATA_SAMPLE  par [8:0];
/*
   DATA_SAMPLE  tap_buf [7:0];
   DATA_SAMPLE  tap_buf_w [7:0];
*/

   logic [7:0][31:0] tap_buf_w, tap_buf;

   logic [2:0] write_ptr, write_ptr_w;

   logic       flag_w, flag, is_full;
  
//   integer i, j;

   always_comb begin
      tap_buf_w = tap_buf;
      write_ptr_w = write_ptr;
      flag_w = flag;
      is_full = 0;
      if (cont_to_tile.flush == 2) begin
         tap_buf_w = 0;
         flag_w = 0;
      end
      else begin
         if (from_next_tile.valid == 1) begin
            if (flag == 1 && write_ptr == 0) begin
               is_full = 1;
            end
            else begin
               if (write_ptr == 7) begin
                  flag_w = 1;
               end
               write_ptr_w = write_ptr + 1;
               tap_buf_w [write_ptr] = from_next_tile.data;
            end 
         end
      end 
   end

   TILE_TO_TILE  to_next_tile_w;

   assign par[0]               = from_prev_tile.psum;

   assign to_next_tile_w.valid = from_prev_tile.valid;
   assign to_next_tile_w.input_sample = from_prev_tile.input_sample;
   assign to_next_tile_w.psum  = par[8];

   DATA_BUS to_prev_tile_w;
   
   assign to_prev_tile_w = (is_full == 1) ? from_next_tile : 0; 
   logic  flush_d, flush_d_w;
   assign flush_d_w = (cont_to_tile.flush != 0);

   always_ff @ (posedge clk) begin
      if (rst_n == 0) begin
         to_next_tile <= 0;
         to_prev_tile <= 0;
         flag <= 0;
         write_ptr <= 0;
         tap_buf <= 0;
         flush_d <= 0;
      end
      else begin
         to_next_tile <= #1 to_next_tile_w;
         to_prev_tile <= #1 to_prev_tile_w;
         flag <= #1 flag_w;
         write_ptr <= #1 write_ptr_w;
         tap_buf <= #1 tap_buf_w;
         flush_d <= #1 flush_d_w;
      end
   end

   genvar i;

   generate 

      for (i = 0; i < 8; i = i + 1) begin
         assign tile_to_pe [i].valid = from_prev_tile.valid;
         assign tile_to_pe [i].input_sample = from_prev_tile.input_sample;
         assign tile_to_pe [i].tap = tap_buf [i];
//         assign tile_to_pe [i].flush = (cont_to_tile.flush != 0);
         assign tile_to_pe [i].flush = flush_d;
         assign tile_to_pe [i].enable = cont_to_tile.enable;
         assign tile_to_pe [i].is_auto = cont_to_tile.is_auto;
         assign tile_to_pe [i].shift = cont_to_tile.shift;

      PE  pp (
         .clk(clk),
         .rst_n(rst_n),
         .tile_to_pe(tile_to_pe[7-i]),
         .from_prev_pe(par[i]),
         .to_next_pe(par[i+1])
      );

      end 

   endgenerate
endmodule
