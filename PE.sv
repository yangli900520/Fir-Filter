`timescale 1ns / 1ps

`ifndef sys_defs_header
`define sys_defs_header
    `include "sys_defs.vh"
`endif

module PE (
   input    TILE_TO_PE   tile_to_pe,
   input                 clk,
   input                 rst_n,
   input    DATA_SAMPLE  from_prev_pe,
   output   DATA_SAMPLE  to_next_pe
);

   DATA_SAMPLE add_opa, add_opb, mult_opa, mult_opb;
   DATA_SAMPLE add_out_pre, mult_out_pre;
   DATA_SAMPLE real_add_opb, mult_out, to_next_pe_w;

   logic add_valid, mult_done, mult_done_w;

// cmult result comes out in the same cycle
   logic real_valid;

   assign real_valid = tile_to_pe.valid == 1 && tile_to_pe.flush == 0 && tile_to_pe.enable == 1;
 
   assign mult_opa = tile_to_pe.tap;
   assign mult_opb = (real_valid == 1 && tile_to_pe.is_auto == 0) ? tile_to_pe.input_sample : 0;
   assign add_opa  = from_prev_pe; 
   assign add_opb  = (add_valid == 1) ? real_add_opb : 0;

   assign real_add_opb = (tile_to_pe.is_auto == 1) ? tile_to_pe.input_sample : mult_out;
   assign add_valid    = (tile_to_pe.is_auto == 1) ? real_valid : mult_done; 

   assign mult_done_w  = (tile_to_pe.is_auto == 1) ? 0 : real_valid;

   always_comb begin
//      to_next_pe_w = to_next_pe;
      if (tile_to_pe.flush == 1) begin
         to_next_pe_w = 0;
      end
      else if (add_valid == 1) begin
         to_next_pe_w = add_out_pre;
      end
      else begin
        to_next_pe_w = 0; //?
     end
   end

//   assign to_next_pe_w = (add_valid == 1) ? add_out_pre : to_next_pe;

   always_ff @ (posedge clk) begin
      if (rst_n == 0) begin
         mult_out <= 0;
         mult_done <= 0;
         to_next_pe <= 0;
      end
      else begin
         mult_out <= #1 mult_out_pre;
         mult_done <= #1 mult_done_w;
         to_next_pe <= #1 to_next_pe_w;
      end
   end
   

   cmult m1 (
      .opa(mult_opa),
      .opb(mult_opb),
      .shift(tile_to_pe.shift),
      .out(mult_out_pre)
   ); 

   cadd a1 (
      .opa(add_opa),
      .opb(add_opb),
      .out(add_out_pre)
   ); 
endmodule
