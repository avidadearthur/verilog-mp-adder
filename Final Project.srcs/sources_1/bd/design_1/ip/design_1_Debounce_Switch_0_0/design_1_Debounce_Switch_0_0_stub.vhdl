-- Copyright 1986-2020 Xilinx, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2020.1.1 (win64) Build 2960000 Wed Aug  5 22:57:20 MDT 2020
-- Date        : Thu Apr 27 18:35:10 2023
-- Host        : DESKTOP-VFM2P2T running 64-bit major release  (build 9200)
-- Command     : write_vhdl -force -mode synth_stub {c:/Users/dell/Desktop/3-2/Complex Digital Design/Final Project/Final
--               Project.srcs/sources_1/bd/design_1/ip/design_1_Debounce_Switch_0_0/design_1_Debounce_Switch_0_0_stub.vhdl}
-- Design      : design_1_Debounce_Switch_0_0
-- Purpose     : Stub declaration of top-level module interface
-- Device      : xc7z020clg400-1
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity design_1_Debounce_Switch_0_0 is
  Port ( 
    i_Clk : in STD_LOGIC;
    i_Switch : in STD_LOGIC;
    o_Switch : out STD_LOGIC
  );

end design_1_Debounce_Switch_0_0;

architecture stub of design_1_Debounce_Switch_0_0 is
attribute syn_black_box : boolean;
attribute black_box_pad_pin : string;
attribute syn_black_box of stub : architecture is true;
attribute black_box_pad_pin of stub : architecture is "i_Clk,i_Switch,o_Switch";
attribute X_CORE_INFO : string;
attribute X_CORE_INFO of stub : architecture is "Debounce_Switch,Vivado 2020.1.1";
begin
end;
