`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/04/22 09:36:17
// Design Name: 
// Module Name: wallace_tree_multiplier
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


module wallace_tree_multiplier #(
    parameter   MULTIPLIER_WIDTH = 4
    )
    (
    input   wire [MULTIPLIER_WIDTH-1:0]     iA, iB, 
    output  wire [MULTIPLIER_WIDTH*2-1:0]   oRes
    );

    // internal variables
    wire s11,s12,s13,s14,s15,s22,s23,s24,s25,s26,s32,s33,s34,s35,s36,s37;
    wire c11,c12,c13,c14,c15,c22,c23,c24,c25,c26,c32,c33,c34,c35,c36,c37;
    wire [6:0] p0,p1,p2,p3;

    // partial results
    assign  p0 = iA & {4{iB[0]}};
    assign  p1 = iA & {4{iB[1]}};
    assign  p2 = iA & {4{iB[2]}};
    assign  p3 = iA & {4{iB[3]}};

    // first stage
    half_adder ha11 (p0[1],p1[0],s11,c11);
    full_adder fa12(p0[2],p1[1],p2[0],s12,c12);
    full_adder fa13(p0[3],p1[2],p2[1],s13,c13);
    half_adder ha14(p1[3],p2[2],s14,c14);

    // second stage
    half_adder ha22 (c11,s12,s22,c22);
    full_adder fa23 (c12,s13,p3[0],s23,c23);
    full_adder fa24 (c13,s14,p3[1],s24,c24);
    full_adder fa25 (c14,p3[2],p2[3],s25,c25);
    
    // final stage
    carry_lookahead_adder_4b carry_lookahead_adder_4b_inst
    (
        .iA({p3[3],s25,s24,s23}),
        .iB({c25,c24,c23,c22}),
        .iCarry(1'b0),
        .oSum(oRes[6:3]),
        .oCarry(oRes[7])
    );
    
    // final product assignments    
    assign oRes[0] = p0[0];
    assign oRes[1] = s11;
    assign oRes[2] = s22;

endmodule

module half_adder(input iA, iB, output s0, c0);
  assign s0 = iA ^ iB;
  assign c0 = iA & iB;
endmodule
