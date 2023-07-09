`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/03/09 10:14:27
// Design Name: 
// Module Name: UART_RX
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

module uart_rx #(
  parameter   CLK_FREQ      = 125_000_000,
  parameter   BAUD_RATE     = 115_200,
  // Example: 125 MHz Clock / 115200 baud UART -> CLKS_PER_BIT = 1085 
  parameter   CLKS_PER_BIT  = CLK_FREQ / BAUD_RATE
)
(
  input wire        iClk, iRst,
  input wire        iRxSerial,
  output wire [7:0] oRxByte, 
  output wire       oRxDone
);

    // State definition  
  localparam sIDLE         = 3'b000;
  localparam sRX_START     = 3'b001;
  localparam sRX_DATA      = 3'b010;
  localparam sRX_STOP      = 3'b011;
  localparam sDONE         = 3'b100;
  
  // Register variables required to drive the FSM
  //---------------------------------------------
  // Remember:  -> 'current' is the register output
  //            -> 'next' is the register input
  
  // -> FSM state
  reg [2:0] rFSM_Current, wFSM_Next; 
 
  // -> counter to keep track of the clock cycles
  reg [$clog2(CLKS_PER_BIT):0]   rCnt_Current, wCnt_Next;
    
  // -> counter to keep track of sent bits
  // (between 0 and 7)
  reg [2:0] rBit_Current, wBit_Next;
  
  // -> the byte we want to send (we store an internal copy)
  reg [7:0] rRxData_Current, wRxData_Next;
  
  // Double-register the input wire to prevent metastability issues
  reg rRx1, rRx2;
  
  // Describe all previous registers
  //------------------------------------------ 
  // Needs to be done with a clocked always block 
  // Don't forget the synchronous reset (default state)
  
  always @(posedge iClk)
  begin
    rRx1 <= iRxSerial;
    rRx2 <= rRx1;
    if (iRst==1)
      begin
        rFSM_Current <= sIDLE;
        rCnt_Current <= 0;
        rBit_Current <= 0;
        rRxData_Current <= 0;
      end
    else
      begin
        rFSM_Current <= wFSM_Next;
        rCnt_Current <= wCnt_Next;
        rBit_Current <= wBit_Next;
        rRxData_Current <= wRxData_Next;
      end
  end
  
  // Next state logic
  //------------------------------------------ 
  // -> this is a COMBINATIONAL module, which specifies the next state 
  //    of the FSM and also the next value of the previous registers
  // -> to AVOID LATCHES, you need to make sure all the next register values
  //    ( rFSM_Next, rCnt_Next, rBit_Next, rTxData_Next)
  //    are defined for every possible condition
  //    iRxSerial:
  //  -> it is '1' by default
  //  -> it is '0' during the start bit
  //  -> it will be wrote to rRxData_Current[0] during the receiving of bits
  //  -> it is '1' during the stop bit
     
  always @(*)
    begin
      
      case (rFSM_Current)
      
        // IDLE STATE:
        // -> we simply wait here until iRxSerial(rRx2) is asserted
        // -> when iRxSerial is asserted, we initialize 0 to
        //    our local register (rTxData_Current)  
        //    and we are ready to start the frame transmission    
        sIDLE :
          begin
            wCnt_Next = 0;
            wBit_Next = 0;
             
            if (rRx2 == 0) // induce 3 cycles delay
              begin
                wFSM_Next = sRX_START;
                wRxData_Next = 0;   // set 0 to rRxData_Current
              end
            else
             begin    
                wFSM_Next = sIDLE;
                wRxData_Next = rRxData_Current;
             end
          end 
           
        // RX_START STATE:
        // -> we stay here for the duration of the start bit,
        //    which takes CLKS_PER_BIT clock cycles
        //    but then we still need to wait for another
        //    CLKS_PER_BIT/2 clock cycles before starting
        //    to sample in the middle of sending
        // -> we use rCnt_Current to keep track of clock cycles 
        sRX_START :
            begin
              wRxData_Next = rRxData_Current;
              wBit_Next = 0;
              
              // There will be 3 cycles delay compared to the real state until now
              // -> the first two are caused by double-registered iRxSerial
              // -> after 2 cyles, rRx2 is registered
              // -> it needs ana extra cycle to read the Rx2 value and make change
              if (rCnt_Current < (CLKS_PER_BIT/2 - 1))
                begin
                  wFSM_Next = sRX_START;
                  wCnt_Next = rCnt_Current + 1;
                end
              else
                begin
                  wFSM_Next = sRX_DATA;
                  wCnt_Next = 0;
                end
            end 
           
           
          // RX_DATA STATE:
          // -> we stay here for the duration of the byte sending,
          //    which takes 8 * CLKS_PER_BIT clock cycles     
          // -> we use rCnt_Current to keep track of clock cycles 
          // -> we use rBit_Current to keep track of number of bits
        
          // -> when rBit_Current increases, we read the data from iRxSerial
          //    and assign it to the MSB rRxData_Current[7],
          //    then we need to shift the contents of the
          //    rRxData_Current register one bit to right after that.
          
          sRX_DATA :
            begin
              
              if (rCnt_Current < (CLKS_PER_BIT - 1) )
                begin
                  wFSM_Next = sRX_DATA;
                  wCnt_Next = rCnt_Current + 1;
                  wRxData_Next = rRxData_Current;
                  wBit_Next = rBit_Current;
                end
              else
                begin
                  wCnt_Next = 0;
                   wRxData_Next = { rRx2, rRxData_Current[7:1] }; // shift rTxData_Current one bit to the right
                  // wRxData_Next = rRxData_Current >> 1; 
                  // wRxData_Next[7] = rRx2;
                  
                  if (rBit_Current != 7)
                    begin
                      wFSM_Next = sRX_DATA;
                      wBit_Next = rBit_Current + 1;
                    end
                  else
                    begin
                      wFSM_Next = sRX_STOP;
                      wBit_Next = 0;
                    end
                end
            end  
            
           
          // RX_STOP STATE:
          // -> we stay here for the duration of the stop bit,
          //    which takes CLKS_PER_BIT clock cycles
          // -> we use rCnt_Current to keep track of clock cycles 
          sRX_STOP :
            begin
              wRxData_Next = rRxData_Current;
              wBit_Next = 0;
               
              if (rCnt_Current < (CLKS_PER_BIT - 1) )
                begin
                  wFSM_Next = sRX_STOP;
                  wCnt_Next = rCnt_Current + 1;
                end
              else
                begin
                  wFSM_Next = sDONE;
                  wCnt_Next = 0;
                end
            end 
           
           
          // DONE STATE:
          // -> we stay here 1 clock cycle, we will use this state
          //    to assert the output oDone 
          sDONE :
            begin
              wRxData_Next = rRxData_Current;
              wBit_Next = 0;
              wCnt_Next = 0;
              wFSM_Next = sIDLE;
            end
           
           
          default :
            begin
              wFSM_Next = sIDLE;
              wCnt_Next = 0;
              wBit_Next = 0;
              wRxData_Next = 0;
            end 
        endcase
    end
    
  // Output oRxByte : easiest is to define it with a combinational
  //  always block
  
  reg[7:0] rRxByte;
  
  always @(*)
  begin
    if (rFSM_Current == sRX_START)
        rRxByte = 8'b0;
    else 
        rRxByte = rRxData_Current;
  end
  
  assign oRxByte = rRxByte;
  
  // Output oRxDone : easiest is to define it with a simple
  // continuous assignment
  //  -> it is '0' by default
  //  -> it is '1' during sDONE
  
  assign oRxDone = (rFSM_Current == sDONE) ? 1 : 0;
    
endmodule
