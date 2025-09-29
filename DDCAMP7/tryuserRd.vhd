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
	
	
----------------------------------------------------------------------------------
-- Signal declaration
----------------------------------------------------------------------------------
	
	type	MtStateType is
		(
			stIdle,
			-- Read
			stChkRdRdy,
			stGenRdReq,
			stRdTrans							
		);
	signal	rMtState	: MtStateType;

	signal	rMemInitDone	: std_logic_vector( 1 downto 0 );
	signal	rHDMIReq		: std_logic;

	
	signal	rMtAddr				: std_logic_vector( 28 downto 7 );	-- Transfer address to request to Avalon-bus
	signal	rMtBusy				: std_logic;
	
	-- Read
	signal	rMtRead				: std_logic;						-- Output to MtRead Port
	signal	rRdBurstCnt			: std_logic_vector( 4 downto 0 );	-- Burst Counter for read transfer	

	
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
	u_rMtState : Process (Clk) Is
	Begin
		if ( rising_edge(Clk) ) then
			if ( RstB='0' ) then
				rMtState		<= stIdle;
			else
				case ( rMtState ) is				
					-- Wait start pulse
					when stIdle		=>
						if ( MtDdrRdReq='1' ) then
							-- Read transfers
							rMtState	<= stChkRdRdy;
						else
							rMtState	<= stIdle;
						end if;

					------------------------------------------------------
					-- Read Transfer
					when stChkRdRdy	=>
--						if ( RdFfWrCnt(15 downto 4)/=x"FFF" ) then
						-- Free space is more than 1 burst size 
						--if ( RdFfWrCnt(15 downto 5)/=("111"&x"FF") ) then
						if ( D2URdFfWrCnt(15 downto 5)/=("111"&x"FF") ) then
							rMtState	<= stGenRdReq;
						else
							rMtState	<= stChkRdRdy;
						end if;
						
					-- Generate read request
					when stGenRdReq	=>
						-- Request complete
						-- if ( rMtRead='1' and MtWaitRequest='0' ) then    URd2HFfWrCnt
						if ( rMtRead='1' and (URd2HFfWrCnt > 32) ) then
							rMtState	<= stRdTrans;
						else
							rMtState	<= stGenRdReq;
						end if;
					
					when stRdTrans	=>
						-- Last data in burst
						if ( MtReadDataValid='1' and rRdBurstCnt=1 ) then
							-- End command
							rMtState	<= stIdle;
						else
							rMtState	<= stRdTrans;
						end if;
					
				end case;
			end if;
		end if;
	End Process u_rMtState;

	u_rMtAddr : Process (Clk) Is
	Begin
		if ( rising_edge(Clk) ) then
			-- Load command MtAddr buffer address
			if ( MtDdrRdReq='1' ) then
				rMtAddr(28 downto 7)	<= MtDdrRdAddr(28 downto 7);
			else
				rMtAddr(28 downto 7)	<= rMtAddr(28 downto 7);
			end if;
		end if;
	End Process u_rMtAddr;

	u_rMtBusy : Process (Clk) Is
	Begin
		if ( rising_edge(Clk) ) then
			if ( RstB='0' ) then
				rMtBusy	<= '0';
			else
				if ( rMtState=stIdle ) then
					if ( MtDdrRdReq='1' ) then
						rMtBusy	<= '1';
					else
						rMtBusy	<= '0';
					end if;
				else
					rMtBusy	<= '1';
				end if;
			end if;
		end if;
	End Process u_rMtBusy;
	
	------------------------------------------------------------------------------
	-- Read
	
	u_rMtRead : Process (Clk) Is
	Begin
		if ( rising_edge(Clk) ) then
			if ( RstB='0' ) then
				rMtRead		<= '0';
			else
				-- Request complete
				--if ( rMtRead='1' and MtWaitRequest='0' ) then
				if ( rMtRead='1' and (URd2HFfWrCnt > 32) ) then
					rMtRead		<= '0';
				-- Send read request when RdFifo is not full
				elsif ( rMtState=stGenRdReq ) then
					rMtRead		<= '1';
				else
					rMtRead		<= rMtRead;
				end if;
			end if;
		end if;
	End Process u_rMtRead;
	
	u_rRdBurstCnt : Process (Clk) Is
	Begin
		if ( rising_edge(Clk) ) then
			-- Receive each data
			--if ( MtReadDataValid='1' ) then
			if ( MtReadData='1' ) then
				rRdBurstCnt		<= rRdBurstCnt - 1;
			-- Load new value when read request
			elsif ( rMtState=stGenRdReq ) then
				-- fixed burst count = 16x64 bit
				rRdBurstCnt		<= "10000";
			else
				rRdBurstCnt		<= rRdBurstCnt;
			end if;
		end if;
	End Process u_rRdBurstCnt;

End Architecture rtl;