`timescale 1 ns / 1 ps

module  stream_master_test #(
 parameter C_S_AXIS_TDATA_WIDTH = 32
)
(
   input            clk,
   output logic  [C_S_AXIS_TDATA_WIDTH-1 : 0]     S_AXIS_TDATA,
   output logic  [(C_S_AXIS_TDATA_WIDTH/8)-1 : 0] S_AXIS_TSTRB,
   output logic                                   S_AXIS_TLAST,
   output logic                                   S_AXIS_TVALID
);
   initial  S_AXIS_TDATA = 0;
   initial  S_AXIS_TSTRB = 0;
   initial  S_AXIS_TLAST = 0;
   initial  S_AXIS_TVALID = 0;
   
   integer dataFile;
   reg [31:0] wdat;
   integer ret;
   integer  rdat;
   integer  idat;
   logic end_of_stream=0;
   
   task input_data(); 
      input  [C_S_AXIS_TDATA_WIDTH/2 - 1 : 0] R;
      input  [C_S_AXIS_TDATA_WIDTH/2 - 1 : 0] I;
      input  last;
      begin
         @(posedge clk)
         #2
         S_AXIS_TDATA  = {R,I};
         S_AXIS_TVALID = 1;
         if(last)begin
         S_AXIS_TLAST = 1;
         end
         else begin
         S_AXIS_TLAST = 0;
         end
      end
   endtask
   
   task no_input();
      begin
         @(posedge clk)
         #2
         S_AXIS_TDATA = 0;
         S_AXIS_TVALID = 0; 
         S_AXIS_TLAST = 0;
      end
   endtask


   initial begin
   
     delay_cycle (`RESET_CYCLE + 1000);
    // data file read
//      dataFile = $fopen("../../../../tx_4000.txt","r");
        dataFile = $fopen("fir_input.dat","r");
        if (!dataFile) begin
            $display("Fail to find data file");
            $finish;
        end
   
/*      delay_cycle (`RESET_CYCLE + 20);
      for (integer i = 1; i < 65; i = i + 1) begin
      input_data  (i, 0);
      end
      for (integer i = 1; i < 65; i = i + 1) begin
      input_data  (i, 0);
      end
      no_input ();*/
      
      for (integer i=0; i<1613; i=i+1) begin
            ret = $fscanf(dataFile, "%d %d", rdat, idat);
            
            if(i==1613-1)
            end_of_stream = 1;
            else
            end_of_stream = 0;
            
            input_data  (rdat, idat,end_of_stream);
      end
         
       no_input ();   
       
       $fclose(dataFile);

        delay_cycle (15000);
        
        dataFile = $fopen("fir_input.dat","r");
        if (!dataFile) begin
            $display("Fail to find data file");
            $finish;
        end
   
/*      delay_cycle (`RESET_CYCLE + 20);
      for (integer i = 1; i < 65; i = i + 1) begin
      input_data  (i, 0);
      end
      for (integer i = 1; i < 65; i = i + 1) begin
      input_data  (i, 0);
      end
      no_input ();*/
      
      for (integer i=0; i<1613; i=i+1) begin
            ret = $fscanf(dataFile, "%d %d", rdat, idat);
            
            if(i==1613-1)
            end_of_stream = 1;
            else
            end_of_stream = 0;
            
            input_data  (rdat, idat,end_of_stream);
      end
         
       no_input ();   
       
       $fclose(dataFile);

        delay_cycle (15000);
        
        dataFile = $fopen("fir_input.dat","r");
        if (!dataFile) begin
            $display("Fail to find data file");
            $finish;
        end
   
/*      delay_cycle (`RESET_CYCLE + 20);
      for (integer i = 1; i < 65; i = i + 1) begin
      input_data  (i, 0);
      end
      for (integer i = 1; i < 65; i = i + 1) begin
      input_data  (i, 0);
      end
      no_input ();*/
      
      for (integer i=0; i<1613; i=i+1) begin
            ret = $fscanf(dataFile, "%d %d", rdat, idat);
            
            if(i==1613-1)
            end_of_stream = 1;
            else
            end_of_stream = 0;
            
            input_data  (rdat, idat,end_of_stream);
      end
         
       no_input ();   
       
       $fclose(dataFile);
      
   end
   

endmodule
