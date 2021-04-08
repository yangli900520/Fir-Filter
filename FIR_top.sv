`timescale 1ns / 1ps

`ifndef sys_defs_header
`define sys_defs_header
    `include "sys_defs.vh"
`endif

module FIR_top #
(      parameter C_S_AXI_DATA_WIDTH = 32, C_S_AXI_ADDR_WIDTH = 9, C_M_AXIS_TDATA_WIDTH	= 32, C_S_AXIS_TDATA_WIDTH = 32
        
)
(
   input   S_AXI_ACLK,
   input   S_AXI_ARESETN,
   input  [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_AWADDR,
   input  [2 : 0] S_AXI_AWPROT,
   input   S_AXI_AWVALID,
   output logic  S_AXI_AWREADY,
   input  [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_WDATA,
   input  [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB,
   input   S_AXI_WVALID,
   output logic  S_AXI_WREADY,
   output logic [1 : 0] S_AXI_BRESP,
   output logic  S_AXI_BVALID,
   input   S_AXI_BREADY,
   input  [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_ARADDR,
   input  [2 : 0] S_AXI_ARPROT,
   input   S_AXI_ARVALID,
   output logic  S_AXI_ARREADY,
   output logic [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_RDATA,
   output logic [1 : 0] S_AXI_RRESP,
   output logic  S_AXI_RVALID,
   input   S_AXI_RREADY,

   input   clk,
   input   rst_n,

   input   M_AXIS_ACLK,
   input   M_AXIS_ARESETN,
   output logic  M_AXIS_TVALID,
   output logic [C_M_AXIS_TDATA_WIDTH-1 : 0] M_AXIS_TDATA,
   output logic [(C_M_AXIS_TDATA_WIDTH/8)-1 : 0] M_AXIS_TSTRB,
   output logic  M_AXIS_TLAST,
   input         M_AXIS_TREADY,

   input   S_AXIS_ACLK,
   input   S_AXIS_ARESETN,
   output logic  S_AXIS_TREADY,
   input  [C_S_AXIS_TDATA_WIDTH-1 : 0] S_AXIS_TDATA,
   input  [(C_S_AXIS_TDATA_WIDTH/8)-1 : 0] S_AXIS_TSTRB,
   input   S_AXIS_TLAST,
   input   S_AXIS_TVALID
);

   logic [31:0]input_config, input_command, status, config_tap;
   logic [1:0]config_valid;  
   
   logic  tlast_in, last_out;

   logic [6:0] real_point;
   
   lite_slave ls1 (.*);

   logic ready_from_cont;
  
   DATA_BUS  RX_to_IB;

   RX_TO_CONT rx_to_cont;

   stream_slave ss1(.*, .is_ready(ready_from_cont), .data_out(RX_to_IB));

   DATA_BUS  IB_to_IN;

   input_buffer ib1(.*, .data_in(RX_to_IB), .data_out(IB_to_IN));

   DATA_BUS  IN_to_CONT;

   CONT_TO_IN cont_to_in;

   FIR_in  fi1 (.*, .data_in(IB_to_IN), .data_out(IN_to_CONT));

   logic ready_to_OB;
   DATA_BUS OB_to_TX;

   stream_master sm1(.*, .is_ready(ready_to_OB), .data_in(OB_to_TX));

//   CONT_TO_COMP cont_to_comp;
//   CONT_TO_TX   cont_to_tx;
   TX_TO_CONT   tx_to_cont;


   DATA_BUS  IP_to_OB;
   
   FIR_cont fc1 (.*, .is_ready(ready_from_cont), .from_input(IN_to_CONT), .to_output(IP_to_OB));
  
   output_buffer ob (.*, .data_in(IP_to_OB), .data_out(OB_to_TX), .is_ready(ready_to_OB));
 
endmodule




