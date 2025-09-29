----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
-- Filename     UserWrDdr.vhd
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

Entity UserWrDdr Is
	Port
	(
		RstB			: in	std_logic;							-- use push button Key0 (active low)
		Clk				: in	std_logic;							-- clock input 100 MHz

		-- WrCtrl I/F
		MemInitDone		: in	std_logic;
		MtDdrWrReq		: out	std_logic;
		MtDdrWrBusy		: in	std_logic;
		MtDdrWrAddr		: out	std_logic_vector( 28 downto 7 );
		
		-- T2UWrFf I/F
		T2UWrFfRdEn		: out	std_logic;
		T2UWrFfRdData	: in	std_logic_vector( 63 downto 0 );
		T2UWrFfRdCnt	: in	std_logic_vector( 15 downto 0 );
		
		-- UWr2DFf I/F
		UWr2DFfRdEn		: in	std_logic;
		UWr2DFfRdData	: out	std_logic_vector( 63 downto 0 );
		UWr2DFfRdCnt	: out	std_logic_vector( 15 downto 0 )
	);
End Entity UserWrDdr;

Architecture rtl Of UserWrDdr Is

----------------------------------------------------------------------------------
-- Component declaration
----------------------------------------------------------------------------------
	
	constant	cnumreq	: integer := 24576;
----------------------------------------------------------------------------------
-- Signal declaration
----------------------------------------------------------------------------------
	
	signal	rMemInitDone	: std_logic_vector( 1 downto 0 );

	signal	rMtDdrWrAddr	: std_logic_vector( 28 downto 7 );

	signal	rMtDdrWrReq		: std_logic;
	signal	rMtDdrWrBusy	: std_logic;

	signal rVaryAddr			: std_logic_vector( 26 downto 7 );
	signal rNumreq				: std_logic_vector(15 downto 0 );


Begin

----------------------------------------------------------------------------------
-- Output assignment
----------------------------------------------------------------------------------
	MtDdrWrReq	<= rMtDdrWrReq;
	MtDdrWrAddr	<= rMtDdrWrAddr;

	T2UWrFfRdEn		<= UWr2DFfRdEn;
	UWr2DFfRdData	<= T2UWrFfRdData;
	UWr2DFfRdCnt	<= T2UWrFfRdCnt;
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

	u_rMtDdrWrBusy : Process (Clk) Is
	Begin
		if ( rising_edge(Clk) ) then
			rMtDdrWrBusy		<= MtDdrWrBusy;
		end if;
	End Process u_rMtDdrWrBusy;

	u_rMtDdrWrReq : Process (Clk) Is
	Begin
		if ( rising_edge(Clk) ) then
			if ( RstB='0' ) then
				rMtDdrWrReq		<= '0';
			else
				if (rMtDdrWrBusy='1') then
					rMtDdrWrReq		<= '0';
				else
					rMtDdrWrReq		<= '1';
				end if;
			end if;
		end if;
	End Process u_rMtDdrWrReq;

	u_rMtDdrWrAddr : Process (Clk) Is
	Begin
		if ( rising_edge(Clk) ) then
			if ( RstB='0' ) then

				rMtDdrWrAddr	<= conv_std_logic_vector(0,22);
			else

				if ((rMtDdrWrReq ='1') and (rMtDdrWrBusy ='1')) then

					if (rNumreq /= 0) then
						--rVaryAddr	<= rVaryAddr + 1;
						rNumreq <= rNumreq - 1;

						rMtDdrWrAddr <= rMtddrWrAddr + 1;
					else
						rNumreq		<= conv_std_logic_vector(cnumreq,16);
                        rMtddrWrAddr <= rMtDdrWrAddr(28 downto 27) & conv_std_logic_vector(0,20) + conv_std_logic_vector(2 **20,22);	
					end if;

				else
					rMtddrwrAddr		<= rMtDdrWrAddr;
				end if;

			end if;
		end if;
	End Process u_rMtDdrWrAddr;
	
End Architecture rtl;