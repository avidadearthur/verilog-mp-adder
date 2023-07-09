`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/04/20 17:46:24
// Design Name: 
// Module Name: carry_select_adder_Nb_TB
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


module carry_select_adder_Nb_TB;
  parameter OPERAND_WIDTH = 128;
  
  // Inputs and outputs
  reg [OPERAND_WIDTH-1:0] rA, rB;
  reg rCarry;
  wire [OPERAND_WIDTH-1:0] wSum;
  wire wCarry;
  
  // Instantiate the DUT
//  carry_select_adder_slice_kogge_stone_Nb #( .ADDER_WIDTH(OPERAND_WIDTH) )
//  carry_select_adder_slice_kogge_stone_Nb_inst (
//    .iA(rA),
//    .iB(rB),
//    .iCarry(rCarry),
//    .oSum(wSum),
//    .oCarry(wCarry)
//  );
  carry_select_adder_128b #( .ADDER_WIDTH(OPERAND_WIDTH) )
  carry_select_adder_128b_inst (
    .iA(rA),
    .iB(rB),
    .iCarry(rCarry),
    .oSum(wSum),
    .oCarry(wCarry)
  );
//  carry_select_adder_Nb #( .ADDER_WIDTH(OPERAND_WIDTH) )
//  carry_select_adder_Nb_inst (
//    .iA(rA),
//    .iB(rB),
//    .iCarry(rCarry),
//    .oSum(wSum),
//    .oCarry(wCarry)
//  );
  
  wire [OPERAND_WIDTH:0] expected;
  assign expected = rA + rB + rCarry;
  
  integer i;
  initial
    begin
      $monitor ("(%d + %d + %d) = %d  expected = %d", rA, rB, rCarry, {wCarry, wSum}, expected);
      // Use a for loop to apply random values to the input  
      for (i = 0; i < 5; i = i+1) 
        begin  
          #10 
          rA <= $random;  
          rB <= $random;  
          rCarry <= $random;  
        end  
    end
endmodule
