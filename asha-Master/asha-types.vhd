library IEEE;
use IEEE.STD_LOGIC_1164.all;

--! @brief ASHA Typdefinitionen
--! @details Dieses Modul enthaelt die Arraydefinitionen,
--! die zwischen verschiedenen Modulen uebergeben werden,
--! weil diese nicht innerhalb der Module selber 
--! deklariert werden koennen
package AshaTypes is

  type ADCRegisterType is array (0 to 7) of std_logic_vector(11 downto 0);
  type ADCStateType is (clken,startb,single,d2,d1,d0,nbit,b11,b10,b9,b8,b7,b6,b5,b4,b3,b2,b1,b0,endb);
  type ADCLoopStateType is (s_getvalue, s_translate, s_end);

end AshaTypes;

