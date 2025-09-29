----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
-- Filename     UserRdDdr.vhd
-- Title        Top
--
-- Company      Design Gateway Co., Ltd.
-- Project      DDCamp
-- PJ No.       
-- Syntax       VHDL
-- Note         

-- Version      1.00
-- Author       B.Attapon
-- Date         2017/12/20
-- Remark       New Creation
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;

Entity UserRdDdr Is
	Port
	(
		RstB			: in	std_logic;							-- use push button Key0 (active low)
		Clk				: in	std_logic;							-- clock input 100 MHz

		DipSwitch		: in 	std_logic_vector( 1 downto 0 );
		
		-- HDMICtrl I/F
		HDMIReq			: out	std_logic;
		HDMIBusy		: in	std_logic;
		
		-- RdCtrl I/F
		MemInitDone		: in	std_logic;  -- 
		MtDdrRdReq		: out	std_logic;
		MtDdrRdBusy		: in	std_logic;
		MtDdrRdAddr		: out	std_logic_vector( 28 downto 7 );
		
		-- D2URdFf I/F mtddr to user read
		D2URdFfWrEn		: in	std_logic;
		D2URdFfWrData	: in	std_logic_vector( 63 downto 0 );
		D2URdFfWrCnt	: out	std_logic_vector( 15 downto 0 );
		
		-- URd2HFf I/F
		URd2HFfWrEn		: out	std_logic;
		URd2HFfWrData	: out	std_logic_vector( 63 downto 0 );
		URd2HFfWrCnt	: in	std_logic_vector( 15 downto 0 )
	);
End Entity UserRdDdr;

Architecture rtl Of UserRdDdr Is

----------------------------------------------------------------------------------
-- Component declaration
----------------------------------------------------------------------------------
	constant	cnumreq	: integer := 24576;
	--constant	cnumreq	: integer := 24575;

	
----------------------------------------------------------------------------------
-- Signal declaration
----------------------------------------------------------------------------------
	
	type	MtStateType is
		(
			stIdle,
			-- Read
			stChangeAddr,
			stWtData,
			stRdData							
		);
	signal	rMtState	: MtStateType;

	signal	rMemInitDone	: std_logic_vector( 1 downto 0 );
	signal	rHDMIReq		: std_logic;

	
	signal	rMtAddr				: std_logic_vector( 28 downto 7 );	-- Transfer address to request to Avalon-bus
	
	-- Read
	signal	rMtRead				: std_logic;						-- Output to MtRead Port
	signal	rRdBurstCnt			: std_logic_vector( 4 downto 0 );	-- Burst Counter for read transfer	

	signal	rMtDdrRdReq			: std_logic;
	signal	rMtDdrRdBusy		: std_logic;
	signal rVaryAddr			: std_logic_vector( 26 downto 7 );
	signal rNumreq				: std_logic_vector(15 downto 0 );
Begin

----------------------------------------------------------------------------------
-- Output assignment
----------------------------------------------------------------------------------

	HDMIReq			<= rHDMIReq;
	--MtDdrRdReq		: out	std_logic;
	--MtDdrRdAddr		: out	std_logic_vector( 28 downto 7 );
	--D2URdFfWrCnt	: out	std_logic_vector( 15 downto 0 );
	--URd2HFfWrEn		: out	std_logic;
	--URd2HFfWrData	: out	std_logic_vector( 63 downto 0 );

	MtDdrRdReq		<= rMtDdrRdReq;
	MtDdrRdAddr		<= rMtAddr;

	URd2HFfWrEn		<= D2URdFfWrEn;
	URd2HFfWrData	<= D2URdFfWrData;
	D2URdFfWrCnt	<= URd2HFfWrCnt;
	


----------------------------------------------------------------------------------
-- DFF 
----------------------------------------------------------------------------------
	
	u_rMemInitDone : Process (Clk) Is
	Begin
		if ( rising_edge(Clk) ) then
			if ( RstB='0' ) then
				rMemInitDone	<= "00";
			else
				-- Use rMemInitDone(1) in your design
				rMemInitDone	<= rMemInitDone(0) & MemInitDone;
			end if;
		end if;
	End Process u_rMemInitDone;

	u_rHDMIReq : Process (Clk) Is
	Begin
		if ( rising_edge(Clk) ) then
			if ( RstB='0' ) then
				rHDMIReq	<= '0';
			else
				if ( HDMIBusy='0' and rMemInitDone(1)='1' ) then
					rHDMIReq	<= '1';
				elsif ( HDMIBusy='1' )  then
					rHDMIReq	<= '0';
				else
					rHDMIReq	<= rHDMIReq;
				end if;
			end if;
		end if;
	End Process u_rHDMIReq;
	------------------------------------------------------------------
	---- edit below
	------------------------------------------------------------------

	u_rMtDdrRdBusy : Process (Clk) Is
		Begin
			if ( rising_edge(Clk) ) then
				rMtDdrRdBusy		<= MtDdrRdBusy;
			end if;
		End Process u_rMtDdrRdBusy;

	u_rMtDdrRdReq : Process (Clk) Is
	Begin
		if ( rising_edge(Clk) ) then
			if ( RstB='0' ) then
				rMtDdrRdReq		<= '0';
			else
				if (MtDdrRdBusy='0') then
					rMtDdrRdReq		<= '1';
				else
					rMtDdrRdReq		<= '0';
				end if;
			end if;
		end if;
	End Process u_rMtDdrRdReq;
	
	

	u_rMtDdrRdAddr : Process (Clk) Is
	Begin
		if ( rising_edge(Clk) ) then
			if ( RstB='0' ) then
				rNumreq		<= conv_std_logic_vector(cnumreq,16) ;
				rMtAddr	<= DipSwitch & conv_std_logic_vector(0,20);
				rVaryAddr <= (others => '0');
			else

				if ((rMtDdrRdReq ='1') and (rMtDdrRdBusy ='1')) then

					if (rNumreq-1  /= 0) then
						rVaryAddr	<= rVaryAddr + 1;
						rNumreq <= rNumreq - 1;

						--rMtAddr(28 downto 27)	<= DipSwitch;
						rMtAddr(26 downto 7)	<= rVaryAddr;
					else
						rNumreq		<= conv_std_logic_vector(cnumreq,16) ;
                        --rMtAddr(28 downto 27)	<= DipSwitch;
                        --rMtAddr(26 downto 7)	<= (others => '0');	
						rVaryAddr <= (others => '0');
						--rMtAddr(28 downto 7)    <= DipSwitch & conv_std_logic_vector(0,20);
						rMtAddr(28 downto 7)    <= DipSwitch & rVaryAddr;

					end if;
				else
					rMtAddr		<= rMtAddr;
				end if;

			end if;
		end if;
	End Process u_rMtDdrRdAddr;


End Architecture rtl;