library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;

--! @brief Debounce - entprellen von Schaltern etc.
--! @details siehe Beschreibung zur Datei
entity Debounce is
    Port ( clk       : in   STD_LOGIC; --! Taktsignal
           keyin     : in   STD_LOGIC_VECTOR(3 downto 0); --! prellende Eingaenge
           keyout    : out  STD_LOGIC_VECTOR(3 downto 0)); --! entprellte Ausgaenge
end Debounce;

architecture Behavioral of Debounce is

constant width : natural := 4;
constant delay : natural := 1000000;
signal keydeb : STD_LOGIC_VECTOR(width-1 downto 0) := (others=>'0');
signal debcnt : integer range 0 to delay := 0;
signal keyin_buf: std_logic_vector (3 downto 0);

begin
   process begin
      wait until rising_edge(clk);
	  keyin_buf <= keyin;
      if (keyin_buf=keydeb) then debcnt <= 0;
      else                   
        debcnt <= debcnt+1;
      end if;
      if (debcnt=delay) then 
        keydeb <= keyin_buf; 
      end if;
   end process;
   keyout <= keydeb;

end Behavioral;
