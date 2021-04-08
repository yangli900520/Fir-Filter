`timescale 1ns / 1ps

`ifndef sys_defs_header
`define sys_defs_header
    `include "sys_defs.vh"
`endif

module FIR_cont (
   input   TX_TO_CONT    tx_to_cont,
   input   RX_TO_CONT    rx_to_cont,
   output logic          is_ready, // to input
   
   input  [31:0]         input_config,
   input  [31:0]         input_command,
   input  [31:0]         config_tap,
   output logic [31:0]   status,   // indicating if it's ok to start again
   input  [1:0]          config_valid,

   input  DATA_BUS       from_input,
   output DATA_BUS       to_output,

   output CONT_TO_IN     cont_to_in,
   
   output logic [6:0]    real_point,

   input                 clk,
   input                 rst_n 

);
   // counter
   logic full, empty;
   logic [8:0]  local_count, local_count_w;

   assign full = (local_count == (56 + cont_to_in.delay));
   assign empty = local_count == 0;

   always_comb begin
      case ({tx_to_cont.valid, rx_to_cont.valid, local_count}) inside
         [11'b10_000000001:11'b10_111111111] :local_count_w = local_count - 1;
         [11'b01_000000000:11'b01_111111110] :local_count_w = local_count + 1;
         default: local_count_w = local_count;
      endcase
   end
   
   always_ff @ (posedge clk) begin
      if (rst_n == 0) begin
         local_count <= 0;
      end
      else begin
         local_count <= #1 local_count_w;
      end
   end


   // internal state and status

   logic [1:0]  current_state, current_state_w;

   always_comb begin
      current_state_w = current_state;
      case (current_state)
      0: begin // waiting for input command to say ok
         if (config_valid == 2 && input_command == 1) begin // start signal
            current_state_w = 1;
         end
      end
      1: begin // running, waiting for host to go soft stop
         if (config_valid == 2 && input_command == 2) begin // soft stop signal
            current_state_w = 2;
         end
      end
      2: begin // waiting for IP to clear out remaining packet
         if (empty == 1) begin
            current_state_w = 3;
         end
      end
      3: begin //ready for performing weights and data flush
         if (config_valid == 2 && input_command == 3) begin //return to initial status
            current_state_w = 0;
         end
      end
      default: begin
      end
      endcase
   end
   
//   assign status = (current_state == 0);
assign status = {30'd0,current_state};

   always_ff @ (posedge clk) begin
      if (rst_n == 0) begin
         current_state <= 0;
      end
      else begin
         current_state <= #1 current_state_w;
      end
   end


   // a gate at the input interface
   
   logic is_ready_w;
   assign is_ready_w = (current_state == 1) && (full == 0);

   always_ff @ (posedge clk) begin
      if (rst_n == 0) begin
         is_ready <= 0;
      end
      else begin
         is_ready <= #1 is_ready_w;
      end
   end
   // settings
   logic [31:0] setting_w, setting;
   logic        is_auto;
   logic [3:0]        shift;
   logic [1:0]  flush, flush_w;
   logic [3:0]  point;
   logic [15:0] enable, enable_d;
   
   logic [15:0] enable_pipe[15:0];

   logic [1:0] flush_pipe[15:0];
   
   logic [15:0] is_auto_pipe;
   logic [3:0]  shift_pipe [15:0];
   
   


   assign enable_pipe[0] = enable_d;
   assign flush_pipe[0] = flush;
   assign is_auto_pipe[0] = is_auto;
   assign shift_pipe[0] = shift;

   integer q;

   always_ff @ (posedge clk) begin
      if (rst_n == 0) begin
          for (q = 1; q<16; q = q + 1) begin
              enable_pipe [q] <= 0;
              flush_pipe [q] <= 0;
              is_auto_pipe [q] <= 0;
              shift_pipe [q] <= 0;
          end
      end
      else begin
          for (q = 1; q<16; q = q + 1) begin
              enable_pipe [q] <= #1 enable_pipe[q-1];
              flush_pipe [q] <= #1 flush_pipe[q-1];
              is_auto_pipe [q] <= #1 is_auto_pipe[q-1];
              shift_pipe [q] <= #1 shift_pipe[q-1];
          end
      end
   end

   assign flush_w = (current_state == 3 && config_valid == 2) ? input_command [3:2] : 0;
   assign is_auto = setting[31];
//   assign cont_to_comp.ifft = setting[31];
   assign point = setting[30:27];
   assign shift = setting[26:23];

   assign cont_to_in.is_auto = is_auto;
   assign cont_to_in.flush   = flush;
   assign cont_to_in.delay   = setting[22:15];
   
   logic  [7:0]                small_point;
   assign small_point = setting[7:0];
   assign cont_to_in.shift = shift;
//   assign real_point = (is_auto == 1) ? {point+1, small_point} : {point, small_point};
   assign real_point = small_point;
   
//   assign cont_to_tx.final_shift = setting [26:22];
//   assign cont_to_comp.scaling = setting [21:4];
   always_comb begin
      case (point)
         0:  enable = 16'b1000_0000_0000_0000;
         1:  enable = 16'b1100_0000_0000_0000;
         2:  enable = 16'b1110_0000_0000_0000;
         3:  enable = 16'b1111_0000_0000_0000;
         4:  enable = 16'b1111_1000_0000_0000;
         5:  enable = 16'b1111_1100_0000_0000;
         6:  enable = 16'b1111_1110_0000_0000;
         7:  enable = 16'b1111_1111_0000_0000;
         8:  enable = 16'b1111_1111_1000_0000;
         9:  enable = 16'b1111_1111_1100_0000;
         10: enable = 16'b1111_1111_1110_0000;
         11: enable = 16'b1111_1111_1111_0000;
         12: enable = 16'b1111_1111_1111_1000;
         13: enable = 16'b1111_1111_1111_1100;
         14: enable = 16'b1111_1111_1111_1110;
         15: enable = 16'b1111_1111_1111_1111;
         default: enable = 0;
      endcase
   end


   always_comb begin
      if (current_state == 0 && config_valid == 1) begin
         setting_w = input_config;
      end
      else begin
         setting_w = setting;
      end
   end

   always_ff @ (posedge clk) begin
      if (rst_n == 0) begin
         setting <= 0;
         flush <= 0;
      end
      else begin
         setting <= #1 setting_w;
         flush <= #1 flush_w;
      end
   end

   DATA_BUS   input_tap, input_tap_w;

   assign input_tap_w.valid = current_state == 0 && config_valid == 3; 
   assign input_tap_w.data  = (input_tap_w.valid == 1) ? config_tap : 0;

   TILE_TO_TILE  prt [16:0];
   DATA_BUS      pnt [16:0];
   CONT_TO_TILE  cont_to_tile [15:0];
   //TODO
   assign prt[0].psum  = 0;
   assign prt[0].valid = from_input.valid;
   assign prt[0].input_sample  = from_input.data;
//   assign to_output.data    = prt[16].psum;   
 //  assign to_output.valid   = prt[16].valid;
   logic valid_d, valid_dd, valid_ddd;
   assign to_output.valid   = (is_auto == 1)? valid_dd : valid_ddd;
   assign pnt[0]  = input_tap;
   always_ff @ (posedge clk) begin
      if (rst_n == 0) begin
         input_tap <= 0;
         valid_d <= 0;
         valid_dd <= 0;
         valid_ddd <= 0;
         to_output.data <= 0;
         enable_d <= 0;
      end
      else begin
         input_tap <= #1 input_tap_w;
         valid_d <= #1 prt[16].valid;
         valid_dd <= #1 valid_d;
         valid_ddd <= #1 valid_dd;
         to_output.data <= #1 prt[16].psum;
         enable_d <= #1 enable;
      end
   end

   genvar i;

   generate 

      for (i = 0; i < 16; i = i + 1) begin
         assign cont_to_tile [i].flush = flush_pipe[i];
         assign cont_to_tile [i].enable = enable_pipe[i][i];
         assign cont_to_tile [i].is_auto = is_auto_pipe[i];
         assign cont_to_tile [i].shift = shift_pipe[i];

      tile  tt (
         .clk(clk),
         .rst_n(rst_n),
         .cont_to_tile(cont_to_tile[i]),
         .from_prev_tile (prt[i]),
         .from_next_tile (pnt[15-i]),
         .to_prev_tile   (pnt[16-i]),
         .to_next_tile   (prt[i+1])
      );

      end 

   endgenerate
endmodule




