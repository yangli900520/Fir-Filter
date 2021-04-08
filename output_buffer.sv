`timescale 1ns / 1ps

`ifndef sys_defs_header
`define sys_defs_header
    `include "sys_defs.vh"
`endif

module output_buffer (
   input               clk,
   input               rst_n, 
   input   DATA_BUS    data_in,    // from IP
   output  DATA_BUS    data_out,   // to output interface
//   input   CONT_TO_TX  cont_to_tx,  // ifft, points, final shift
   output  TX_TO_CONT  tx_to_cont,    // to controller, when pop one data controller count -1
   input               is_ready,    // from output interface
   input               tlast_in,
   output   logic      last_out
);




   logic [3:0] mem_counter, mem_counter_w;
   logic [3:0] read_counter, read_counter_w;

   // assigning IO for buffer

   logic [3:0]        addr_0, addr_1;
  
   DATA_SAMPLE     data_in_0,  data_in_1;
   DATA_SAMPLE     data_out_0, data_out_1;

   logic           rd_0, rd_1, wr_0, wr_1;
   logic           rd, wr;

   ram #(.DATA_WIDTH(32), .MEM_SIZE(16)) ob0 (
      .clk(clk),
      .enable_write(wr_0),
      .enable_read (rd_0),
      .ctrl_write(wr_0),
      .addr(addr_0),
      .data_write(data_in_0),
      .data_read(data_out_0)
    );
   ram #(.DATA_WIDTH(32), .MEM_SIZE(16)) ob1 (
      .clk(clk),
      .enable_write(wr_1),
      .enable_read (rd_1),
      .ctrl_write(wr_1),
      .addr(addr_1),
      .data_write(data_in_1),
      .data_read(data_out_1)
    );
   // some flags for read and write

   logic      wr_flag_0_w, wr_flag_0;
   logic      rd_flag_0_w, rd_flag_0;
   logic      wr_flag_1_w, wr_flag_1;
   logic      rd_flag_1_w, rd_flag_1;
   
   logic           finish_write_0, finish_write_1;
   logic           finish_read_0,  finish_read_1;

   always_comb begin
      wr_flag_0_w = wr_flag_0;
      if (finish_write_0 == 1) begin
         wr_flag_0_w = 0;
      end
      else if (finish_read_0) begin
         wr_flag_0_w = 1;
      end 
   end
   always_comb begin
      wr_flag_1_w = wr_flag_1;
      if (finish_write_1 == 1) begin
         wr_flag_1_w = 0;
      end
      else if (finish_read_1) begin
         wr_flag_1_w = 1;
      end 
   end

   always_comb begin
      rd_flag_0_w = rd_flag_0;
      if (finish_write_0 == 1) begin
         rd_flag_0_w = 1;
      end
      else if (finish_read_0) begin
         rd_flag_0_w = 0;
      end 
   end

   always_comb begin
      rd_flag_1_w = rd_flag_1;
      if (finish_write_1 == 1) begin
         rd_flag_1_w = 1;
      end
      else if (finish_read_1) begin
         rd_flag_1_w = 0;
      end 
   end

   logic last_flag, last_flag_w;
   logic finish_last;

   always_comb begin
      last_flag_w = last_flag;
      if (tlast_in == 1)  last_flag_w = 1;
      else if (finish_last == 1) last_flag_w = 0;
   end
   
   always_ff @ (posedge clk) begin
      if (rst_n == 0) begin
         wr_flag_0 <= 1;
         wr_flag_1 <= 1;
         rd_flag_0 <= 0;
         rd_flag_1 <= 0;
         last_flag <= 0;
      end
      else begin
         wr_flag_0 <= #1 wr_flag_0_w;
         wr_flag_1 <= #1 wr_flag_1_w;
         rd_flag_0 <= #1 rd_flag_0_w;
         rd_flag_1 <= #1 rd_flag_1_w;
         last_flag <= #1 last_flag_w;
      end
   end

   // ping-pong, giving write priority

   always_comb begin
      addr_0 = 0;
      data_in_0 = 0;
      if (wr_0 == 1) begin
         addr_0 = mem_counter;
         data_in_0 = data_in.data;
      end
      else if (rd_0 == 1) begin
         addr_0 = read_counter;
      end
   end  

   always_comb begin
      addr_1 = 0;
      data_in_1 = 0;
      if (wr_1 == 1) begin
         addr_1 = mem_counter;
         data_in_1 = data_in.data;
      end
      else if (rd_1 == 1) begin
         addr_1 = read_counter;
      end
   end 

   // writing into output buffer according to wr_flag, doesn't control flag
 
   always_comb begin
      wr_0 = 0;
      wr_1 = 0;
      mem_counter_w = (finish_last == 1)? 0 : mem_counter;
      finish_write_0 = 0;
      finish_write_1 = 0;
      if (data_in.valid == 1) begin
         if (wr_flag_0 == 1) begin
            wr_0 = 1;
//            if (mem_counter == 15 || finish_last == 1) begin
            if (mem_counter == 15) begin
               mem_counter_w = 0;
               finish_write_0 = 1;
            end 
            else begin
               mem_counter_w = mem_counter + 1;
            end
         end
         else if (wr_flag_1 == 1) begin
            wr_1 = 1;
//            if (mem_counter == 15 || finish_last == 1) begin
            if (mem_counter == 15) begin
               mem_counter_w = 0;
               finish_write_1 = 1;
            end 
            else begin
               mem_counter_w = mem_counter + 1;
            end
         end
      end
   end

   TX_TO_CONT tx_to_cont_w;
   logic indi, indi_w;

   always_comb begin
      tx_to_cont_w.valid = 0;
      rd_0 = 0;
      rd_1 = 0;
      finish_read_0 = 0; 
      finish_read_1 = 0;
      finish_last = 0;
      read_counter_w = read_counter; 
      if (is_ready == 1) begin
         if (rd_flag_0 == 1) begin
            tx_to_cont_w.valid = 1;
            rd_0 = 1;
            if (read_counter == 15) begin
               read_counter_w = 0;
               finish_read_0 = 1;
            end
            else begin
               read_counter_w = read_counter + 1;
            end
         end
         else if (rd_flag_1 == 1) begin
            tx_to_cont_w.valid = 1;
            rd_1 = 1;
            if (read_counter == 15) begin
               read_counter_w = 0;
               finish_read_1 = 1;
            end
            else begin
               read_counter_w = read_counter + 1;
            end
         end
        else if (last_flag == 1) begin
            if (indi == 0) begin
               tx_to_cont_w.valid = 1;
    //           rd_0 = 1;
               if (read_counter == mem_counter) begin
               rd_0 = 0;
                  read_counter_w = 0;
                  finish_last = 1;
               end
               else begin
               rd_0 = 1;
                  read_counter_w = read_counter + 1;
               end
            end
            else begin
               tx_to_cont_w.valid = 1;
//               rd_1 = 1;
               if (read_counter == mem_counter) begin
                  read_counter_w = 0;
                  finish_last = 1;
               rd_1 = 0;
               end
               else begin
               rd_1 = 1;
                  read_counter_w = read_counter + 1;
               end
            end
         end         
      end
   end
   
   always_comb begin
      indi_w = indi;
      if (last_flag == 1) begin
         if (rd_flag_0 == 1) indi_w = 1;
         else if (rd_flag_1 == 1) indi_w = 0;
      end
   end

   always_ff @ (posedge clk) begin
      if (rst_n == 0) begin
         mem_counter <= 0;
         read_counter <= 0;
         tx_to_cont <= 0;
         indi <= 0;
         last_out <= 0;
      end
      else begin
         mem_counter <= #1 mem_counter_w;
         read_counter <= #1 read_counter_w;
         tx_to_cont <= #1 tx_to_cont_w;
         indi <= #1 indi_w;
         last_out <= #1 finish_last;
      end
   end

   // output data

   logic [1:0]  read_pattern, read_pattern_w;
   assign read_pattern_w = {rd_1, rd_0};
   
   DATA_BUS  data_out_w;
   assign data_out_w.valid = (read_pattern != 0) ? 1 : 0;

   always_comb begin
      if (read_pattern == 2) data_out_w.data = data_out_1;
      else if (read_pattern == 1) data_out_w.data = data_out_0;
      else data_out_w.data = 0;
   end 

   always_ff @ (posedge clk) begin
      if (rst_n == 0) begin
         read_pattern <= 0;
         data_out     <= 0;
      end
      else begin
         read_pattern <= #1 read_pattern_w;
         data_out     <= #1 data_out_w;
      end
   end


 
endmodule  
