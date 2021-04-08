`timescale 1 ns / 1 ps

module stream_slave_test (
   output logic M_AXIS_TREADY
);
   
   initial begin
   M_AXIS_TREADY = 1;
   delay_cycle(1070);
   M_AXIS_TREADY = 0;
   delay_cycle(28);
   M_AXIS_TREADY = 1;
   end
endmodule 
