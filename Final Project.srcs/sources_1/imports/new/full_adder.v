`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/02/23 11:05:15
// Design Name: 
// Module Name: full_adder
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


module full_adder(
    input   wire    iA, iB, iCarry,
    output  wire    oSum, oCarry
    );
    
    reg rSum, rCarry;
    always @ (*)
    begin
        rSum = (iA^iB) ^ iCarry;
        rCarry = ((iA^iB) & iCarry) | (iA&iB);
    end
    
    assign oSum = rSum;
    assign oCarry = rCarry;
endmodule
