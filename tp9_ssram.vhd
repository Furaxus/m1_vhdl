--------------------------------------------------------------------------------
-- SSRAM
-- Dr THIEBOLT Francois
--------------------------------------------------------------------------------

------------------------------------------------------------------
-- RAM Statique Synchrone - mode burst -
-- Les donnes sur DBUS changent d'etat juste apres le front
-- 	montant CLK. La memoire n'est pas circulaire, c.a.d que lorsque
--		l'adresse depasse la capacite, DBUS <= Z
-- Elle dispose d'un parametre fixant la latence au chip
-- select, c.a.d que lorsque CS* est actif, il se passe CS_LATENCY
-- cycles avant que l'operation READ ou WRITE se fasse effectivement
-- Une operation READ ou WRITE dure tant que CS est actif.
-- L'adresse de l'operation est echantillonnee sur front descendant
--		de CS*, puis incrementee tacitement apres CS_LATENCY cycles
--		et ce tant que CS* est actif.
------------------------------------------------------------------

-- Definition des librairies
library IEEE;

-- Definition des portee d'utilisation
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

-- Definition de l'entite
entity ssram is

	generic (
		-- taille du bus d'adresse
		ABUS_WIDTH : natural := 4; -- soit 16 mots memoire

		-- taille du bus donnee
		DBUS_WIDTH : natural := 8;
		
		-- chip select latence en nombre de cycles
		CS_LATENCY : natural := 4;
		
		-- delai de propagation entre la nouvelle adresse et la donnee sur la sortie
		I2Q : time := 2 ns );

	port (
		-- signaux de controle
		RW		: in std_logic; -- R/W* (W actif a l'etat bas)
		CS,RST		: in std_logic; -- actifs a l'etat bas
		CLK		: in std_logic;

		-- bus d'adresse et de donnee
		ABUS 		: in std_logic_vector(ABUS_WIDTH-1 downto 0);
		DBUS 		: inout std_logic_vector(DBUS_WIDTH-1 downto 0) );

end ssram;

-- -----------------------------------------------------------------------------
-- Definition de l'architecture de la ssram
-- -----------------------------------------------------------------------------
architecture behavior of ssram is

	-- definition de constantes

	-- definitions de types (index type default is integer)
	type FILE_REG_typ is array (0 to 2**ABUS_WIDTH-1) of std_logic_vector (DBUS_WIDTH-1 downto 0);

	-- definition des ressources internes
	signal REGS : FILE_REG_typ; -- le banc de registres

begin



P_SSRAM : process
	variable overflow : boolean := false;
	variable index : integer range 0 to 2**ABUS_WIDTH-1;
	variable cpt_latency : integer range 0 to CS_LATENCY := 0;
begin
	wait on CLK;
	if (rising_edge(CLK)) then
		if (RST = '0') then
			--mettre la memoire a 0
			for i in 0 to 2**ABUS_WIDTH -1 loop
				REGS(i) <= (others => '0');
			end loop;
		else
			if (CS = '0') then -- cycle en cours
				if (cpt_latency = 0) then
					for i in ABUS'range loop
						report natural'image(ABUS_WIDTH) & " ABUS : " & std_logic'image(ABUS(i));
					end loop;
					index := conv_integer(ABUS);
					report "index : " & integer'image(index);
				end if;
				if (cpt_latency < CS_LATENCY) then -- generation latence
					cpt_latency := cpt_latency + 1;
				else -- debut traitement
					if (RW = '0') then -- ecriture
						if (not overflow) then
							REGS(index) <= DBUS;
						end if;
					else -- lecture
						wait for I2Q;
						if (not overflow) then
							DBUS <= REGS(index);
						else
							DBUS <= (others => 'Z');
						end if;
					end if;
					if (index = 2**ABUS_WIDTH-1) then
						overflow := true;
					else
						index := index + 1;
					end if;
				end if;
				
			else -- pas de cycle en cours
				DBUS <= (others => 'Z');
				cpt_latency := 0;
				overflow := false;
			end if;
		end if;
	end if;

end process P_SSRAM;

--P_SSRAM : process (CLK)
--	variable overflow : boolean := false;
--	variable index : integer range 0 to 2**ABUS_WIDTH-1;
--	variable cpt_latency : integer range 0 to CS_LATENCY := 0;
--begin
--	if (rising_edge(CLK)) then
--		if (RST = '0') then
--			--mettre la memoire a 0
--			for i in 0 to 2**ABUS_WIDTH -1 loop
--				REGS(i) <= (others => '0');
--			end loop;
--		else
--			if (CS = '0') then -- cycle en cours
--				if (cpt_latency = 0) then
--					index := conv_integer(ABUS);
--				end if;
--				if (cpt_latency < CS_LATENCY) then -- generation latence
--					cpt_latency := cpt_latency + 1;
--				else -- debut traitement
--					if (RW = '0') then -- ecriture
--						if (not overflow) then
--							REGS(index) <= DBUS;
--						end if;
--					else -- lecture
--						if (not overflow) then
--							DBUS <= REGS(index);
--						else
--							DBUS <= (others => 'Z');
--						end if;
--					end if;
--					if (index = 2**ABUS_WIDTH-1) then
--						overflow := true;
--					else
--						index := index + 1;
--					end if;
--				end if;
--				
--			else -- pas de cycle en cours
--				DBUS <= (others => 'Z');
--				cpt_latency := 0;
--				overflow := false;
--			end if;
--		end if;
--	end if;
--
--end process P_SSRAM;


end behavior;
