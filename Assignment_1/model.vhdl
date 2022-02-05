--Odd Parity Generator
--Resource: https://www.csun.edu/edaasic/roosta/VHDL_Examples.pdf
package anu is
constant m: integer :=8;
type input is array (0 to m-1) of bit;
end anu;
library ieee;
use ieee.std_logic_1164.all ;
use Work.anu.all;
entity Parity_Generator1 is
port ( input_stream : in input;
clk : in std_logic ;
parity :out bit );
end Parity_Generator1;
architecture odd of Parity_Generator1 is
begin
P1: process
variable odd : bit ;
begin
wait until clk'event and clk = '1';
odd := '0';
for I in 0 to m-1 loop
odd := odd xor input_stream (I);
end loop;
parity <= odd;
end process;
end odd;
