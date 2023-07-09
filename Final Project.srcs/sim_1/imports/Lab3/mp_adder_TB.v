`timescale 1ns / 1ps

module mp_adder_TB();

  localparam CLOCK_PERIOD_NS = 100;
  
  localparam OPERAND_WIDTH   = 512; 
  localparam ADDER_WIDTH     = 128; 
  
  reg           rClk, rRst, rStart, rAddSub;
  reg [OPERAND_WIDTH-1:0]   rA, rB;
  
  wire [OPERAND_WIDTH:0]  wRes;
  wire          wDone;
  
  reg [OPERAND_WIDTH:0]  rExpectedResult;
  
  mp_adder #( .OPERAND_WIDTH(OPERAND_WIDTH), .ADDER_WIDTH(ADDER_WIDTH) )
  mp_adder_INST
  ( .iClk(rClk), .iRst(rRst), .iStart(rStart), .iAddSub(rAddSub), .iOpA(rA), .iOpB(rB), .oRes(wRes), .oDone(wDone) );

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
      rAddSub = 1;
      rA = 0;
      rB = 0;
      
      #(5*T);
      rRst = 0;
      #(5*T);
      
      rStart = 1;           
      rA <= 512'hcccdcf726f8eb3f338b88e0a9180ba68d82cfa81c28bb684e6993b2e2990c889fdaafa24c586853fc5aff5f8993d19695e7ca46312da80b4ddf550cc8bf992ce;
      rB <= 512'ha11dffc7990dc1ec2623884df1a9a829ea80bfb0fdeb12a8d16e7f9a0c75ac24b653a2b2a750765830d384abff939839ca4a50d5c89406a1da73fcf6b05b6965;
      #T;
      // rExpectedResult = rA + rB;
//      rExpectedResult <= 513'h16debcf3a089c75df5edc1658832a6292c2adba32c076c92db807bac8360674aeb3fe9cd76cd6fb97f6837aa498d0b1a328c6f538db6e8756b8694dc33c54fc33;
      rExpectedResult <= 513'h12bafcfaad680f207129505bc9fd7123eedac3ad0c4a0a3dc152abb941d1b1c65475757721e360ee794dc714c99a9812f9432538d4a467a13038153d5db9e2969;
      rStart = 0;
            
      // wait until wDone is asserted     
      @(posedge wDone);
      
      // display the results in the terminal
      $display(rExpectedResult);
      $display(wRes);
      
      // compare results
      if ( rExpectedResult != wRes )
        $display("Test Failed - Incorrect Addition");
      else
        $display("Test Passed - Correct Addition");
      
      #(5*T);
        
      $stop;
    end

endmodule
