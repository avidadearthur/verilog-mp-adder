`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/02/23 11:56:13
// Design Name: 
// Module Name: ripple_carry_adder_Nb
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


module ripple_carry_adder_Nb #(
    parameter   ADDER_WIDTH = 16
    )
    (
    input   wire [ADDER_WIDTH-1:0]  iA, iB, 
    input   wire                    iCarry,
    output  wire [ADDER_WIDTH-1:0]  oSum, 
    output  wire                    oCarry
);
    
    wire [ADDER_WIDTH:0] tCarry;         
    genvar i;                 
    assign tCarry[0] = iCarry;
    generate                  
        for (i=0; i < ADDER_WIDTH; i=i+1) 
        begin                 
            full_adder full_adder_inst
            (                 
                .iA(iA[i]),   
                .iB(iB[i]),   
                .iCarry(tCarry[i]),
                .oSum(oSum[i]),
                .oCarry(tCarry[i+1])
            );                
        end                   
    endgenerate               
    assign oCarry = tCarry[ADDER_WIDTH];
endmodule
