`timescale 1ns / 1ps

module uart_top_TB ();
 
  // Define signals for module under test
  reg  rClk = 0;
  reg  rRst = 0;
  wire wRx, wTx;
  
  // We downscale the values in the simulation
  // this will give CLKS_PER_BIT = 100 / 10 = 10
  localparam CLK_FREQ_inst  = 100;
  localparam BAUD_RATE_inst = 10;
  localparam OPERAND_WIDTH = 512;
  localparam ADDER_WIDTH = 128;
  localparam OPERAND_WIDTH_MUL = 256;
  
  reg rTxStart = 0;
  reg [7:0] rTxByte = 0;
  wire wTxDone;
  // instantiate module under test
  uart_tx #( .CLK_FREQ(CLK_FREQ_inst), .BAUD_RATE(BAUD_RATE_inst) ) 
  UART_TX_INST
    (.iClk(rClk),
     .iRst(rRst),
     .iTxStart(rTxStart),
     .iTxByte(rTxByte),
     .oTxSerial(wRx),
     .oTxDone(wTxDone)
     );
    
  // Instantiate DUT  
  uart_top #( .OPERAND_WIDTH(OPERAND_WIDTH), .ADDER_WIDTH(ADDER_WIDTH), .CLK_FREQ(CLK_FREQ_inst), .BAUD_RATE(BAUD_RATE_inst) ) 
  uart_top_inst
  ( .iClk(rClk), .iRst(rRst), .iRx(wRx), .oTx(wTx) );
  
  wire wRxDone;
  wire [7:0] wRxByte;
  // instantiate module under test
  uart_rx #( .CLK_FREQ(CLK_FREQ_inst), .BAUD_RATE(BAUD_RATE_inst) ) 
  UART_RX_INST
    (.iClk(rClk),
     .iRst(rRst),
     .iRxSerial(wTx),
     .oRxByte(wRxByte),
     .oRxDone(wRxDone)
     );
  
  // Define clock signal
  localparam CLOCK_PERIOD = 5;
  localparam NBYTES = OPERAND_WIDTH/8*2+1; // 129 bytes
  localparam NBYTES_MUL = OPERAND_WIDTH_MUL/8*2+1; // 129 bytes
  
  always
    #(CLOCK_PERIOD/2) rClk <= !rClk;
 
  integer i;
  reg [OPERAND_WIDTH*2+7:0] rBuffer;
  reg [OPERAND_WIDTH_MUL*2+7:0] rBuffer_MUL;
  reg [OPERAND_WIDTH+7:0] result_expected;
  reg [7:0] rCom;
  reg [OPERAND_WIDTH-1:0] rA;
  reg [OPERAND_WIDTH-1:0] rB;
  
  // Input stimulus
  initial
    begin
      rCom = 8'h02;
      
      if (rCom != 02)
      begin
      rA = 512'hcccdcf726f8eb3f338b88e0a9180ba68d82cfa81c28bb684e6993b2e2990c889fdaafa24c586853fc5aff5f8993d19695e7ca46312da80b4ddf550cc8bf992ce;
      rB = 512'ha11dffc7990dc1ec2623884df1a9a829ea80bfb0fdeb12a8d16e7f9a0c75ac24b653a2b2a750765830d384abff939839ca4a50d5c89406a1da73fcf6b05b6965;
      rBuffer = {rCom, rA, rB};
      end
      else
      begin
      rA = 256'h12121212_34343434_56565656_78787878_efefefef_cdcdcdcd_abababab_90909090;
      rB = 256'hefefefef_cdcdcdcd_abababab_90909090_12121212_34343434_56565656_78787878;
      rBuffer_MUL = {rCom, rA[OPERAND_WIDTH_MUL-1:0], rB[OPERAND_WIDTH_MUL-1:0]};
      end
      
      result_expected = 0;
      if (rCom == 0)
          result_expected = rA + rB;
      else if (rCom == 1)
          result_expected = rA - rB;
      else if (rCom == 2)
          result_expected = rA[OPERAND_WIDTH_MUL-1:0] * rB[OPERAND_WIDTH_MUL-1:0];
      
      rTxStart = 0;
      rRst = 1;
      #(5*CLOCK_PERIOD);
      rRst =0;
      
      if (rCom != 2)
      begin
          for (i = 0; i < NBYTES; i = i+1) 
          begin  
          // circuit is reset 
          rTxByte = rBuffer[NBYTES*8-1:NBYTES*8-8];
          #(5*CLOCK_PERIOD);
          
          // assert rTxStart to send a frame (only 1 clock cycle!)
          rTxStart = 1;
          #(CLOCK_PERIOD);
          rTxStart = 0;
          rTxByte = 8'h00;
          rBuffer = { rBuffer[NBYTES*8-9:0], 8'b0000_0000 };
          
          // let the counter run for 150 clock cycles
          #(100*CLOCK_PERIOD);
          end   
      end
      else
      begin
      for (i = 0; i < NBYTES_MUL; i = i+1) 
      begin  
          // circuit is reset 
          rTxByte = rBuffer_MUL[NBYTES_MUL*8-1:NBYTES_MUL*8-8];
          #(5*CLOCK_PERIOD);
          
          // assert rTxStart to send a frame (only 1 clock cycle!)
          rTxStart = 1;
          #(CLOCK_PERIOD);
          rTxStart = 0;
          rTxByte = 8'h00;
          rBuffer_MUL = { rBuffer_MUL[NBYTES_MUL*8-9:0], 8'b0000_0000 };
          
          // let the counter run for 150 clock cycles
          #(100*CLOCK_PERIOD);
      end 
      end 
          
      // Let it run for a while
      #(3000*CLOCK_PERIOD);
            
      $stop;
           
    end
   
endmodule