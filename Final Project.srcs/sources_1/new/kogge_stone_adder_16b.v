`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/04/20 22:13:11
// Design Name: 
// Module Name: kogge_stone_adder_16b
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

module kogge_stone_adder_16b #(
    parameter   ADDER_WIDTH = 16
    )
    (
    input   wire [ADDER_WIDTH-1:0]  iA, iB, 
    input   wire                    iCarry,
    output  wire [ADDER_WIDTH-1:0]  oSum, 
    output  wire                    oCarry
    );            

    wire [ADDER_WIDTH-1:0] wP;
    wire [ADDER_WIDTH-1:0] wG;
    
    // bit propagate and generate
    genvar i;                 
    generate                  
        for (i = 0; i < ADDER_WIDTH; i = i+1) 
        begin                 
            pre_processing pre_processing_inst(iA[i],iB[i],wP[i],wG[i]);
        end                   
    endgenerate
    
    // stage 1
    group_generate f17(iCarry,wP[0],wG[0],C);
    
    group_popagate_generate f18(wP[0],wG[0],wP[1],wG[1],a1,b1);
    group_popagate_generate f19(wP[1],wG[1],wP[2],wG[2],a2,b2);
    group_popagate_generate f20(wP[2],wG[2],wP[3],wG[3],a3,b3);
    group_popagate_generate f21(wP[3],wG[3],wP[4],wG[4],a4,b4);
    group_popagate_generate f22(wP[4],wG[4],wP[5],wG[5],a5,b5);
    group_popagate_generate f23(wP[5],wG[5],wP[6],wG[6],a6,b6);
    group_popagate_generate f24(wP[6],wG[6],wP[7],wG[7],a7,b7);
    group_popagate_generate f25(wP[7],wG[7],wP[8],wG[8],a8,b8);
    group_popagate_generate f26(wP[8],wG[8],wP[9],wG[9],a9,b9);
    group_popagate_generate f27(wP[9],wG[9],wP[10],wG[10],a10,b10);
    group_popagate_generate f28(wP[10],wG[10],wP[11],wG[11],a11,b11);
    group_popagate_generate f29(wP[11],wG[11],wP[12],wG[12],a12,b12);
    group_popagate_generate f30(wP[12],wG[12],wP[13],wG[13],a13,b13);
    group_popagate_generate f31(wP[13],wG[13],wP[14],wG[14],a14,b14);
    group_popagate_generate f32(wP[14],wG[14],wP[15],wG[15],a15,b15);
    
    // stage 2
    group_generate f33(iCarry,a1,b1,c1);
    group_generate f34(C,a2,b2,c2);
    
    group_popagate_generate f35(a1,b1,a3,b3,a16,b16);
    group_popagate_generate f36(a2,b2,a4,b4,a17,b17);
    group_popagate_generate f37(a3,b3,a5,b5,a18,b18);
    group_popagate_generate f38(a4,b4,a6,b6,a19,b19);
    group_popagate_generate f39(a5,b5,a7,b7,a20,b20);
    group_popagate_generate f40(a6,b6,a8,b8,a21,b21);
    group_popagate_generate f41(a7,b7,a9,b9,a22,b22);
    group_popagate_generate f42(a8,b8,a10,b10,a23,b23);
    group_popagate_generate f43(a9,b9,a11,b11,a24,b24);
    group_popagate_generate f44(a10,b10,a12,b12,a25,b25);
    group_popagate_generate f45(a11,b11,a13,b13,a26,b26);
    group_popagate_generate f46(a12,b12,a14,b14,a27,b27);
    group_popagate_generate f47(a13,b13,a15,b15,a28,b28);
    
    // stage 3
    group_generate f48(iCarry,a16,b16,c3);
    group_generate f49(C,a17,b17,c4);
    group_generate f50(c1,a18,b18,c5);
    group_generate f51(c2,a19,b19,c6);
    
    group_popagate_generate f52(a16,b16,a20,b20,a29,b29);
    group_popagate_generate f53(a17,b17,a21,b21,a30,b30);
    group_popagate_generate f54(a18,b18,a22,b22,a31,b31);
    group_popagate_generate f55(a19,b19,a23,b23,a32,b32);
    group_popagate_generate f56(a20,b20,a24,b24,a33,b33);
    group_popagate_generate f57(a21,b21,a25,b25,a34,b34);
    group_popagate_generate f58(a22,b22,a26,b26,a35,b35);
    group_popagate_generate f59(a23,b23,a27,b27,a36,b36);
    group_popagate_generate f60(a24,b24,a28,b28,a37,b37);
    
    // satge 4
    group_generate f61(iCarry,a29,b29,c7);
    group_generate f62(C,a30,b30,c8);
    group_generate f63(c1,a31,b31,c9);
    group_generate f64(c2,a32,b32,c10);
    group_generate f65(c3,a33,b33,c11);
    group_generate f66(c4,a34,b34,c12);
    group_generate f67(c5,a35,b35,c13);
    group_generate f68(c6,a36,b36,c14);
    
    group_popagate_generate f69(a29,b29,a37,b37,a38,b38);
    
    // final processing
    post_processing f70(iCarry,wP[0],oSum[0]);
    post_processing f71(C,wP[1],oSum[1]);
    post_processing f72(c1,wP[2],oSum[2]);
    post_processing f73(c2,wP[3],oSum[3]);
    post_processing f74(c3,wP[4],oSum[4]);
    post_processing f75(c4,wP[5],oSum[5]);
    post_processing f76(c5,wP[6],oSum[6]);
    post_processing f77(c6,wP[7],oSum[7]);
    post_processing f78(c7,wP[8],oSum[8]);
    post_processing f79(c8,wP[9],oSum[9]);
    post_processing f82(c9,wP[10],oSum[10]);
    post_processing f83(c10,wP[11],oSum[11]);
    post_processing f84(c11,wP[12],oSum[12]);
    post_processing f85(c12,wP[13],oSum[13]);
    post_processing f86(c13,wP[14],oSum[14]);
    post_processing f87(c14,wP[15],oSum[15]);
    
    group_generate f81(iCarry,a38,b38,oCarry);
endmodule

module pre_processing ( // Bit propagate and generate
    input   wire iA, iB, 
    output  wire oP, oG
    );
    assign oP = iA ^ iB;
    assign oG = iA & iB;
endmodule

module group_popagate_generate ( // Group popagate and generate
    input   wire iP0, iG0, iP1, iG1,
    output  wire oP2, oG2
    );
    assign oG2 = iG1 | (iG0 & iP1);
    assign oP2 = iP1 & iP0;
endmodule

module group_generate ( // Group generate
    input   wire iG0, iP1, iG1,
    output  wire oG2
    );
    assign oG2 = iG1 | (iG0 & iP1);
endmodule

module post_processing (
    input   wire iCarry, iP,
    output  wire oSum
    );
    assign oSum = iCarry ^ iP;
endmodule
