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


module carry_select_adder_128b #(
        parameter   ADDER_WIDTH = 128 
    )
    (
        input   wire [ADDER_WIDTH-1:0]  iA, iB, 
        input   wire                    iCarry,
        output  wire [ADDER_WIDTH-1:0]  oSum, 
        output  wire                    oCarry
    );
    
    wire [14:0] wCarry; 
    assign wCarry[0] = iCarry;   
    assign oCarry = wCarry[14];      
    
    ripple_carry_adder_Nb #( .ADDER_WIDTH(2) ) ripple_carry_adder_inst            
    (
        .iA( iA[1:0] ), 
        .iB( iB[1:0] ),
        .iCarry( wCarry[0] ),
        .oSum( oSum[1:0] ),
        .oCarry( wCarry[1] )
    );
    genvar f;
    generate                  
        for (f = 0; f < 3; f = f+1) 
        begin   
            carry_select_adder_slice_ripple_carry #( .ADDER_WIDTH(2) ) carry_select_adder_slice_ripple_carry_inst            
            (
                .iA( iA[f*2+2+2-1:f*2+2] ), 
                .iB( iB[f*2+2+2-1:f*2+2] ),
                .iCarry( wCarry[f+1] ),
                .oSum( oSum[f*2+2+2-1:f*2+2] ),
                .oCarry( wCarry[f+1+1] )
            );
        end                   
    endgenerate
    
    localparam base_lookahead_4b = 8;
    localparam carry_base_lookahead_4b = 4;
    genvar i;
    generate                  
        for (i = 0; i < (16-base_lookahead_4b)/4; i = i+1) 
        begin   
            carry_select_adder_slice_carry_lookahead_4b carry_select_adder_slice_carry_lookahead_4b_inst            
            (
                .iA( iA[(i*4)+4+base_lookahead_4b-1 : i*4+base_lookahead_4b] ), 
                .iB( iB[(i*4)+4+base_lookahead_4b-1 : i*4+base_lookahead_4b] ),
                .iCarry( wCarry[i+carry_base_lookahead_4b] ),
                .oSum( oSum[(i*4)+4+base_lookahead_4b-1 : i*4+base_lookahead_4b] ),
                .oCarry( wCarry[i+1+carry_base_lookahead_4b] )
            );
        end                   
    endgenerate
    
    localparam base_lookahead_8b = 16;
    localparam carry_base_lookahead_8b = 6;
    genvar k;
    generate                  
        for (k = 0; k < (48-base_lookahead_8b)/8; k = k+1) 
        begin   
            carry_select_adder_slice_carry_lookahead_8b carry_select_adder_slice_carry_lookahead_8b_inst            
            (
                .iA( iA[(k*8)+8+base_lookahead_8b-1 : k*8+base_lookahead_8b] ), 
                .iB( iB[(k*8)+8+base_lookahead_8b-1 : k*8+base_lookahead_8b] ),
                .iCarry( wCarry[k+carry_base_lookahead_8b] ),
                .oSum( oSum[(k*8)+8+base_lookahead_8b-1 : k*8+base_lookahead_8b] ),
                .oCarry( wCarry[k+1+carry_base_lookahead_8b] )
            );
        end                   
    endgenerate
    
    localparam base_kogge_stone = 48;
    localparam carry_base_kogge_stone = 10;
    genvar j;
    generate                  
        for (j = 0; j < (96-base_kogge_stone)/16; j = j+1) 
        begin   
            carry_select_adder_slice_kogge_stone_Nb #( .ADDER_WIDTH(16) ) carry_select_adder_slice_kogge_stone_inst            
            (
                .iA( iA[(j*16)+16+base_kogge_stone-1 : j*16+base_kogge_stone] ), 
                .iB( iB[(j*16)+16+base_kogge_stone-1 : j*16+base_kogge_stone] ),
                .iCarry( wCarry[j+carry_base_kogge_stone] ),
                .oSum( oSum[(j*16)+16+base_kogge_stone-1 : j*16+base_kogge_stone] ),
                .oCarry( wCarry[j+1+carry_base_kogge_stone] )
            );
        end                   
    endgenerate
    
    carry_select_adder_slice_kogge_stone_Nb #( .ADDER_WIDTH(32) ) carry_select_adder_slice_kogge_stone_inst          
    (
        .iA( iA[127 : 96] ), 
        .iB( iB[127 : 96] ),
        .iCarry( wCarry[13] ),
        .oSum( oSum[127 : 96] ),
        .oCarry( wCarry[14] )
    ); 

endmodule

module carry_select_adder_Nb #(
        parameter   ADDER_WIDTH = 32,
        parameter   SUBADDER_WIDTH = 16  
    )
    (
        input   wire [ADDER_WIDTH-1:0]  iA, iB, 
        input   wire                    iCarry,
        output  wire [ADDER_WIDTH-1:0]  oSum, 
        output  wire                    oCarry
    );
    
    wire [ADDER_WIDTH/SUBADDER_WIDTH:0] wCarry;           
    assign wCarry[0] = iCarry;
    
    genvar i;
    generate                  
        for (i = 0; i < ADDER_WIDTH/SUBADDER_WIDTH; i = i+1) 
        begin   
            carry_select_adder_slice_kogge_stone_Nb #( .ADDER_WIDTH(16) ) carry_select_adder_slice_kogge_stone_inst            
            (
                .iA( iA[(i*SUBADDER_WIDTH)+SUBADDER_WIDTH-1 : i*SUBADDER_WIDTH] ), 
                .iB( iB[(i*SUBADDER_WIDTH)+SUBADDER_WIDTH-1 : i*SUBADDER_WIDTH] ),
                .iCarry( wCarry[i] ),
                .oSum( oSum[(i*SUBADDER_WIDTH)+SUBADDER_WIDTH-1 : i*SUBADDER_WIDTH] ),
                .oCarry( wCarry[i+1] )
            );
        end                   
    endgenerate               
    assign oCarry = wCarry[ADDER_WIDTH/SUBADDER_WIDTH];

endmodule

module carry_select_adder_Nb_look_ahead #(
        parameter   ADDER_WIDTH = 32,
        parameter   SUBADDER_WIDTH = 4  
    )
    (
        input   wire [ADDER_WIDTH-1:0]  iA, iB, 
        input   wire                    iCarry,
        output  wire [ADDER_WIDTH-1:0]  oSum, 
        output  wire                    oCarry
    );
    
    wire [ADDER_WIDTH/SUBADDER_WIDTH:0] wCarry;           
    assign wCarry[0] = iCarry;
    
    genvar i;
    generate                  
        for (i = 0; i < ADDER_WIDTH/SUBADDER_WIDTH; i = i+1) 
        begin   
            carry_select_adder_slice_carry_lookahead_4b carry_select_adder_slice_carry_lookahead_4b_inst            
            (
                .iA( iA[(i*SUBADDER_WIDTH)+SUBADDER_WIDTH-1 : i*SUBADDER_WIDTH] ), 
                .iB( iB[(i*SUBADDER_WIDTH)+SUBADDER_WIDTH-1 : i*SUBADDER_WIDTH] ),
                .iCarry( wCarry[i] ),
                .oSum( oSum[(i*SUBADDER_WIDTH)+SUBADDER_WIDTH-1 : i*SUBADDER_WIDTH] ),
                .oCarry( wCarry[i+1] )
            );
        end                   
    endgenerate               
    assign oCarry = wCarry[ADDER_WIDTH/SUBADDER_WIDTH];

endmodule