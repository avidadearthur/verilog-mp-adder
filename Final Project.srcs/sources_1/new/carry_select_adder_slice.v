`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/04/20 17:21:34
// Design Name: 
// Module Name: carry_select_adder_Nb
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


module carry_select_adder_slice_kogge_stone_Nb #(
        parameter   ADDER_WIDTH = 64,
        parameter   SUBADDER_WIDTH = 16  
    )
    (
        input   wire [ADDER_WIDTH-1:0]  iA, iB, 
        input   wire                    iCarry,
        output  wire [ADDER_WIDTH-1:0]  oSum, 
        output  wire                    oCarry
    );
    
    wire [ADDER_WIDTH-1:0] wS0, wS1;
    wire [ADDER_WIDTH/SUBADDER_WIDTH:0] wC0, wC1; 
    
    assign wC0[0] = 1'b0;
    assign wC1[0] = 1'b1;   
        
    genvar i;                 
    generate                  
        for (i = 0; i < ADDER_WIDTH/SUBADDER_WIDTH; i = i+1) 
        begin                 
            kogge_stone_adder_16b  kogge_stone_adder_16b_inst               
            (
                .iA( iA[(i*SUBADDER_WIDTH)+SUBADDER_WIDTH-1 : i*SUBADDER_WIDTH] ), 
                .iB( iB[(i*SUBADDER_WIDTH)+SUBADDER_WIDTH-1 : i*SUBADDER_WIDTH] ),
                .iCarry( wC0[i] ),
                .oSum( wS0[(i*SUBADDER_WIDTH)+SUBADDER_WIDTH-1 : i*SUBADDER_WIDTH] ),
                .oCarry( wC0[i+1] )
            );
        end                   
    endgenerate
    
    genvar j;                 
    generate                  
        for (j = 0; j < ADDER_WIDTH/SUBADDER_WIDTH; j = j+1) 
        begin                 
            kogge_stone_adder_16b  kogge_stone_adder_16b_inst               
            (
                .iA( iA[(j*SUBADDER_WIDTH)+SUBADDER_WIDTH-1 : j*SUBADDER_WIDTH] ), 
                .iB( iB[(j*SUBADDER_WIDTH)+SUBADDER_WIDTH-1 : j*SUBADDER_WIDTH] ),
                .iCarry( wC1[j] ),
                .oSum( wS1[(j*SUBADDER_WIDTH)+SUBADDER_WIDTH-1 : j*SUBADDER_WIDTH] ),
                .oCarry( wC1[j+1] )
            );
        end                   
    endgenerate               
    
    mux2X1 #(ADDER_WIDTH) mux2X1_inst_sum(
        .iIn0( wS0 ),
        .iIn1( wS1 ),
        .iSel( iCarry ),
        .oOut( oSum )
        );
    
    mux2X1 #(1) mux2X1_inst_carry(
        .iIn0( wC0[ADDER_WIDTH/SUBADDER_WIDTH] ),
        .iIn1( wC1[ADDER_WIDTH/SUBADDER_WIDTH] ),
        .iSel( iCarry ),
        .oOut( oCarry )
        );
    
endmodule

module carry_select_adder_slice_ripple_carry #(
    parameter   ADDER_WIDTH = 2
    )
    (
    input   wire [ADDER_WIDTH-1:0]  iA, iB, 
    input   wire                    iCarry,
    output  wire [ADDER_WIDTH-1:0]  oSum, 
    output  wire                    oCarry
    );
    
    wire [ADDER_WIDTH-1:0] wS0, wS1;
    wire wC0, wC1;
    
    ripple_carry_adder_Nb #( .ADDER_WIDTH(2) ) ripple_carry_adder_Nb_inst1 (
        .iA( iA ), 
        .iB( iB ),
        .iCarry( 1'b0 ),
        .oSum( wS0 ),
        .oCarry( wC0 )
        );

    ripple_carry_adder_Nb  #( .ADDER_WIDTH(2) ) ripple_carry_adder_Nb_inst2 (
         .iA( iA ), 
        .iB( iB ),
        .iCarry( 1'b1 ),
        .oSum( wS1 ),
        .oCarry( wC1 )
        );
    
    mux2X1 #(ADDER_WIDTH) mux2X1_inst_sum(
        .iIn0( wS0 ),
        .iIn1( wS1 ),
        .iSel( iCarry ),
        .oOut( oSum )
        );
    
    mux2X1 #(1) mux2X1_inst_carry(
        .iIn0( wC0 ),
        .iIn1( wC1 ),
        .iSel( iCarry ),
        .oOut( oCarry )
        );
endmodule

module carry_select_adder_slice_carry_lookahead_4b #(
    parameter   ADDER_WIDTH = 4
    )
    (
    input   wire [ADDER_WIDTH-1:0]  iA, iB, 
    input   wire                    iCarry,
    output  wire [ADDER_WIDTH-1:0]  oSum, 
    output  wire                    oCarry
    );
    
    wire [ADDER_WIDTH-1:0] wS0, wS1;
    wire wC0, wC1;
    
    carry_lookahead_adder_4b carry_lookahead_adder_4b_inst1 (
        .iA( iA ), 
        .iB( iB ),
        .iCarry( 1'b0 ),
        .oSum( wS0 ),
        .oCarry( wC0 )
        );

    carry_lookahead_adder_4b carry_lookahead_adder_4b_inst2 (
         .iA( iA ), 
        .iB( iB ),
        .iCarry( 1'b1 ),
        .oSum( wS1 ),
        .oCarry( wC1 )
        );
    
    mux2X1 #(ADDER_WIDTH) mux2X1_inst_sum(
        .iIn0( wS0 ),
        .iIn1( wS1 ),
        .iSel( iCarry ),
        .oOut( oSum )
        );
    
    mux2X1 #(1) mux2X1_inst_carry(
        .iIn0( wC0 ),
        .iIn1( wC1 ),
        .iSel( iCarry ),
        .oOut( oCarry )
        );
endmodule

module carry_select_adder_slice_carry_lookahead_8b #(
    parameter   ADDER_WIDTH = 8
    )
    (
    input   wire [ADDER_WIDTH-1:0]  iA, iB, 
    input   wire                    iCarry,
    output  wire [ADDER_WIDTH-1:0]  oSum, 
    output  wire                    oCarry
    );
    
    wire [ADDER_WIDTH-1:0] wS0, wS1;
    wire wC0, wC1;
    
    carry_lookahead_adder_8b carry_lookahead_adder_8b_inst1 (
        .iA( iA ), 
        .iB( iB ),
        .iCarry( 1'b0 ),
        .oSum( wS0 ),
        .oCarry( wC0 )
        );

    carry_lookahead_adder_8b carry_lookahead_adder_8b_inst2 (
         .iA( iA ), 
        .iB( iB ),
        .iCarry( 1'b1 ),
        .oSum( wS1 ),
        .oCarry( wC1 )
        );
    
    mux2X1 #(ADDER_WIDTH) mux2X1_inst_sum(
        .iIn0( wS0 ),
        .iIn1( wS1 ),
        .iSel( iCarry ),
        .oOut( oSum )
        );
    
    mux2X1 #(1) mux2X1_inst_carry(
        .iIn0( wC0 ),
        .iIn1( wC1 ),
        .iSel( iCarry ),
        .oOut( oCarry )
        );
endmodule

module mux2X1 #(
    parameter   WIDTH = 16
    )
    (
    input   wire [WIDTH-1:0]  iIn0, iIn1,
    input   wire              iSel,
    output  wire [WIDTH-1:0]  oOut
    );
    
    assign oOut = (iSel) ? iIn1 : iIn0;
endmodule
