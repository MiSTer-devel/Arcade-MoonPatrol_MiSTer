library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

library work;
use work.pace_pkg.all;

entity inputmapper is
	generic
	(
    NUM_DIPS    : integer := 8;
		NUM_INPUTS  : integer := 2
	);
	port
	(
    clk       : in std_logic;
    rst_n     : in std_logic;

    jamma		: in from_JAMMA_t;

    -- user outputs
    dips			: in	std_logic_vector(NUM_DIPS-1 downto 0);
    inputs		: out from_MAPPED_INPUTS_t(0 to NUM_INPUTS-1)
	);
end inputmapper;

architecture SYN of inputmapper is

begin

  process (clk, rst_n)
    variable jamma_v	: from_MAPPED_INPUTS_t(0 to NUM_INPUTS-1);
  begin

       -- note: all inputs are active LOW

      if rst_n = '0' then
        for i in 0 to NUM_INPUTS-1 loop
          jamma_v(i).d := (others =>'1');
        end loop;
        
      elsif rising_edge (clk) then

        -- handle JAMMA inputs

        -- 1E
        jamma_v(0).d(0) := jamma.p(1).start;     -- 1P START
        jamma_v(0).d(1) := jamma.p(2).start;     -- 2P START
        jamma_v(0).d(2) := jamma.service;        -- SERVICE
        jamma_v(0).d(3) := jamma.coin(1);        -- COIN (A)

        -- 1D
        jamma_v(1).d(0) := jamma.p(1).right;     -- 1P FAST
        jamma_v(1).d(1) := jamma.p(1).left;      -- 1P SLOW
        -- jamma_v(1).d(2) := jamma.p(1).down;   -- NC
        -- jamma_v(1).d(3) := jamma.p(1).up;     -- NC
        -- jamma_v(1).d(4)                       -- NC
        jamma_v(1).d(5) := jamma.p(1).button(2); -- 1P JUMP
        -- jamma_v(1).d(6)                       -- NC
        jamma_v(1).d(7) := jamma.p(1).button(1); -- 1P FIRE

        -- 1C
        jamma_v(2).d(0) := jamma.p(2).right;     -- 2P FAST
        jamma_v(2).d(1) := jamma.p(2).left;      -- 2P SLOW
        -- jamma_v(2).d(2)                       -- NC
        -- jamma_v(2).d(3)                       -- NC
        jamma_v(2).d(4) := jamma.coin(2);        -- COIN (B)
        jamma_v(2).d(5) := jamma.p(2).button(2); -- 2P JUMP
        -- jamma_v(2).d(6)                       -- ?
        jamma_v(2).d(7) := jamma.p(2).button(1); -- 2P FIRE

      end if; -- rising_edge (clk)

      -- assign outputs
      inputs(0).d <= jamma_v(0).d; -- 1E
      inputs(1).d <= jamma_v(1).d; -- 1D
      inputs(2).d <= jamma_v(2).d; -- 1C
      inputs(3).d <= "11111110";  -- 1C/1C, 10/30/50K, 3 lives
      inputs(4).d <= "11111100";
      -- activate service which is only checked on startup
      --inputs(4).d <= "01111100";
      inputs(NUM_INPUTS-1).d <= (others =>'0');

  end process;

end architecture SYN;


