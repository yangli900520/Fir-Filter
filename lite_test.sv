`timescale 1 ns / 1 ps

module lite_test #
(
   parameter C_S_AXI_DATA_WIDTH	= 32, 
             C_S_AXI_ADDR_WIDTH = 9
)
(
   input                                        clk,
   output logic                                 S_AXI_WVALID,
   output logic                                 S_AXI_AWVALID,
   output logic                                 S_AXI_ARVALID,
   output logic    [C_S_AXI_ADDR_WIDTH - 1 : 0] S_AXI_AWADDR,
   output logic    [C_S_AXI_ADDR_WIDTH - 1 : 0] S_AXI_ARADDR,
   output logic    [C_S_AXI_DATA_WIDTH - 1 : 0] S_AXI_WDATA,
   output logic                                 S_AXI_BREADY,
   output logic                                 S_AXI_RREADY

);

   integer dataFile;
   logic [16:0] weight_real;
   logic [16:0] weight_imag;
   
    initial S_AXI_WVALID  = 0;
    initial S_AXI_AWVALID = 0;
    initial S_AXI_ARVALID = 0;
    initial S_AXI_AWADDR  = 0;
    initial S_AXI_ARADDR  = 0;
    initial S_AXI_WDATA   = 0;
    initial S_AXI_BREADY  = 0;
    initial S_AXI_RREADY  = 0;

    task input_config();
        input [C_S_AXI_ADDR_WIDTH - 3 : 0] addr;
        input [C_S_AXI_DATA_WIDTH - 1 : 0] data;
 //       input [C_S_AXI_DATA_WIDTH / 2 - 1 : 0] data_I;
        begin
            @(posedge clk)
            #2
            S_AXI_WVALID = 1;
            S_AXI_AWVALID = 1;
            S_AXI_AWADDR = {addr,{2'b0}};
            @(posedge clk)
            #2
            S_AXI_AWADDR = 0;
            S_AXI_WDATA = data;
            @(posedge clk)
            #2
            S_AXI_WVALID = 0;
            S_AXI_AWVALID = 0;
            S_AXI_BREADY = 1;
            S_AXI_WDATA = 0;
            @(posedge clk)
            #2
            S_AXI_BREADY = 0;
        end
    endtask: input_config

    task FIR_config ();
       input           mode;  // 1 bit 1 for autocorrelation, 0 for cross-correlation
       input   [3:0]   taps;  // 4 bits taps = 8 ^ (n+1)
       input   [3:0]   shift; // 4 bits shift amount : the shift amount after fix point multiplecation
       input   [7:0]  delay_for_ac; //8 bits delay for autocorrelation
       input   [7:0]  last_taps; //for N taps, put in N - 1 
       begin
          input_config (0, {mode, taps, shift, delay_for_ac, 7'd0, last_taps});
       end
    endtask : FIR_config 
    
    task FIR_command ();
       input   [31:0]   command;       // 2
       begin
          input_config (1, command);
       end
    endtask : FIR_command
    
     task FIR_weights ();
       input   [15:0]   weight_real;       // 2
       input   [15:0]   weight_imag;
       begin
          input_config (3, {weight_real,weight_imag});
       end
    endtask : FIR_weights    

    initial begin
    
        dataFile = $fopen("fir_weights.dat","r");
        if (!dataFile) begin
            $display("Fail to find weight file");
            $finish;
        end
    
       delay_cycle (`RESET_CYCLE + 3);
       FIR_config (0, 'd15, 'd10, 0, 'd127);
       delay_cycle (2);

      for (integer i=0; i<128; i=i+1) begin
          $fscanf(dataFile, "%d %d", weight_real,weight_imag);
          FIR_weights (weight_real,weight_imag);
          delay_cycle (2);
      end   
             
       delay_cycle (2);
       FIR_command (1);
       delay_cycle (14000);
       FIR_command (2);
       delay_cycle (2);
       FIR_command (8);
    
       $fclose(dataFile);
       

       delay_cycle (200);
       FIR_command (3);
       delay_cycle (2);    
           
        dataFile = $fopen("fir_weights.dat","r");
        if (!dataFile) begin
            $display("Fail to find weight file");
            $finish;
        end
    
       delay_cycle (`RESET_CYCLE + 3);
       FIR_config (0, 'd15, 'd10, 0, 'd126);
       delay_cycle (2);

      for (integer i=0; i<128; i=i+1) begin
          $fscanf(dataFile, "%d %d", weight_real,weight_imag);
          FIR_weights (weight_real,weight_imag);
          delay_cycle (2);
      end   
             
       delay_cycle (2);
       FIR_command (1);
       delay_cycle (14000);
       FIR_command (2);
       delay_cycle (2);
       FIR_command (8);
       
       $fclose(dataFile);


       delay_cycle (200);
       FIR_command (3);
       delay_cycle (2);    
           
        dataFile = $fopen("fir_weights.dat","r");
        if (!dataFile) begin
            $display("Fail to find weight file");
            $finish;
        end
    
       delay_cycle (`RESET_CYCLE + 3);
       FIR_config (0, 'd15, 'd10, 0, 'd125);
       delay_cycle (2);

      for (integer i=0; i<128; i=i+1) begin
          $fscanf(dataFile, "%d %d", weight_real,weight_imag);
          FIR_weights (weight_real,weight_imag);
          delay_cycle (2);
      end   
             
       delay_cycle (2);
       FIR_command (1);
       delay_cycle (14000);
       FIR_command (2);
       delay_cycle (2);
       FIR_command (8);
       
       $fclose(dataFile);       
    end


endmodule
