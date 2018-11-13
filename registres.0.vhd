-------------------------------------------------------------------------------
-- Banc de registres
-- THIEBOLT Francois le 05/04/04
-------------------------------------------------------------------------------

--------------------------------------------------------------
-- Par defaut 32 registres de 32 bits avec lecture double port
--------------------------------------------------------------

-- Definition des librairies
library IEEE;

-- Definition des portee d'utilisation
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

-- Definition de l'entite
entity registres is

	-- definition des parametres generiques
	generic	(
		-- largeur du bus de donnees par defaut
		DBUS_WIDTH	: integer := 32; -- registre de 32 bits par defaut

		-- largeur du bus adr pour acces registre soit 32 (2**5) par defaut
		ABUS_WIDTH	: integer := 5
	);

	-- definition des entrees/sorties
	port 	(
		-- signaux de controle du Banc de registres
		________
		________

		-- bus d'adresse et donnees
		ADR_A, ADR_B, ADR_W : in std_logic_vector (ABUS_WIDTH downto 0);

		-- Ports de sortie
		QA, QB : out is array (0 to ABUS_WIDTH-1) of std_logic_vector (DBUS_WIDTH-1 downto 0)
	);

end registres;


-------------------------------------------------------------------------------
-- REGISTRES architecture in a behavioral style
-------------------------------------------------------------------------------

-- Definition de l'architecture du banc de registres
architecture behavior of registres is

	-- definitions de types (index type default is integer)
	type FILE_REGS is array (0 to (2**3)-1) of std_logic_vector (31 downto 0);

	-- definition des ressources internes
	signal REGS : FILE_REGS; -- le banc de registres

begin

---------------------------------
-- affectation des bus en lecture
-- DOMAINE COMBINATOIRE
	QA <= REGS(conv_integer(ADR_A)) when ADR_A /= conv_std_logic_vector(0, ADR_A'length)
		else (others => '0');
	QB <= REGS(conv_integer(ADR_B)) when ADR_B /= conv_std_logic_vector(0, ADR_B'length)
		else (others => '0');

-----------------
-- Process P_REGS
P_REGS: process(RST, CLK)
begin
	-- test du reset
	if RST='0' then
		REGS <= (others => conv_std_logic_vector(0,DBUS_WIDTH));
		-- ON NE RESET PAS LES SORTIES CAR LES PROCESS AU DESSUS LES MODIFIES !!!!!
		-- LES VALEURS SERONT MAINTENU DE FORCE QUAND LA CONDITION N'EST PAS RESPECTEE
		-- QA <= (others => '0');
		-- QB <= (others => '0');
	-- test front actif d'horloge et si ecriture dans le registre
	elsif (rising_edge(CLK) and W='0' and ADR_W /= ABUS_WIDTH) then
		REGS(conv_integer(ADR_W)) <= D;
	end if;
end process P_REGS;

end behavior;
