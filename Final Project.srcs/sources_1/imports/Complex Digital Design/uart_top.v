`timescale 1ns / 1ps

module uart_top #(
    parameter   OPERAND_WIDTH = 512,
    parameter   OPERAND_WIDTH_MUL = 256,
    parameter   ADDER_WIDTH   = 128,
    parameter   NBYTES        = OPERAND_WIDTH / 8,    
    parameter   NBYTES_MUL    = OPERAND_WIDTH_MUL / 8,
    parameter   CLK_FREQ      = 125_000_000,
    parameter   BAUD_RATE     = 115_200
    )  
    (
    input   wire   iClk, iRst,
    input   wire   iRx,
    output  wire   oTx
    );
  
  // Buffer to exchange data between Pynq-Z2 and laptop
  reg [NBYTES*8-1:0] rA;
  reg [NBYTES*8-1:0] rB;
  
  // State definition  
  localparam s_IDLE         = 4'b0000;
  localparam s_COM          = 4'b0001;
  localparam s_RX           = 4'b0010;
  localparam s_WAIT_RX      = 4'b0011;
  localparam s_ADD          = 4'b0100;
  localparam s_MUL          = 4'b0101;
  localparam s_TX           = 4'b0110;
  localparam s_WAIT_TX      = 4'b0111;
  localparam s_RX_MUL       = 4'b1000;
  localparam s_WAIT_RX_MUL  = 4'b1001;
  localparam s_TX_MUL       = 4'b1010;
  localparam s_WAIT_TX_MUL  = 4'b1011;
   
  // Declare all variables needed for the finite state machine 
  // -> the FSM state
  reg [3:0]   rFSM;  
     
  // Connection to UART RX (inputs = registers, outputs = wires);
  wire [7:0]  wRxByte;
  wire        wRxDone;
  
  uart_rx #(  .CLK_FREQ(CLK_FREQ), .BAUD_RATE(BAUD_RATE) )
  UART_RX_INST
    (.iClk(iClk),
     .iRst(iRst),
     .iRxSerial(iRx),
     .oRxByte(wRxByte),
     .oRxDone(wRxDone)
     );
     
  // Connection to MP_ADDER
  wire [NBYTES*8:0] wRes;
  wire              wMpAdderDone;
  reg               rStart, rAddSub;
  
  mp_adder #( .OPERAND_WIDTH(OPERAND_WIDTH), .ADDER_WIDTH(ADDER_WIDTH) )
  MP_ADDER_INST  
    (
    .iClk(iClk),
    .iRst(iRst),
    .iStart(rStart),
    .iAddSub(rAddSub),
    .iOpA(rA),
    .iOpB(rB),
    .oRes(wRes),  
    .oDone(wMpAdderDone)
    );
    
  // Connection to MP_MULTIPLIER
  wire [OPERAND_WIDTH_MUL*2-1:0]    wMulRes;
  wire                              wMpMultiplierDone;
  
  mp_multiplier_256b
  MP_MULTIPLIER_INST  
    (
    .iClk(iClk),
    .iRst(iRst),
    .iStart(rStart),
    .iA(rA[OPERAND_WIDTH_MUL-1:0]),
    .iB(rB[OPERAND_WIDTH_MUL-1:0]),
    .oRes(wMulRes),  
    .oDone(wMpMultiplierDone)
    );
  
  // Connection to UART TX (inputs = registers, outputs = wires)
  reg         rTxStart;
  reg [7:0]   rTxByte;
  
  wire        wTxBusy;
  wire        wTxDone;
      
  uart_tx #(  .CLK_FREQ(CLK_FREQ), .BAUD_RATE(BAUD_RATE) )
  UART_TX_INST
    (.iClk(iClk),
     .iRst(iRst),
     .iTxStart(rTxStart),
     .iTxByte(rTxByte),
     .oTxSerial(oTx),
     .oTxBusy(wTxBusy),
     .oTxDone(wTxDone)
     );
     
  reg [$clog2(NBYTES):0] rCnt;
  reg rRxOpCnt;
  reg [(NBYTES+1)*8-1:0] rRes;
  reg [OPERAND_WIDTH_MUL*2-1:0] rRes_MUL;
  reg [7:0] rCom;
  
  always @(posedge iClk)
  begin
  
  // reset all registers upon reset
  if (iRst == 1) 
    begin
      rFSM <= s_IDLE;
      rTxStart <= 0;
      rCnt <= 0;
      rRxOpCnt <= 0;
      rTxByte <= 0;
      rA <= 0;
      rB <= 0;
      rRes <= 0;
      rRes_MUL <= 0;
      rStart <= 0;
      rAddSub <= 0;
      rCom <= 0;
    end 
  else 
    begin
      case (rFSM)
   
        s_IDLE :
          begin
            rFSM <= s_COM;
          end
        
        s_COM :
          begin
            if (wRxDone)
              begin
                rCom <= wRxByte;
                if (wRxByte == 2)
                    rFSM <= s_RX_MUL;
                else  
                    rFSM <= s_RX;
              end
            else
              rFSM <= s_COM;
          end
           
        s_RX :
          begin
            if (rRxOpCnt == 0) // we store the wRxByte into the lowermost byte of rA/rB
              begin rA [7:0] <= wRxByte; end
            else
              begin rB [7:0] <= wRxByte; end
                  
            if (rCnt == NBYTES)
              begin
                rCnt <= 0;
                if (rRxOpCnt == 0)
                  begin
                    rRxOpCnt <= 1;
                    rFSM <= s_RX;
                  end
                else
                  begin
                    if (rCom == 1) rAddSub <= 1;
                    rFSM <= s_ADD;                   
                    rRxOpCnt <= 0;
                    rStart <= 1;
                  end
              end
            else if (rCnt < NBYTES)
              begin rFSM <= s_WAIT_RX; end
          end
          
        s_WAIT_RX :
          begin
            if (wRxDone)
              begin
                rFSM <= s_RX;
                rCnt <= rCnt + 1;
                if (rRxOpCnt == 0)
                  begin rA <= { rA[NBYTES*8-9:0] , 8'b0000_0000 }; end     // we shift from right to left
                else
                  begin rB <= { rB[NBYTES*8-9:0] , 8'b0000_0000 }; end     // we shift from right to left
              end
            else
              rFSM <= s_WAIT_RX;
          end
        
        s_RX_MUL :
          begin
            if (rRxOpCnt == 0) // we store the wRxByte into the lowermost byte of rA/rB
              begin rA [7:0] <= wRxByte; end
            else
              begin rB [7:0] <= wRxByte; end
                  
            if (rCnt == NBYTES_MUL)
              begin
                rCnt <= 0;
                if (rRxOpCnt == 0)
                  begin
                    rRxOpCnt <= 1;
                    rFSM <= s_RX_MUL;
                  end
                else
                  begin
                    rFSM <= s_MUL;                  
                    rRxOpCnt <= 0;
                    rStart <= 1;
                  end
              end
            else if (rCnt < NBYTES_MUL)
              begin rFSM <= s_WAIT_RX_MUL; end
          end
          
        s_WAIT_RX_MUL :
          begin
            if (wRxDone)
              begin
                rFSM <= s_RX_MUL;
                rCnt <= rCnt + 1;
                if (rRxOpCnt == 0)
                  begin rA <= { rA[NBYTES_MUL*8-9:0] , 8'b0000_0000 }; end     // we shift from right to left
                else
                  begin rB <= { rB[NBYTES_MUL*8-9:0] , 8'b0000_0000 }; end     // we shift from right to left
              end
            else
              rFSM <= s_WAIT_RX_MUL;
          end
          
        s_ADD:
          begin
            if (wMpAdderDone)
              begin 
                rFSM <= s_TX;
                if (rCom == 0) 
                    rRes <= {7'b0, wRes};
                else
                    rRes <= {8'b0, wRes[NBYTES*8-1:0]};
                rStart <= 0;
              end
            else
              begin rFSM <= s_ADD; end
          end
          
        s_MUL:
          begin
            if (wMpMultiplierDone)
              begin 
                rFSM <= s_TX_MUL;
                rRes_MUL <= wMulRes;
              end
            else
              begin 
                rFSM <= s_MUL;
                rStart <= 0; 
              end
          end
             
        s_TX :
          begin
            if ( (rCnt < (NBYTES+1)) && (wTxBusy == 0) ) 
              begin
                rFSM <= s_WAIT_TX;
                rTxStart <= 1; 
                rTxByte <= rRes[(NBYTES+1)*8-1:(NBYTES+1)*8-8];            // we send the uppermost byte
                rRes <= {rRes[(NBYTES+1)*8-9:0], 8'b0000_0000};    // we shift from right to left
                rCnt <= rCnt + 1;
              end 
            else 
              begin
                rFSM <= s_IDLE;
                rTxStart <= 0;
                rTxByte <= 0;
                rRes <= 0;
                rCnt <= 0;
                rAddSub <= 0;
              end
            end
            
            s_WAIT_TX :
              begin
                if (wTxDone) begin
                  rFSM <= s_TX;
                end else begin
                  rFSM <= s_WAIT_TX;
                  rTxStart <= 0;                   
                end
              end
              
            s_TX_MUL :
          begin
            if ( (rCnt < NBYTES_MUL*2) && (wTxBusy == 0) ) 
              begin
                rFSM <= s_WAIT_TX_MUL;
                rTxStart <= 1; 
                rTxByte <= rRes_MUL[(NBYTES_MUL*2)*8-1:(NBYTES_MUL*2)*8-8];            // we send the uppermost byte
                rRes_MUL <= {rRes_MUL[(NBYTES_MUL*2)*8-9:0], 8'b0000_0000};    // we shift from right to left
                rCnt <= rCnt + 1;
              end 
            else 
              begin
                rFSM <= s_IDLE;
                rTxStart <= 0;
                rTxByte <= 0;
                rRes_MUL <= 0;
                rCnt <= 0;
                rAddSub <= 0;
              end
            end
            
            s_WAIT_TX_MUL :
              begin
                if (wTxDone) begin
                  rFSM <= s_TX_MUL;
                end else begin
                  rFSM <= s_WAIT_TX_MUL;
                  rTxStart <= 0;                   
                end
              end 

            default :
              rFSM <= s_IDLE;
             
          endcase
      end
    end       
    
endmodule