`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/04/23 23:50:29
// Design Name: 
// Module Name: mp_multiplier
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


module mp_multiplier_256b #(
    parameter   OPERAND_WIDTH = 256,
    parameter   HALF_OPERAND_WIDTH = OPERAND_WIDTH/2,
    parameter   SUBADDER_WIDTH = 64
    )
    (
    input   wire                        iClk, iRst,
    input   wire                        iStart,
    input   wire [OPERAND_WIDTH-1:0]    iA, iB, 
    output  wire [OPERAND_WIDTH*2-1:0]  oRes,
    output  wire                        oDone
    );
    
    reg [OPERAND_WIDTH*2-1:0]       rRes;
    reg                             rDone, rMultiplierStart;
    reg [HALF_OPERAND_WIDTH-1:0]    iAL, iAH, iBL, iBH;
    
    wire [OPERAND_WIDTH-1:0]        wMultiplierRes;
    reg [HALF_OPERAND_WIDTH-1:0]    rMultiplierA, rMultiplierB;  
    wire                            wMultiplierDone;             
    mp_multiplier_128b mp_multiplier_128b_inst (
        .iClk( iClk ),
        .iRst( iRst ),
        .iStart( rMultiplierStart ),
        .iA( rMultiplierA ),
        .iB( rMultiplierB ),
        .oRes( wMultiplierRes ),
        .oDone( wMultiplierDone )
    );
    
    reg                         rAddSub, rAdderStart;
    reg  [OPERAND_WIDTH-1:0]    rA0, rB0;
    wire [OPERAND_WIDTH:0]      wAdderRes0;
    wire                        wAdderDone0;
    mp_adder_free #( .OPERAND_WIDTH(OPERAND_WIDTH), .ADDER_WIDTH(SUBADDER_WIDTH) )
    mp_adder_inst1  
    (
        .iClk( iClk ),
        .iRst( iRst ),
        .iStart( rAdderStart ),
        .iAddSub( rAddSub ),
        .iOpA( rA0 ),
        .iOpB( rB0 ),
        .oRes( wAdderRes0 ),  
        .oDone( wAdderDone0 )
    );
    
    reg  [OPERAND_WIDTH+HALF_OPERAND_WIDTH-1:0]     rA1, rB1;
    wire [OPERAND_WIDTH+HALF_OPERAND_WIDTH:0]       wAdderRes1;
    wire                                            wAdderDone1;  
    mp_adder_free #( .OPERAND_WIDTH(OPERAND_WIDTH+HALF_OPERAND_WIDTH), .ADDER_WIDTH(SUBADDER_WIDTH) )
    mp_adder_inst2  
    (
        .iClk( iClk ),
        .iRst( iRst ),
        .iStart( rAdderStart ),
        .iAddSub( rAddSub ),
        .iOpA( rA1 ),
        .iOpB( rB1 ),
        .oRes( wAdderRes1 ),  
        .oDone( wAdderDone1 )
    );
     
    localparam s_IDLE         = 3'b000;
    localparam s_STORE_OPS    = 3'b001;
    localparam s_MUL          = 3'b010;
    localparam s_WAIT_MUL     = 3'b011;
    localparam s_ADD1         = 3'b100;
    localparam s_ADD2         = 3'b101;
    localparam s_ADD3         = 3'b110;
    localparam s_DONE         = 3'b111;
    
    reg [3:0] rFSM;
    reg [2:0] rMulCnt;
    
    always @(posedge iClk)
    begin
  
    if (iRst == 1) 
    begin
        rFSM <= s_IDLE;
        rMulCnt <= 0;
        iAL <= 0; iAH <= 0; iBL <= 0; iBH <= 0;
        rMultiplierA <= 0; rMultiplierB <= 0;
        rA0 <= 0; rB0 <= 0; rA1 <= 0; rB1 <= 0;
        rRes <= 0; rMultiplierStart <= 0; 
        rAdderStart <= 0; rAddSub <= 0;
    end 
    else 
    begin
        case (rFSM)
   
        s_IDLE :
        begin
            if (iStart==1)
                rFSM <= s_STORE_OPS;
        end
        
        s_STORE_OPS :
        begin
            iAL <= iA[HALF_OPERAND_WIDTH-1:0];
            iAH <= iA[OPERAND_WIDTH-1:HALF_OPERAND_WIDTH];
            iBL <= iB[HALF_OPERAND_WIDTH-1:0];
            iBH <= iB[OPERAND_WIDTH-1:HALF_OPERAND_WIDTH];
            rFSM <= s_MUL;
        end
        
        s_MUL :
        begin
            case (rMulCnt)
            0 :
            begin
                rMultiplierA <= iAL;
                rMultiplierB <= iBL;
                rFSM <= s_WAIT_MUL;
                rMultiplierStart <= 1;
            end
            1 :
            begin
                rMultiplierA <= iAL;
                rMultiplierB <= iBH;
                rFSM <= s_WAIT_MUL;
                rMultiplierStart <= 1;
            end
            2 :
            begin
                rMultiplierA <= iAH;
                rMultiplierB <= iBL;
                rFSM <= s_WAIT_MUL;
                rMultiplierStart <= 1;
            end
            3 :
            begin
                rMultiplierA <= iAH;
                rMultiplierB <= iBH;
                rFSM <= s_WAIT_MUL;
                rMultiplierStart <= 1;
            end
            4 :
            begin
                rFSM <= s_ADD1;
                rMulCnt <= 0;
                rAdderStart <= 1;
            end
            default:
                rFSM <= s_WAIT_MUL;
            endcase
        end
        
        s_WAIT_MUL :
        begin     
            if (wMultiplierDone)      
            begin  
                rFSM <= s_MUL;
                case (rMulCnt)
                0 : 
                begin
                    rA0 <= { {HALF_OPERAND_WIDTH{1'b0}} , wMultiplierRes[OPERAND_WIDTH-1:HALF_OPERAND_WIDTH] };
                    rRes <= {rRes[OPERAND_WIDTH*2-1:HALF_OPERAND_WIDTH], wMultiplierRes[HALF_OPERAND_WIDTH-1:0]};
                end
                1 : 
                    rB0 <= wMultiplierRes[OPERAND_WIDTH-1:0];
                2 : 
                    rA1 <= { {HALF_OPERAND_WIDTH{1'b0}}, wMultiplierRes[OPERAND_WIDTH-1:0] };    
                3 : 
                    rB1 <= { wMultiplierRes[OPERAND_WIDTH-1:0], {HALF_OPERAND_WIDTH{1'b0}} };
                default : 
                    rRes <= 0;
                endcase
                rMulCnt <= rMulCnt + 1;
            end
            else
                rMultiplierStart <= 0;
        end
        
        s_ADD1 :
        begin
            if (wAdderDone0)
            begin
                rFSM <= s_ADD2;
                rA1 <= { {HALF_OPERAND_WIDTH{1'b0}}, wAdderRes0[OPERAND_WIDTH-1:0]};
            end
            else
                rAdderStart <= 0;
        end
        
        s_ADD2 :
        begin
            if (wAdderDone1)
            begin
                rFSM <= s_ADD3;
                rB1 <= wAdderRes1[OPERAND_WIDTH+HALF_OPERAND_WIDTH-1:0];
                rAdderStart <= 1;
            end          
        end
        
        s_ADD3 :
        begin
            if (wAdderDone1)
            begin
                rFSM <= s_DONE;
                rRes <= {wAdderRes1, rRes[HALF_OPERAND_WIDTH-1:0]};
            end       
            else
                rAdderStart <= 0;
        end

        default :
            rFSM <= s_IDLE;
             
        endcase
    end
    
    end
    
    assign oRes = (rFSM == s_DONE) ? rRes : 0;
    assign oDone = (rFSM == s_DONE) ? 1'b1 : 1'b0;
    
endmodule

module mp_multiplier_128b #(
    parameter   OPERAND_WIDTH = 128,
    parameter   HALF_OPERAND_WIDTH = OPERAND_WIDTH/2,
    parameter   SUBADDER_WIDTH = 32
    )
    (
    input   wire                        iClk, iRst,
    input   wire                        iStart,
    input   wire [OPERAND_WIDTH-1:0]    iA, iB, 
    output  wire [OPERAND_WIDTH*2-1:0]  oRes,
    output  wire                        oDone
    );
    
    reg [OPERAND_WIDTH*2-1:0]       rRes;
    reg                             rDone, rMultiplierStart;
    reg [HALF_OPERAND_WIDTH-1:0]    iAL, iAH, iBL, iBH;
    
    wire [OPERAND_WIDTH-1:0]        wMultiplierRes;
    reg [HALF_OPERAND_WIDTH-1:0]    rMultiplierA, rMultiplierB;  
    wire                            wMultiplierDone;             
    mp_multiplier_64b mp_multiplier_64b_inst (
        .iClk( iClk ),
        .iRst( iRst ),
        .iStart( rMultiplierStart ),
        .iA( rMultiplierA ),
        .iB( rMultiplierB ),
        .oRes( wMultiplierRes ),
        .oDone( wMultiplierDone )
    );
    
    reg                         rAddSub, rAdderStart;
    reg  [OPERAND_WIDTH-1:0]    rA0, rB0;
    wire [OPERAND_WIDTH:0]      wAdderRes0;
    wire                        wAdderDone0;
    mp_adder_free #( .OPERAND_WIDTH(OPERAND_WIDTH), .ADDER_WIDTH(SUBADDER_WIDTH) )
    mp_adder_inst1  
    (
        .iClk( iClk ),
        .iRst( iRst ),
        .iStart( rAdderStart ),
        .iAddSub( rAddSub ),
        .iOpA( rA0 ),
        .iOpB( rB0 ),
        .oRes( wAdderRes0 ),  
        .oDone( wAdderDone0 )
    );
    
    reg  [OPERAND_WIDTH+HALF_OPERAND_WIDTH-1:0]     rA1, rB1;
    wire [OPERAND_WIDTH+HALF_OPERAND_WIDTH:0]       wAdderRes1;
    wire                                            wAdderDone1;  
    mp_adder_free #( .OPERAND_WIDTH(OPERAND_WIDTH+HALF_OPERAND_WIDTH), .ADDER_WIDTH(SUBADDER_WIDTH) )
    mp_adder_inst2  
    (
        .iClk( iClk ),
        .iRst( iRst ),
        .iStart( rAdderStart ),
        .iAddSub( rAddSub ),
        .iOpA( rA1 ),
        .iOpB( rB1 ),
        .oRes( wAdderRes1 ),  
        .oDone( wAdderDone1 )
    );
     
    localparam s_IDLE         = 3'b000;
    localparam s_STORE_OPS    = 3'b001;
    localparam s_MUL          = 3'b010;
    localparam s_WAIT_MUL     = 3'b011;
    localparam s_ADD1         = 3'b100;
    localparam s_ADD2         = 3'b101;
    localparam s_ADD3         = 3'b110;
    localparam s_DONE         = 3'b111;
    
    reg [3:0] rFSM;
    reg [2:0] rMulCnt;
    
    always @(posedge iClk)
    begin
  
    if (iRst == 1) 
    begin
        rFSM <= s_IDLE;
        rMulCnt <= 0;
        iAL <= 0; iAH <= 0; iBL <= 0; iBH <= 0;
        rMultiplierA <= 0; rMultiplierB <= 0;
        rA0 <= 0; rB0 <= 0; rA1 <= 0; rB1 <= 0;
        rRes <= 0; rMultiplierStart <= 0; 
        rAdderStart <= 0; rAddSub <= 0;
    end 
    else 
    begin
        case (rFSM)
   
        s_IDLE :
        begin
            if (iStart==1)
                rFSM <= s_STORE_OPS;
        end
        
        s_STORE_OPS :
        begin
            iAL <= iA[HALF_OPERAND_WIDTH-1:0];
            iAH <= iA[OPERAND_WIDTH-1:HALF_OPERAND_WIDTH];
            iBL <= iB[HALF_OPERAND_WIDTH-1:0];
            iBH <= iB[OPERAND_WIDTH-1:HALF_OPERAND_WIDTH];
            rFSM <= s_MUL;
        end
        
        s_MUL :
        begin
            case (rMulCnt)
            0 :
            begin
                rMultiplierA <= iAL;
                rMultiplierB <= iBL;
                rFSM <= s_WAIT_MUL;
                rMultiplierStart <= 1;
            end
            1 :
            begin
                rMultiplierA <= iAL;
                rMultiplierB <= iBH;
                rFSM <= s_WAIT_MUL;
                rMultiplierStart <= 1;
            end
            2 :
            begin
                rMultiplierA <= iAH;
                rMultiplierB <= iBL;
                rFSM <= s_WAIT_MUL;
                rMultiplierStart <= 1;
            end
            3 :
            begin
                rMultiplierA <= iAH;
                rMultiplierB <= iBH;
                rFSM <= s_WAIT_MUL;
                rMultiplierStart <= 1;
            end
            4 :
            begin
                rFSM <= s_ADD1;
                rMulCnt <= 0;
                rAdderStart <= 1;
            end
            default:
                rFSM <= s_WAIT_MUL;
            endcase
        end
        
        s_WAIT_MUL :
        begin     
            if (wMultiplierDone)      
            begin  
                rFSM <= s_MUL;
                case (rMulCnt)
                0 : 
                begin
                    rA0 <= { {HALF_OPERAND_WIDTH{1'b0}} , wMultiplierRes[OPERAND_WIDTH-1:HALF_OPERAND_WIDTH] };
                    rRes <= {rRes[OPERAND_WIDTH*2-1:HALF_OPERAND_WIDTH], wMultiplierRes[HALF_OPERAND_WIDTH-1:0]};
                end
                1 : 
                    rB0 <= wMultiplierRes[OPERAND_WIDTH-1:0];
                2 : 
                    rA1 <= { {HALF_OPERAND_WIDTH{1'b0}}, wMultiplierRes[OPERAND_WIDTH-1:0] };    
                3 : 
                    rB1 <= { wMultiplierRes[OPERAND_WIDTH-1:0], {HALF_OPERAND_WIDTH{1'b0}} };
                default : 
                    rRes <= 0;
                endcase
                rMulCnt <= rMulCnt + 1;
            end
            else
                rMultiplierStart <= 0;
        end
        
        s_ADD1 :
        begin
            if (wAdderDone0)
            begin
                rFSM <= s_ADD2;
                rA1 <= { {HALF_OPERAND_WIDTH{1'b0}}, wAdderRes0[OPERAND_WIDTH-1:0]};
            end
            else
                rAdderStart <= 0;
        end
        
        s_ADD2 :
        begin
            if (wAdderDone1)
            begin
                rFSM <= s_ADD3;
                rB1 <= wAdderRes1[OPERAND_WIDTH+HALF_OPERAND_WIDTH-1:0];
                rAdderStart <= 1;
            end          
        end
        
        s_ADD3 :
        begin
            if (wAdderDone1)
            begin
                rFSM <= s_DONE;
                rRes <= {wAdderRes1, rRes[HALF_OPERAND_WIDTH-1:0]};
            end       
            else
                rAdderStart <= 0;
        end

        default :
            rFSM <= s_IDLE;
             
        endcase
    end
    
    end
    
    assign oRes = (rFSM == s_DONE) ? rRes : 0;
    assign oDone = (rFSM == s_DONE) ? 1'b1 : 1'b0;
    
endmodule

module mp_multiplier_64b #(
    parameter   OPERAND_WIDTH = 64,
    parameter   HALF_OPERAND_WIDTH = OPERAND_WIDTH/2,
    parameter   SUBADDER_WIDTH = 16
    )
    (
    input   wire                        iClk, iRst,
    input   wire                        iStart,
    input   wire [OPERAND_WIDTH-1:0]    iA, iB, 
    output  wire [OPERAND_WIDTH*2-1:0]  oRes,
    output  wire                        oDone
    );
    
    reg [OPERAND_WIDTH*2-1:0]       rRes;
    reg                             rDone, rMultiplierStart;
    reg [HALF_OPERAND_WIDTH-1:0]    iAL, iAH, iBL, iBH;
    
    wire [OPERAND_WIDTH-1:0]        wMultiplierRes;
    reg [HALF_OPERAND_WIDTH-1:0]    rMultiplierA, rMultiplierB;  
    wire                            wMultiplierDone;             
    mp_multiplier_32b mp_multiplier_32b_inst (
        .iClk( iClk ),
        .iRst( iRst ),
        .iStart( rMultiplierStart ),
        .iA( rMultiplierA ),
        .iB( rMultiplierB ),
        .oRes( wMultiplierRes ),
        .oDone( wMultiplierDone )
    );
    
    reg                         rAddSub, rAdderStart;
    reg  [OPERAND_WIDTH-1:0]    rA0, rB0;
    wire [OPERAND_WIDTH:0]      wAdderRes0;
    wire                        wAdderDone0;
    mp_adder_free #( .OPERAND_WIDTH(OPERAND_WIDTH), .ADDER_WIDTH(SUBADDER_WIDTH) )
    mp_adder_inst1  
    (
        .iClk( iClk ),
        .iRst( iRst ),
        .iStart( rAdderStart ),
        .iAddSub( rAddSub ),
        .iOpA( rA0 ),
        .iOpB( rB0 ),
        .oRes( wAdderRes0 ),  
        .oDone( wAdderDone0 )
    );
    
    reg  [OPERAND_WIDTH+HALF_OPERAND_WIDTH-1:0]     rA1, rB1;
    wire [OPERAND_WIDTH+HALF_OPERAND_WIDTH:0]       wAdderRes1;
    wire                                            wAdderDone1;  
    mp_adder_free #( .OPERAND_WIDTH(OPERAND_WIDTH+HALF_OPERAND_WIDTH), .ADDER_WIDTH(SUBADDER_WIDTH) )
    mp_adder_inst2  
    (
        .iClk( iClk ),
        .iRst( iRst ),
        .iStart( rAdderStart ),
        .iAddSub( rAddSub ),
        .iOpA( rA1 ),
        .iOpB( rB1 ),
        .oRes( wAdderRes1 ),  
        .oDone( wAdderDone1 )
    );
     
    localparam s_IDLE         = 3'b000;
    localparam s_STORE_OPS    = 3'b001;
    localparam s_MUL          = 3'b010;
    localparam s_WAIT_MUL     = 3'b011;
    localparam s_ADD1         = 3'b100;
    localparam s_ADD2         = 3'b101;
    localparam s_ADD3         = 3'b110;
    localparam s_DONE         = 3'b111;
    
    reg [3:0] rFSM;
    reg [2:0] rMulCnt;
    
    always @(posedge iClk)
    begin
  
    if (iRst == 1) 
    begin
        rFSM <= s_IDLE;
        rMulCnt <= 0;
        iAL <= 0; iAH <= 0; iBL <= 0; iBH <= 0;
        rMultiplierA <= 0; rMultiplierB <= 0;
        rA0 <= 0; rB0 <= 0; rA1 <= 0; rB1 <= 0;
        rRes <= 0; rMultiplierStart <= 0; 
        rAdderStart <= 0; rAddSub <= 0;
    end 
    else 
    begin
        case (rFSM)
   
        s_IDLE :
        begin
            if (iStart==1)
                rFSM <= s_STORE_OPS;
        end
        
        s_STORE_OPS :
        begin
            iAL <= iA[HALF_OPERAND_WIDTH-1:0];
            iAH <= iA[OPERAND_WIDTH-1:HALF_OPERAND_WIDTH];
            iBL <= iB[HALF_OPERAND_WIDTH-1:0];
            iBH <= iB[OPERAND_WIDTH-1:HALF_OPERAND_WIDTH];
            rFSM <= s_MUL;
        end
        
        s_MUL :
        begin
            case (rMulCnt)
            0 :
            begin
                rMultiplierA <= iAL;
                rMultiplierB <= iBL;
                rFSM <= s_WAIT_MUL;
                rMultiplierStart <= 1;
            end
            1 :
            begin
                rMultiplierA <= iAL;
                rMultiplierB <= iBH;
                rFSM <= s_WAIT_MUL;
                rMultiplierStart <= 1;
            end
            2 :
            begin
                rMultiplierA <= iAH;
                rMultiplierB <= iBL;
                rFSM <= s_WAIT_MUL;
                rMultiplierStart <= 1;
            end
            3 :
            begin
                rMultiplierA <= iAH;
                rMultiplierB <= iBH;
                rFSM <= s_WAIT_MUL;
                rMultiplierStart <= 1;
            end
            4 :
            begin
                rFSM <= s_ADD1;
                rMulCnt <= 0;
                rAdderStart <= 1;
            end
            default:
                rFSM <= s_WAIT_MUL;
            endcase
        end
        
        s_WAIT_MUL :
        begin     
            if (wMultiplierDone)      
            begin  
                rFSM <= s_MUL;
                case (rMulCnt)
                0 : 
                begin
                    rA0 <= { {HALF_OPERAND_WIDTH{1'b0}} , wMultiplierRes[OPERAND_WIDTH-1:HALF_OPERAND_WIDTH] };
                    rRes <= {rRes[OPERAND_WIDTH*2-1:HALF_OPERAND_WIDTH], wMultiplierRes[HALF_OPERAND_WIDTH-1:0]};
                end
                1 : 
                    rB0 <= wMultiplierRes[OPERAND_WIDTH-1:0];
                2 : 
                    rA1 <= { {HALF_OPERAND_WIDTH{1'b0}}, wMultiplierRes[OPERAND_WIDTH-1:0] };    
                3 : 
                    rB1 <= { wMultiplierRes[OPERAND_WIDTH-1:0], {HALF_OPERAND_WIDTH{1'b0}} };
                default : 
                    rRes <= 0;
                endcase
                rMulCnt <= rMulCnt + 1;
            end
            else
                rMultiplierStart <= 0;
        end
        
        s_ADD1 :
        begin
            if (wAdderDone0)
            begin
                rFSM <= s_ADD2;
                rA1 <= { {HALF_OPERAND_WIDTH{1'b0}}, wAdderRes0[OPERAND_WIDTH-1:0]};
            end
            else
                rAdderStart <= 0;
        end
        
        s_ADD2 :
        begin
            if (wAdderDone1)
            begin
                rFSM <= s_ADD3;
                rB1 <= wAdderRes1[OPERAND_WIDTH+HALF_OPERAND_WIDTH-1:0];
                rAdderStart <= 1;
            end          
        end
        
        s_ADD3 :
        begin
            if (wAdderDone1)
            begin
                rFSM <= s_DONE;
                rRes <= {wAdderRes1, rRes[HALF_OPERAND_WIDTH-1:0]};
            end       
            else
                rAdderStart <= 0;
        end

        default :
            rFSM <= s_IDLE;
             
        endcase
    end
    
    end
    
    assign oRes = (rFSM == s_DONE) ? rRes : 0;
    assign oDone = (rFSM == s_DONE) ? 1'b1 : 1'b0;
    
endmodule

module mp_multiplier_32b #(
    parameter   OPERAND_WIDTH = 32,
    parameter   HALF_OPERAND_WIDTH = OPERAND_WIDTH/2
    )
    (
    input   wire                        iClk, iRst,
    input   wire                        iStart,
    input   wire [OPERAND_WIDTH-1:0]    iA, iB, 
    output  wire [OPERAND_WIDTH*2-1:0]  oRes,
    output  wire                        oDone
    );
    
    reg [OPERAND_WIDTH*2-1:0]       rRes;
    reg                             rDone, rMultiplierStart;
    reg [HALF_OPERAND_WIDTH-1:0]    iAL, iAH, iBL, iBH;
    
    wire [OPERAND_WIDTH-1:0]        wMultiplierRes;
    reg [HALF_OPERAND_WIDTH-1:0]    rMultiplierA, rMultiplierB;  
    wire                            wMultiplierDone;             
    mp_multiplier_16b mp_multiplier_16b_inst (
        .iClk( iClk ),
        .iRst( iRst ),
        .iStart( rMultiplierStart ),
        .iA( rMultiplierA ),
        .iB( rMultiplierB ),
        .oRes( wMultiplierRes ),
        .oDone( wMultiplierDone )
    );
     
    reg  [OPERAND_WIDTH-1:0]    rA0, rB0;
    wire [OPERAND_WIDTH-1:0]    wAdderRes0;
    wire                        wCarry0;
    carry_select_adder_Nb #( .ADDER_WIDTH(OPERAND_WIDTH) ) 
    carry_select_adder_Nb_inst1 (
        .iA( rA0 ), 
        .iB( rB0 ),
        .iCarry( 1'b0 ),
        .oSum( wAdderRes0 ),
        .oCarry( wCarry0 )
      );
    
    reg  [OPERAND_WIDTH+HALF_OPERAND_WIDTH-1:0]     rA1, rB1;
    wire [OPERAND_WIDTH+HALF_OPERAND_WIDTH-1:0]     wAdderRes1;
    wire                                            wCarry1;
    carry_select_adder_Nb #( .ADDER_WIDTH(OPERAND_WIDTH+HALF_OPERAND_WIDTH) ) 
    carry_select_adder_Nb_inst2 (
        .iA( rA1 ),
        .iB( rB1 ),
        .iCarry( 1'b0 ),
        .oSum( wAdderRes1 ),
        .oCarry( wCarry1 )
      );
     
    localparam s_IDLE         = 3'b000;
    localparam s_STORE_OPS    = 3'b001;
    localparam s_MUL          = 3'b010;
    localparam s_WAIT_MUL     = 3'b011;
    localparam s_ADD1         = 3'b100;
    localparam s_ADD2         = 3'b101;
    localparam s_ADD3         = 3'b110;
    localparam s_DONE         = 3'b111;
    
    reg [3:0] rFSM;
    reg [2:0] rMulCnt;
    
    always @(posedge iClk)
    begin
  
    if (iRst == 1) 
    begin
        rFSM <= s_IDLE;
        rMulCnt <= 0;
        iAL <= 0; iAH <= 0; iBL <= 0; iBH <= 0;
        rMultiplierA <= 0; rMultiplierB <= 0;
        rA0 <= 0; rB0 <= 0; rA1 <= 0; rB1 <= 0;
        rRes <= 0; rMultiplierStart <= 0;
    end 
    else 
    begin
        case (rFSM)
   
        s_IDLE :
        begin
            if (iStart==1)
                rFSM <= s_STORE_OPS;
        end
        
        s_STORE_OPS :
        begin
            iAL <= iA[HALF_OPERAND_WIDTH-1:0];
            iAH <= iA[OPERAND_WIDTH-1:HALF_OPERAND_WIDTH];
            iBL <= iB[HALF_OPERAND_WIDTH-1:0];
            iBH <= iB[OPERAND_WIDTH-1:HALF_OPERAND_WIDTH];
            rFSM <= s_MUL;
        end
        
        s_MUL :
        begin
            case (rMulCnt)
            0 :
            begin
                rMultiplierA <= iAL;
                rMultiplierB <= iBL;
                rFSM <= s_WAIT_MUL;
                rMultiplierStart <= 1;
            end
            1 :
            begin
                rMultiplierA <= iAL;
                rMultiplierB <= iBH;
                rFSM <= s_WAIT_MUL;
                rMultiplierStart <= 1;
            end
            2 :
            begin
                rMultiplierA <= iAH;
                rMultiplierB <= iBL;
                rFSM <= s_WAIT_MUL;
                rMultiplierStart <= 1;
            end
            3 :
            begin
                rMultiplierA <= iAH;
                rMultiplierB <= iBH;
                rFSM <= s_WAIT_MUL;
                rMultiplierStart <= 1;
            end
            4 :
            begin
                rFSM <= s_ADD2;
                rMulCnt <= 0;
            end
            default:
                rFSM <= s_WAIT_MUL;
            endcase
        end
        
        s_WAIT_MUL :
        begin     
            if (wMultiplierDone)      
            begin  
                rFSM <= s_MUL;
                case (rMulCnt)
                0 : 
                begin
                    rA0 <= { {HALF_OPERAND_WIDTH{1'b0}} , wMultiplierRes[OPERAND_WIDTH-1:HALF_OPERAND_WIDTH] };
                    rRes <= {rRes[OPERAND_WIDTH*2-1:HALF_OPERAND_WIDTH], wMultiplierRes[HALF_OPERAND_WIDTH-1:0]};
                end
                1 : 
                    rB0 <= wMultiplierRes[OPERAND_WIDTH-1:0];
                2 : 
                    rA1 <= { {HALF_OPERAND_WIDTH{1'b0}}, wMultiplierRes[OPERAND_WIDTH-1:0] };    
                3 : 
                    rB1 <= { wMultiplierRes[OPERAND_WIDTH-1:0], {HALF_OPERAND_WIDTH{1'b0}} };
                default : 
                    rRes <= 0;
                endcase
                rMulCnt <= rMulCnt + 1;
            end
            else
                rMultiplierStart <= 0;
        end
        
        s_ADD2 :
        begin
            rFSM <= s_ADD3;
            rA1 <= { {HALF_OPERAND_WIDTH{1'b0}}, wAdderRes0[OPERAND_WIDTH-1:0]};
            rB1 <= wAdderRes1[OPERAND_WIDTH+HALF_OPERAND_WIDTH-1:0];
        end
        
        s_ADD3 :
        begin
            rFSM <= s_DONE;
            rRes <= {wAdderRes1, rRes[HALF_OPERAND_WIDTH-1:0]};
        end

        default :
            rFSM <= s_IDLE;
             
        endcase
    end
    
    end
    
    assign oRes = (rFSM == s_DONE) ? rRes : 0;
    assign oDone = (rFSM == s_DONE) ? 1'b1 : 1'b0;
    
endmodule

module mp_multiplier_16b #(
    parameter   OPERAND_WIDTH = 16,
    parameter   HALF_OPERAND_WIDTH = OPERAND_WIDTH/2
    )
    (
    input   wire                        iClk, iRst,
    input   wire                        iStart,
    input   wire [OPERAND_WIDTH-1:0]    iA, iB, 
    output  wire [OPERAND_WIDTH*2-1:0]  oRes,
    output  wire                        oDone
    );
    
    reg [OPERAND_WIDTH*2-1:0]       rRes;
    reg                             rDone, rMultiplierStart;
    reg [HALF_OPERAND_WIDTH-1:0]    iAL, iAH, iBL, iBH;
    
    wire [OPERAND_WIDTH-1:0]        wMultiplierRes;
    reg [HALF_OPERAND_WIDTH-1:0]    rMultiplierA, rMultiplierB;  
    wire                            wMultiplierDone;             
    mp_multiplier_8b mp_multiplier_8b_inst (
        .iClk( iClk ),
        .iRst( iRst ),
        .iStart( rMultiplierStart ),
        .iA( rMultiplierA ),
        .iB( rMultiplierB ),
        .oRes( wMultiplierRes ),
        .oDone( wMultiplierDone )
    );
     
    reg  [OPERAND_WIDTH-1:0]    rA0, rB0;
    wire [OPERAND_WIDTH-1:0]    wAdderRes0;
    wire                        wCarry0;
    carry_select_adder_Nb_look_ahead #( .ADDER_WIDTH(OPERAND_WIDTH) ) 
    carry_select_adder_Nb_look_ahead_inst1 (
        .iA( rA0 ), 
        .iB( rB0 ),
        .iCarry( 1'b0 ),
        .oSum( wAdderRes0 ),
        .oCarry( wCarry0 )
      );
    
    reg  [OPERAND_WIDTH+HALF_OPERAND_WIDTH-1:0]     rA1, rB1;
    wire [OPERAND_WIDTH+HALF_OPERAND_WIDTH-1:0]     wAdderRes1;
    wire                                            wCarry1;
    carry_select_adder_Nb_look_ahead #( .ADDER_WIDTH(OPERAND_WIDTH+HALF_OPERAND_WIDTH) ) 
    carry_select_adder_Nb_look_ahead_inst2 (
        .iA( rA1 ),
        .iB( rB1 ),
        .iCarry( 1'b0 ),
        .oSum( wAdderRes1 ),
        .oCarry( wCarry1 )
      );
     
    localparam s_IDLE         = 3'b000;
    localparam s_STORE_OPS    = 3'b001;
    localparam s_MUL          = 3'b010;
    localparam s_WAIT_MUL     = 3'b011;
    localparam s_ADD1         = 3'b100;
    localparam s_ADD2         = 3'b101;
    localparam s_ADD3         = 3'b110;
    localparam s_DONE         = 3'b111;
    
    reg [3:0] rFSM;
    reg [2:0] rMulCnt;
    
    always @(posedge iClk)
    begin
  
    if (iRst == 1) 
    begin
        rFSM <= s_IDLE;
        rMulCnt <= 0;
        iAL <= 0; iAH <= 0; iBL <= 0; iBH <= 0;
        rMultiplierA <= 0; rMultiplierB <= 0;
        rA0 <= 0; rB0 <= 0; rA1 <= 0; rB1 <= 0;
        rRes <= 0; rMultiplierStart <= 0;
    end 
    else 
    begin
        case (rFSM)
   
        s_IDLE :
        begin
            if (iStart==1)
                rFSM <= s_STORE_OPS;
        end
        
        s_STORE_OPS :
        begin
            iAL <= iA[HALF_OPERAND_WIDTH-1:0];
            iAH <= iA[OPERAND_WIDTH-1:HALF_OPERAND_WIDTH];
            iBL <= iB[HALF_OPERAND_WIDTH-1:0];
            iBH <= iB[OPERAND_WIDTH-1:HALF_OPERAND_WIDTH];
            rFSM <= s_MUL;
        end
        
        s_MUL :
        begin
            case (rMulCnt)
            0 :
            begin
                rMultiplierA <= iAL;
                rMultiplierB <= iBL;
                rFSM <= s_WAIT_MUL;
                rMultiplierStart <= 1;
            end
            1 :
            begin
                rMultiplierA <= iAL;
                rMultiplierB <= iBH;
                rFSM <= s_WAIT_MUL;
                rMultiplierStart <= 1;
            end
            2 :
            begin
                rMultiplierA <= iAH;
                rMultiplierB <= iBL;
                rFSM <= s_WAIT_MUL;
                rMultiplierStart <= 1;
            end
            3 :
            begin
                rMultiplierA <= iAH;
                rMultiplierB <= iBH;
                rFSM <= s_WAIT_MUL;
                rMultiplierStart <= 1;
            end
            4 :
            begin
                rFSM <= s_ADD2;
                rMulCnt <= 0;
            end
            default:
                rFSM <= s_WAIT_MUL;
            endcase
        end
        
        s_WAIT_MUL :
        begin     
            if (wMultiplierDone)      
            begin  
                rFSM <= s_MUL;
                case (rMulCnt)
                0 : 
                begin
                    rA0 <= { {HALF_OPERAND_WIDTH{1'b0}} , wMultiplierRes[OPERAND_WIDTH-1:HALF_OPERAND_WIDTH] };
                    rRes <= {rRes[OPERAND_WIDTH*2-1:HALF_OPERAND_WIDTH], wMultiplierRes[HALF_OPERAND_WIDTH-1:0]};
                end
                1 : 
                    rB0 <= wMultiplierRes[OPERAND_WIDTH-1:0];
                2 : 
                    rA1 <= { {HALF_OPERAND_WIDTH{1'b0}}, wMultiplierRes[OPERAND_WIDTH-1:0] };    
                3 : 
                    rB1 <= { wMultiplierRes[OPERAND_WIDTH-1:0], {HALF_OPERAND_WIDTH{1'b0}} };
                default : 
                    rRes <= 0;
                endcase
                rMulCnt <= rMulCnt + 1;
            end
            else
                rMultiplierStart <= 0;
        end
        
        s_ADD2 :
        begin
            rFSM <= s_ADD3;
            rA1 <= { {HALF_OPERAND_WIDTH{1'b0}}, wAdderRes0[OPERAND_WIDTH-1:0]};
            rB1 <= wAdderRes1[OPERAND_WIDTH+HALF_OPERAND_WIDTH-1:0];
        end
        
        s_ADD3 :
        begin
            rFSM <= s_DONE;
            rRes <= {wAdderRes1, rRes[HALF_OPERAND_WIDTH-1:0]};
        end

        default :
            rFSM <= s_IDLE;
             
        endcase
    end
    
    end
    
    assign oRes = (rFSM == s_DONE) ? rRes : 0;
    assign oDone = (rFSM == s_DONE) ? 1'b1 : 1'b0;
    
endmodule

module mp_multiplier_8b #(
    parameter   OPERAND_WIDTH = 8,
    parameter   HALF_OPERAND_WIDTH = OPERAND_WIDTH/2
    )
    (
    input   wire                        iClk, iRst,
    input   wire                        iStart,
    input   wire [OPERAND_WIDTH-1:0]    iA, iB, 
    output  wire [OPERAND_WIDTH*2-1:0]  oRes,
    output  wire                        oDone
    );
    
    reg [OPERAND_WIDTH*2-1:0]       rRes;
    reg                             rDone;
    reg [HALF_OPERAND_WIDTH-1:0]    iAL, iAH, iBL, iBH;
    
    wire [OPERAND_WIDTH-1:0]        wMultiplierRes;
    reg [HALF_OPERAND_WIDTH-1:0]    rMultiplierA, rMultiplierB;                  
    wallace_tree_multiplier wallace_tree_multiplier_inst (
        .iA( rMultiplierA ),
        .iB( rMultiplierB ),
        .oRes( wMultiplierRes )
    );
     
    reg  [OPERAND_WIDTH-1:0]    rA0, rB0;
    wire [OPERAND_WIDTH-1:0]    wAdderRes0;
    wire                        wCarry0;
    carry_select_adder_Nb_look_ahead #( .ADDER_WIDTH(OPERAND_WIDTH) ) 
    carry_select_adder_Nb_look_ahead_inst1 (
        .iA( rA0 ), 
        .iB( rB0 ),
        .iCarry( 1'b0 ),
        .oSum( wAdderRes0 ),
        .oCarry( wCarry0 )
      );
    
    reg  [OPERAND_WIDTH+HALF_OPERAND_WIDTH-1:0]     rA1, rB1;
    wire [OPERAND_WIDTH+HALF_OPERAND_WIDTH-1:0]     wAdderRes1;
    wire                                            wCarry1;
    carry_select_adder_Nb_look_ahead #( .ADDER_WIDTH(OPERAND_WIDTH+HALF_OPERAND_WIDTH) ) 
    carry_select_adder_Nb_look_ahead_inst2 (
        .iA( rA1 ),
        .iB( rB1 ),
        .iCarry( 1'b0 ),
        .oSum( wAdderRes1 ),
        .oCarry( wCarry1 )
      );
     
    localparam s_IDLE         = 3'b000;
    localparam s_STORE_OPS    = 3'b001;
    localparam s_MUL          = 3'b010;
    localparam s_WAIT_MUL     = 3'b011;
    localparam s_ADD1         = 3'b100;
    localparam s_ADD2         = 3'b101;
    localparam s_ADD3         = 3'b110;
    localparam s_DONE         = 3'b111;
    
    reg [3:0] rFSM;
    reg [2:0] rMulCnt;
    
    always @(posedge iClk)
    begin
  
    if (iRst == 1) 
    begin
        rFSM <= s_IDLE;
        rMulCnt <= 0;
        iAL <= 0; iAH <= 0; iBL <= 0; iBH <= 0;
        rMultiplierA <= 0; rMultiplierB <= 0;
        rA0 <= 0; rB0 <= 0; rA1 <= 0; rB1 <= 0;
        rRes <= 0;
    end 
    else 
    begin
        case (rFSM)
   
        s_IDLE :
        begin
            if (iStart==1)
            begin
                rFSM <= s_STORE_OPS;
                
            end
        end
        
        s_STORE_OPS :
        begin
            iAL <= iA[HALF_OPERAND_WIDTH-1:0];
            iAH <= iA[OPERAND_WIDTH-1:HALF_OPERAND_WIDTH];
            iBL <= iB[HALF_OPERAND_WIDTH-1:0];
            iBH <= iB[OPERAND_WIDTH-1:HALF_OPERAND_WIDTH];
            rFSM <= s_MUL;
        end
        
        s_MUL :
        begin
            case (rMulCnt)
            0 :
            begin
                rMultiplierA <= iAL;
                rMultiplierB <= iBL;
                rFSM <= s_WAIT_MUL;
            end
            1 :
            begin
                rMultiplierA <= iAL;
                rMultiplierB <= iBH;
                rFSM <= s_WAIT_MUL;
            end
            2 :
            begin
                rMultiplierA <= iAH;
                rMultiplierB <= iBL;
                rFSM <= s_WAIT_MUL;
            end
            3 :
            begin
                rMultiplierA <= iAH;
                rMultiplierB <= iBH;
                rFSM <= s_WAIT_MUL;
            end
            4 :
            begin
                rFSM <= s_ADD2;
                rMulCnt <= 0;
            end
            default:
                rFSM <= s_WAIT_MUL;
            endcase
        end
        
        s_WAIT_MUL :
        begin             
            rFSM <= s_MUL;
            case (rMulCnt)
            0 : 
            begin
                rA0 <= { {HALF_OPERAND_WIDTH{1'b0}} , wMultiplierRes[OPERAND_WIDTH-1:HALF_OPERAND_WIDTH] };
                rRes <= {rRes[OPERAND_WIDTH*2-1:HALF_OPERAND_WIDTH], wMultiplierRes[HALF_OPERAND_WIDTH-1:0]};
            end
            1 : 
                rB0 <= wMultiplierRes[OPERAND_WIDTH-1:0];
            2 : 
                rA1 <= { {HALF_OPERAND_WIDTH{1'b0}}, wMultiplierRes[OPERAND_WIDTH-1:0] };    
            3 : 
                rB1 <= { wMultiplierRes[OPERAND_WIDTH-1:0], {HALF_OPERAND_WIDTH{1'b0}} };
            default : 
                rRes <= 0;
            endcase
            rMulCnt <= rMulCnt + 1;
        end
        
        s_ADD2 :
        begin
            rFSM <= s_ADD3;
            rA1 <= { {HALF_OPERAND_WIDTH{1'b0}}, wAdderRes0[OPERAND_WIDTH-1:0]};
            rB1 <= wAdderRes1[OPERAND_WIDTH+HALF_OPERAND_WIDTH-1:0];
        end
        
        s_ADD3 :
        begin
            rFSM <= s_DONE;
            rRes <= {wAdderRes1, rRes[HALF_OPERAND_WIDTH-1:0]};
        end

        default :
            rFSM <= s_IDLE;
             
        endcase
    end
    
    end
    
    assign oRes = (rFSM == s_DONE) ? rRes : 0;
    assign oDone = (rFSM == s_DONE) ? 1'b1 : 1'b0;
    
endmodule

//module mp_multiplier_8b #(
//    parameter   OPERAND_WIDTH = 8,
//    parameter   HALF_OPERAND_WIDTH = OPERAND_WIDTH/2
//    )
//    (
//    input   wire                        iClk, iRst,
//    input   wire                        iStart,
//    input   wire [OPERAND_WIDTH-1:0]    iA, iB, 
//    output  wire [OPERAND_WIDTH*2-1:0]  oRes,
//    output  wire                        oDone
//    );
    
//    reg [OPERAND_WIDTH*2-1:0] rRes;
//    reg rDone;
    
//    wire [OPERAND_WIDTH-1:0] q0, q1, q2, q3;
//    wallace_tree_multiplier wallace_tree_multiplier_inst1(
//        .iA(iA[HALF_OPERAND_WIDTH-1:0]),
//        .iB(iB[HALF_OPERAND_WIDTH-1:0]),
//        .oRes(q0)
//    );
    
//    wallace_tree_multiplier wallace_tree_multiplier_inst2(
//        .iA(iA[HALF_OPERAND_WIDTH-1 : 0]),
//        .iB(iB[OPERAND_WIDTH-1 : HALF_OPERAND_WIDTH]),
//        .oRes(q1)
//    );
    
//    wallace_tree_multiplier wallace_tree_multiplier_inst3(
//        .iA(iA[OPERAND_WIDTH-1 : HALF_OPERAND_WIDTH]),
//        .iB(iB[HALF_OPERAND_WIDTH-1 : 0]),
//        .oRes(q2)
//    );
    
//    wallace_tree_multiplier wallace_tree_multiplier_inst4(
//        .iA(iA[OPERAND_WIDTH-1 : HALF_OPERAND_WIDTH]),
//        .iB(iB[OPERAND_WIDTH-1 : HALF_OPERAND_WIDTH]),
//        .oRes(q3)
//    );
     
//    reg  [OPERAND_WIDTH-1:0]    rA0, rB0;
//    wire [OPERAND_WIDTH-1:0]    q4;
//    wire                        carry0;
//    carry_select_adder_Nb_look_ahead #( .ADDER_WIDTH(OPERAND_WIDTH) ) 
//    carry_select_adder_Nb_look_ahead_inst1 (
//        .iA( rA0 ), 
//        .iB( rB0 ),
//        .iCarry( 1'b0 ),
//        .oSum( q4 ),
//        .oCarry( carry0 )
//      );
    
//    reg  [OPERAND_WIDTH+HALF_OPERAND_WIDTH-1:0]     rA1, rB1;
//    wire [OPERAND_WIDTH+HALF_OPERAND_WIDTH-1:0]     q5;
//    wire                                            carry1;
//    carry_select_adder_Nb_look_ahead #( .ADDER_WIDTH(OPERAND_WIDTH+HALF_OPERAND_WIDTH) ) 
//    carry_select_adder_Nb_look_ahead_inst2 (
//        .iA( rA1 ),
//        .iB( rB1 ),
//        .iCarry( 1'b0 ),
//        .oSum( q5 ),
//        .oCarry( carry1 )
//      );
    
//    reg  [OPERAND_WIDTH+HALF_OPERAND_WIDTH-1:0]     rA2, rB2;
//    wire [OPERAND_WIDTH+HALF_OPERAND_WIDTH-1:0]     q6;
//    wire                                            carry2;
//    carry_select_adder_Nb_look_ahead #( .ADDER_WIDTH(OPERAND_WIDTH+HALF_OPERAND_WIDTH) ) 
//    carry_select_adder_Nb_look_ahead_inst3 (
//        .iA( rA2 ),
//        .iB( rB2 ),
//        .iCarry( 1'b0 ),
//        .oSum( q6 ),
//        .oCarry( carry2 )
//      );
     
//    localparam s_IDLE         = 3'b000;
//    localparam s_MUL          = 3'b001;
//    localparam s_ADD1         = 3'b010;
//    localparam s_ADD2         = 3'b011;
//    localparam s_ADD3         = 3'b100;
//    localparam s_DONE         = 3'b101;
   
//    reg [3:0]   rFSM;
    
//    always @(posedge iClk)
//    begin
  
//    if (iRst == 1) 
//    begin
//        rFSM <= s_IDLE;
//        rA0 <= 0;
//        rB0 <= 0;
//        rA1 <= 0;
//        rB1 <= 0;
//        rA2 <= 0;
//        rB2 <= 0;
//        rRes <= 0;
//    end 
//    else 
//    begin
//        case (rFSM)
   
//        s_IDLE :
//        begin
//            if (iStart==1)
//                rFSM <= s_MUL;
//        end
        
//        s_MUL :
//        begin
//            rFSM <= s_ADD2;
//            rA0 <= { {HALF_OPERAND_WIDTH{1'b0}} , q0[OPERAND_WIDTH-1:HALF_OPERAND_WIDTH] };
//            rB0 <= q1[OPERAND_WIDTH-1:0];
//            rA1 <= { {HALF_OPERAND_WIDTH{1'b0}}, q2[OPERAND_WIDTH-1:0] };
//            rB1 <= { q3[OPERAND_WIDTH-1:0], {HALF_OPERAND_WIDTH{1'b0}} };
//        end
        
//        s_ADD2 :
//        begin
//            rFSM <= s_ADD3;
//            rA2 <= { {HALF_OPERAND_WIDTH{1'b0}}, q4[OPERAND_WIDTH-1:0]};
//            rB2 <= q5[OPERAND_WIDTH+HALF_OPERAND_WIDTH-1:0];
//        end
        
//        s_ADD3 :
//        begin
//            rFSM <= s_DONE;
//            rRes <= {q6, q0[HALF_OPERAND_WIDTH-1:0]};
//        end

//        default :
//            rFSM <= s_IDLE;
             
//        endcase
//    end
    
//    end
    
//    assign oRes = (rFSM == s_DONE) ? rRes : 0;
//    assign oDone = (rFSM == s_DONE) ? 1'b1 : 1'b0;
    
//endmodule