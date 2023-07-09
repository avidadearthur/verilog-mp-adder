`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/04/22 11:43:27
// Design Name: 
// Module Name: mp_multiplier_TB
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module mp_multiplier_TB;

 localparam CLOCK_PERIOD_NS = 100;
  
  localparam OPERAND_WIDTH   = 64; 
  
  reg                           rClk, rRst, rStart;
  wire                          wDone;
  reg [OPERAND_WIDTH-1:0]       rA, rB; 
  wire [OPERAND_WIDTH*2-1:0]    wRes;
  reg [OPERAND_WIDTH*2-1:0]  rExpectedResult;
  
  mp_multiplier_64b #( .OPERAND_WIDTH(OPERAND_WIDTH) )
  multiplier_inst
  ( .iClk(rClk), .iRst(rRst), .iStart(rStart), .iA(rA), .iB(rB), .oRes(wRes), .oDone(wDone) );

  // definition of clock period
  localparam  T = 20;  
  
  // generation of clock signal
  always 
  begin
    rClk = 1;
    #(T/2);
    rClk = 0;
    #(T/2);
  end
  
  initial
    begin
      rRst = 1;
      rStart = 0;
      rA = 0;
      rB = 0;
      #(5*T);
      rRst = 0;
      #(5*T);
      
      rStart = 1;
      rA <= 512'h12121212_34343434_56565656_78787878_efefefef_cdcdcdcd_abababab_90909090_12121212_34343434_56565656_78787878_efefefef_cdcdcdcd_abababab_abababab;
      rB <= 512'hefefefef_cdcdcdcd_abababab_90909090_12121212_34343434_56565656_78787878_efefefef_cdcdcdcd_abababab_90909090_12121212_34343434_56565656_78787878;
      #T;
      rExpectedResult = rA * rB;
      rStart = 0;
            
      // wait until wDone is asserted     
      @(posedge wDone);
      
      // display the results in the terminal
      $display(rExpectedResult);
      $display(wRes);
      
      // compare results
      if ( rExpectedResult != wRes )
        $display("Test Failed - Incorrect Multiplication");
      else
        $display("Test Passed - Correct Multiplication");
      
      #(5*T);
        
      $stop;
    end
    
endmodule