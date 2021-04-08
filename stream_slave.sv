`timescale 1ns / 1ps

`ifndef sys_defs_header
`define sys_defs_header
    `include "sys_defs.vh"
`endif
module stream_slave # (
   parameter integer C_S_AXIS_TDATA_WIDTH	= 32
)
(
   input   S_AXIS_ACLK,
// AXI4Stream sink: Reset
   input   S_AXIS_ARESETN,
// Ready to accept data in
   output logic  S_AXIS_TREADY,
// Data in
   input  [C_S_AXIS_TDATA_WIDTH-1 : 0] S_AXIS_TDATA,
// Byte qualifier
   input  [(C_S_AXIS_TDATA_WIDTH/8)-1 : 0] S_AXIS_TSTRB,
// Indicates boundary of last packet
   input   S_AXIS_TLAST,
// Data is in valid
   input   S_AXIS_TVALID,

   input   is_ready,
   input   [6:0]  real_point,
   output  DATA_BUS data_out,
   output  logic    tlast_in,
   output  RX_TO_CONT rx_to_cont 
);
   assign rx_to_cont.valid = data_out.valid;
   assign S_AXIS_TREADY = is_ready;

   DATA_BUS  data_out_w;
   logic flag_w, flag;
 
   assign data_out_w.valid = (is_ready && S_AXIS_TVALID) || flag == 1;

   assign data_out_w.data  = (is_ready && S_AXIS_TVALID  == 1) ? S_AXIS_TDATA : 0; 


   logic finish_0;

   always_comb begin
      flag_w = flag;
      if (S_AXIS_TLAST == 1 && finish_0 == 0)   flag_w = 1;
      else if (finish_0 == 1)  flag_w = 0;
   end
  
   logic [6:0]  count, count_w;

   always_comb begin
      count_w = count;
      finish_0 = 0;
      if (S_AXIS_TLAST == 1 && flag == 0) begin //if (flag == 1) begin
         if (count == real_point) begin
            count_w = 0;
            finish_0 = 1;
         end
       end 
       else if (flag == 1) begin
          if (count +1 == real_point) begin
            count_w = 0;
            finish_0 = 1;
         end        
         else begin
          count_w = count + 1;
         end
      end
   end 

   parameter DEPTH = 40;

   logic  [DEPTH - 1:0] tlast_pipe;

   assign tlast_pipe[0] = finish_0;
   assign tlast_in = tlast_pipe[DEPTH-1];
   integer i;

   always_ff @ (posedge S_AXIS_ACLK) begin
      if (S_AXIS_ARESETN == 0) begin
         data_out <= 0;
         flag  <= 0;
         count <= 0;
         for (i = 1; i < DEPTH; i = i + 1) begin
            tlast_pipe [i] <= 0;
         end
      end
      else begin
         data_out <= #1 data_out_w;
         flag <= #1 flag_w;
         count <= #1 count_w;
         for (i = 1; i < DEPTH; i = i + 1) begin
            tlast_pipe [i] <= #1 tlast_pipe[i-1];
         end
      end
   end 


endmodule

