`timescale 1ns / 1ps

`ifndef sys_defs_header
`define sys_defs_header
    `include "sys_defs.vh"
`endif

module FIR_in (
   input    CONT_TO_IN    cont_to_in,
   input    DATA_BUS      data_in,
   output   DATA_BUS      data_out,
   input                  clk,
   input                  rst_n
);

   logic  [6:0] actual_delay;

   assign actual_delay = cont_to_in.delay[7:1];

   DATA_BUS  in_d, real_in, in_dd;

   always_ff @ (posedge clk) begin
      if (rst_n == 0) begin
         in_d <= 0;
         in_dd <= 0;
         real_in <= 0;
      end
      else begin
         in_d <= #1 data_in;
         in_dd <= #1 in_d;
         real_in <= #1 in_dd;
      end
   end


   DATA_BUS   data_out_w;
   DATA_SAMPLE mult_opa, mult_opb;
   DATA_SAMPLE mult_out_pre, real_mem_data;
   logic       mult_done;

 //  assign data_out_w.valid = (cont_to_in.is_auto == 1) ? mult_done : real_in.valid;
   assign data_out_w.valid = real_in.valid;
   assign data_out_w.data  = (cont_to_in.is_auto == 1) ? mult_out_pre : real_in.data;
   
   cmult m1 (
      .opa(mult_opa),
      .opb(mult_opb),
      .shift(cont_to_in.shift),
      .out(mult_out_pre)
   ); 
   assign mult_opa = (cont_to_in.is_auto == 1) ? real_in.data : 0;
   assign mult_opb = (cont_to_in.is_auto == 1) ? real_mem_data : 0;
   
   always_ff @ (posedge clk) begin
      if (rst_n == 0) begin
         data_out <= 0;
      end
      else begin
         data_out <= #1 data_out_w;
      end
   end



   // assigning IO for buffer

   logic [6:0]        addr_0, addr_1;
   logic [6:0]        write_ptr, write_ptr_w;  
   logic [6:0]        read_ptr,  read_ptr_w;  

   logic              even, even_w;

   DATA_SAMPLE     data_in_0,  data_in_1;
   DATA_SAMPLE     data_out_0, data_out_1;

   logic           rd_0, rd_1, wr_0, wr_1;
   logic           rd, wr;

   ram #(.DATA_WIDTH(32), .MEM_SIZE(128)) ob0 (
      .clk(clk),
      .enable_write(wr_0),
      .enable_read (rd_0),
      .ctrl_write(wr_0),
      .addr(addr_0),
      .data_write(data_in_0),
      .data_read(data_out_0)
    );
   ram #(.DATA_WIDTH(32), .MEM_SIZE(128)) ob1 (
      .clk(clk),
      .enable_write(wr_1),
      .enable_read (rd_1),
      .ctrl_write(wr_1),
      .addr(addr_1),
      .data_write(data_in_1),
      .data_read(data_out_1)
    );
   logic  flag, flag_w;
   always_ff @ (posedge clk) begin
      if (rst_n == 0) begin
         flag <= 0;
         even <= 0;
         write_ptr <= 0;
         read_ptr <= 0;
      end
      else begin
         flag <= #1 flag_w;
         even <= #1 even_w;
         write_ptr <= #1 write_ptr_w;
         read_ptr <= #1 read_ptr_w;
      end
   end


   always_comb begin
      flag_w = flag;
      even_w = even;
      write_ptr_w = write_ptr;
      read_ptr_w = read_ptr;
      wr_1 = 0;
      wr_0 = 0;
      rd_1 = 0;
      rd_0 = 0;
      if (cont_to_in.flush == 1) begin
         flag_w = 0;
         even_w = 0;
         write_ptr_w = 0;
         read_ptr_w = 0;
      end
      else begin
         if (cont_to_in.is_auto == 1) begin
            if (data_in.valid == 1) begin
               if (flag == 1) begin // starting to write and read at the same time
                  if (even == 1) begin
                     wr_1 = 1;
                     rd_0 = 1;
                     even_w = 0;
                     write_ptr_w = write_ptr + 1;
                  end
                  else begin
                     wr_0 = 1;
                     rd_1 = 1;
                     even_w = 1;
                     read_ptr_w = read_ptr + 1;
                  end
               end
               else begin
                  if (even == 1) begin
                     wr_1 = 1;
                     even_w = 0;
                     write_ptr_w = write_ptr + 1;
                  end
                  else begin
                     wr_0 = 1;
                     even_w = 1;
                     if (write_ptr == actual_delay) begin
                        flag_w = 1;
                     end
                  end
               end
            end
         end
      end
   end

   always_comb begin
      addr_0 = 0;
      data_in_0 = 0;
      if (wr_0 == 1) begin
         addr_0 = write_ptr;
         data_in_0 = data_in.data;
      end
      else if (rd_0 == 1) begin
         addr_0 = read_ptr;
      end
   end  

   always_comb begin
      addr_1 = 0;
      data_in_1 = 0;
      if (wr_1 == 1) begin
         addr_1 = write_ptr;
         data_in_1 = data_in.data;
      end
      else if (rd_1 == 1) begin
         addr_1 = read_ptr;
      end
   end 
   
   logic [1:0]  read_pattern, read_pattern_w;
   assign read_pattern_w = {rd_1, rd_0};
   DATA_SAMPLE  mem_data_out_w, mem_data_out, mem_data_d;
//   assign mem_data_out_w.valid = (read_pattern != 0) ? 1 : 0;

   always_comb begin
      if (read_pattern == 2) mem_data_out_w = data_out_1; 
      else if (read_pattern == 1) mem_data_out_w = data_out_0;
      else mem_data_out_w = 0;
   end 

   always_ff @ (posedge clk) begin
      if (rst_n == 0) begin
         read_pattern <= 0;
         mem_data_out     <= 0;
         mem_data_d       <= 0;
      end
      else begin
         read_pattern <= #1 read_pattern_w;
         mem_data_out     <= #1 mem_data_out_w;
         mem_data_d   <= #1 mem_data_out;
      end
   end
   
   assign real_mem_data = (cont_to_in.delay[0] == 1) ? mem_data_d : mem_data_out;

endmodule
