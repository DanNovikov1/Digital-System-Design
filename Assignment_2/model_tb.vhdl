entity STATE_MACHINE_TB is
end STATE_MACHINE_TB;
library IEEE;
use IEEE.std_logic_1164.all;
architecture ARC_STATE_MACHINE_TB of STATE_MACHINE_TB is
component P_GENERATOR
port ( CLK : in std_ulogic;
RESET : in std_ulogic;
TRIG : in std_ulogic;
PULSE : out std_ulogic);
end component;
signal CLK : std_ulogic;
signal RESET : std_ulogic;
signal TRIG : std_ulogic;
signal PULSE : std_ulogic;

begin
U1: P_GENERATOR
port map( CLK, RESET,TRIG,PULSE);
CREATE_CLOCK: process (clk)
begin
if clk <= 'U' then clk <= '0' after 1 ns;
else clk <= not clk after 1 ns;
end if;
end process CREATE_CLOCK;
CREATE_PULSE: process (TRIG)
begin
TRIG <= '0' after 10 ns,
'1' after 15 ns,
'0' after 20 ns;

begin
U1: P_GENERATOR
port map( CLK, RESET,TRIG,PULSE);
CREATE_CLOCK: process (clk)
begin
if clk <= 'U' then clk <= '0' after 1 ns;
else clk <= not clk after 1 ns;
end if;
end process CREATE_CLOCK;
CREATE_PULSE: process (TRIG)
begin
TRIG <= '0' after 10 ns,
'1' after 15 ns,
'0' after 20 ns;
