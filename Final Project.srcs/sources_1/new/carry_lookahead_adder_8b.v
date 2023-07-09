`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/04/20 16:36:27
// Design Name: 
// Module Name: carry_lookahead_adder_8b
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


module carry_lookahead_adder_8b #(
    parameter   ADDER_WIDTH = 8
    )
    (
    input   wire [ADDER_WIDTH-1:0]  iA, iB, 
    input   wire                    iCarry,
    output  wire [ADDER_WIDTH-1:0]  oSum, 
    output  wire                    oCarry
    );

    wire [ADDER_WIDTH-1:0] wP,wG,wC;
    
    assign wP = iA ^ iB;//propagate
    assign wG = iA & iB; //generate
    
    //carry=gi + Pi.ci
    
    assign wC[0] = iCarry;
    assign wC[1] = wG[0] | (wP[0] & wC[0]);
    assign wC[2] = wG[1] | (wP[1] & wG[0]) | (wP[1] & wP[0] & wC[0]);
    assign wC[3] = wG[2] | (wP[2] & wG[1]) | (wP[2] & wP[1] & wG[0]) | (wP[2] & wP[1] & wP[0] & wC[0]);     
    assign wC[4] = wG[3] | (wP[3] & wG[2]) | (wP[3] & wP[2] & wG[1]) | (wP[3] & wP[2] & wP[1] & wG[0]) 
    | (wP[3] & wP[2] & wP[1] & wP[0] & wC[0]);
    assign wC[5] = wG[4] | (wP[4] & wG[3]) | (wP[4] & wP[3] & wG[2]) | (wP[4] & wP[3] & wP[2] & wG[1]) 
    | (wP[4] & wP[3] & wP[2] & wP[1] & wG[0]) | (wP[4] & wP[3] & wP[2] & wP[1] & wP[0] & wC[0]);
    assign wC[6] = wG[5] | (wP[5] & wG[4]) | (wP[5] & wP[4] & wG[3]) | (wP[5] & wP[4] & wP[3] & wG[2]) 
    | (wP[5] & wP[4] & wP[3] & wP[2] & wG[1]) | (wP[5] & wP[4] & wP[3] & wP[2] & wP[1] & wG[0]) 
    | (wP[5] & wP[4] & wP[3] & wP[2] & wP[1] & wP[0] & wC[0]);
    assign wC[7] = wG[6] | (wP[6] & wG[5]) | (wP[6] & wP[5] & wG[4]) | (wP[6] & wP[5] & wP[4] & wG[3]) 
    | (wP[6] & wP[5] & wP[4] & wP[3] & wG[2]) | (wP[6] & wP[5] & wP[4] & wP[3] & wP[2] & wG[1]) 
    | (wP[6] & wP[5] & wP[4] & wP[3] & wP[2] & wP[1] & wG[0]) | (wP[6] & wP[5] & wP[4] & wP[3] & wP[2] & wP[1] & wP[0] & wC[0]);
    assign oCarry = wG[7] | (wP[7] & wG[6]) | (wP[7] & wP[6] & wG[5]) | (wP[7] & wP[6] & wP[5] & wG[4]) 
    | (wP[7] & wP[6] & wP[5] & wP[4] & wG[3]) | (wP[7] & wP[6] & wP[5] & wP[4] & wP[3] & wG[2]) 
    | (wP[7] & wP[6] & wP[5] & wP[4] & wP[3] & wP[2] & wG[1]) | (wP[7] & wP[6] & wP[5] & wP[4] & wP[3] & wP[2] & wP[1] & wG[0]) 
    | (wP[7] & wP[6] & wP[5] & wP[4] & wP[3] & wP[2] & wP[1] & wP[0] & wC[0]);

    assign oSum = wP ^ wC;

endmodule
