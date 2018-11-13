---------------------------------------
-- Fichier de test de Banc de registres
-- THIEBOLT Francois le 20/11/02
---------------------------------------

-- Definition des librairies
library IEEE;

-- Definition des portee d'utilisation
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

-- Definition de l'entite
entity test_registres is
end test_registres;

-- Definition de l'architecture
architecture behavior of test_registres is

-- definition des constantes de test
	constant S_DATA	: positive:=32; -- taille du bus de donnes
	constant S_ADR		: positive:=3; -- taille du bus d'adresse
	constant WFRONT 	: std_logic := '1'; -- front actif pour ecriture
	constant TIMEOUT 	: time := 150 ns; -- timeout de la simulation

-- definition de constantes
constant clkpulse : Time := 5 ns; -- 1/2 periode horloge

-- definition de types

-- definition de ressources internes

-- definition de ressources externes
signal E_CLK							: std_logic;
signal E_RST,E_W 						: std_logic; -- actifs a l'etat bas
signal E_ADR_A,E_ADR_B,E_ADR_W	: std_logic_vector(S_ADR-1 downto 0);
signal E_QA,E_QB,E_D					: std_logic_vector(S_DATA-1 downto 0);

begin

--------------------------
-- definition de l'horloge
P_E_CLK: process
begin
	E_CLK <= '1';
	wait for clkpulse;
	E_CLK <= '0';
	wait for clkpulse;
end process P_E_CLK;

-----------------------------------------
-- definition du timeout de la simulation
P_TIMEOUT: process
begin
	wait for TIMEOUT;
	assert FALSE report "SIMULATION TIMEOUT!!!" severity FAILURE;
end process P_TIMEOUT;

--------------------------------------------------
-- instantiation et mapping du composant registres
regf0 : entity work.registres(behavior)
--					generic map (S_DATA,S_ADR,WFRONT)
					port map (CLK => E_CLK,
								 W => E_W,
								 RST => E_RST,
								 D => E_D,
								 ADR_A => E_ADR_A,
								 ADR_B => E_ADR_B,
								 ADR_W => E_ADR_W,
								 QA => E_QA,
								 QB => E_QB);

-----------------------------
-- debut sequence de test
P_TEST: process
begin

	-- initialisations
	E_RST <= '0';
	E_ADR_A <= (others=>'X');
	E_ADR_B <= (others=>'X');
	E_ADR_W <= (others=>'X');
	E_D <= (others=>'X');
	E_W <= '1';

	-- sequence RESET
	E_RST <= '0';
	wait for clkpulse*3;
	E_RST <= '1';
	wait for clkpulse;

	-- ecriture dans registre2
	wait until (E_CLK=(WFRONT)); wait for clkpulse/2;
	E_ADR_W <= conv_std_logic_vector(2,S_ADR);
	E_D <= to_stdlogicvector(BIT_VECTOR'(X"2222FFFF"));
	E_W <= '0';

	-- ecriture dans registre3
	wait until (E_CLK=(WFRONT)); wait for clkpulse/2;
	E_ADR_W <= conv_std_logic_vector(3,S_ADR);
	E_D <= to_stdlogicvector(BIT_VECTOR'(X"33FF33FF"));
	E_W <= '0';

	-- ecriture dans registre0
	wait until (E_CLK=(WFRONT)); wait for clkpulse/2;
	E_ADR_W <= conv_std_logic_vector(0,S_ADR);
	E_D <= to_stdlogicvector(BIT_VECTOR'(X"FFFF0000"));
	E_W <= '0';

	-- ecriture dans registre4 et
	-- lectures registres 0 et 3 sur respectivement QA et QB
	wait until (E_CLK=(WFRONT)); wait for clkpulse/2;
	E_ADR_W <= conv_std_logic_vector(4,S_ADR);
	E_D <= to_stdlogicvector(BIT_VECTOR'(X"4F4F4F4F"));
	E_W <= '0';
	E_ADR_A <= conv_std_logic_vector(0,S_ADR);
	E_ADR_B <= conv_std_logic_vector(3,S_ADR);

	-- tests
	wait until (E_CLK=(WFRONT)); wait for clkpulse/2;
	E_W <= '1';
	E_ADR_A <= (others => 'X');
	E_ADR_B <= (others => 'X');
	E_ADR_W <= (others => 'X');
	E_D <= (others => 'X');
	assert E_QA = conv_std_logic_vector(0,S_DATA)
		report "Register 0 BAD VALUE"
		severity ERROR;
	assert E_QB = to_stdlogicvector(BIT_VECTOR'(X"33FF33FF"))
		report "Register 3 BAD VALUE"
		severity ERROR;

	-- ecriture dans registre5 et lecture registre 5
	wait until (E_CLK=(WFRONT)); wait for clkpulse/2;
	E_ADR_W <= conv_std_logic_vector(5,S_ADR);
	E_D <= to_stdlogicvector(BIT_VECTOR'(X"F5F5F5F5"));
	E_W <= '0';
	E_ADR_A <= conv_std_logic_vector(5,S_ADR);

	-- tests de la lecture asynchrone sur l'autre front
	wait until (E_CLK=not(WFRONT));
	assert E_QA = to_stdlogicvector(BIT_VECTOR'(X"F5F5F5F5"))
		report "Register 5 BAD VALUE"
		severity WARNING;

	-- NOP
	wait until (E_CLK=(WFRONT)); wait for clkpulse/2;
	E_W <= '1';
	E_ADR_A <= (others => 'X');
	E_ADR_B <= (others => 'X');
	E_ADR_W <= (others => 'X');
	E_D <= (others => 'X');
	-- ADD NEW SEQUENCE HERE

	-- LATEST COMMAND (NE PAS ENLEVER !!!)
	wait until (E_CLK=(WFRONT)); wait for clkpulse/2;
	assert FALSE report "FIN DE SIMULATION" severity FAILURE;

end process P_TEST;

end behavior;
