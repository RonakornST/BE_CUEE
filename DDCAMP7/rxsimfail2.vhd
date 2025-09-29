library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
Entity RxSerial Is
Port(
	RstB		: in	std_logic;
	Clk			: in	std_logic;
	
	SerDataIn	: in	std_logic;
	
	RxFfFull	: in	std_logic;
	RxFfWrData	: out	std_logic_vector( 7 downto 0 );
	RxFfWrEn	: out	std_logic
);
End Entity RxSerial;

Architecture rtl Of RxSerial Is

----------------------------------------------------------------------------------
-- Constant declaration
----------------------------------------------------------------------------------
	constant	cbuadCnt	: integer := 868;
	constant    cDataCnt 	: integer := 0;

----------------------------------------------------------------------------------
-- Signal declaration
----------------------------------------------------------------------------------
	signal rBuadCnt	: std_logic_vector( 9 downto 0);
	signal rBuadEnd	: std_logic;
	signal rBuadEndShift	: std_logic;
	signal rDataCnt		: std_logic_vector( 3 downto 0);
	

	signal rserData : std_logic_vector( 9 downto 0);
	
	signal rRxFfWrData	: std_logic_vector( 7 downto 0 );
    signal rRxFfWrEn	: std_logic;

	signal rSerDataIn	: std_logic;
	type	StateType is
					(
					 stWtFirstData,
					 stWtEnd,
					 stWtNextData
					);
	signal rState	: StateType;

Begin

----------------------------------------------------------------------------------
-- Output assignment
	--TxFfRdEn <= rTxFfRdEn;
	RxFfWrEn <= rRxFfWrEn;
	RxFfWrData <= rRxFfWrData;

----------------------------------------------------------------------------------

	u_rBuadCnt : Process (Clk) Is 
	Begin
		if (rising_edge(Clk)) then
			if (RstB='0') then
				rBuadCnt <= conv_std_logic_vector(cbuadCnt,10);
			else
				if (rState = stWtEnd) then
					if ( rBuadCnt =1) then
						rBuadCnt <= conv_std_logic_vector(cbuadCnt,10);
					else
						rBuadCnt <= rBuadCnt - 1;
					end if;
				elsif (rState = stWtNextData) then
					rBuadCnt <= conv_std_logic_vector(cbuadCnt,10);
					--rSerData <= (others => '1');
				else
					--rBuadCnt <= rBuadCnt; --- sai cbuadcnt dee mah
					rBuadCnt <= conv_std_logic_vector(cbuadCnt,10);
				end if;
				-- if (rState = stWtEnd) then
					-- if ( rBuadCnt =1) then
						-- rBuadCnt <= conv_std_logic_vector(cbuadCnt,10);
					-- else
						-- rBuadCnt <= rBuadCnt - 1;
					-- end if;
				-- else
					-- if (rState = stWtData) then
						-- rBuadCnt <= conv_std_logic_vector(cbuadCnt,10);
					-- else
						-- rBuadCnt <= rBuadCnt;
					-- end if;
				-- end if;
			end if;
		end if;
	End Process u_rBuadCnt;

	u_rBuadEnd : Process (Clk) Is
	Begin
		if (rising_edge(Clk)) then
			if (RstB='0') then
				rBuadEnd <= '0';
			else
				if ( rState = stWtEnd) then
					if (rBuadCnt=435) then --  make rbaudend is 1 at the middle of the bit from 686 length
						rBuadEnd <= '1';
					else
						rBuadEnd <= '0';
					end if;
				else
					rBuadEnd <= '0';
				end if;
			end if;
		end if;
	End Process u_rBuadEnd;

	u_rBuadEndShift : Process (Clk) Is
	Begin
		if (rising_edge(Clk)) then
			if (RstB='0') then
				rBuadEndShift <= '0';
			else
				rBuadEndShift <= rBuadEnd;
			end if;
		end if;
	End Process u_rBuadEndShift;
	
	u_rDataCnt	: Process (Clk) Is 
	Begin
		if (rising_edge(Clk)) then
			if (RstB='0') then
				rDataCnt <= conv_std_logic_vector(cDataCnt,4);
			else
				if (rState = stWtEnd) then
					if (rBuadEnd='1') then
						if (rDataCnt=10) then
							rDataCnt  <= conv_std_logic_vector(cDataCnt,4);
						else
							rDataCnt <= rDataCnt + 1;
						end if;
					else
						rDataCnt <= rDataCnt;
					end if;
				elsif (rState = stWtNextData) then
					rDataCnt  <= conv_std_logic_vector(cDataCnt,4);
				else
					rDataCnt <= rDataCnt;
				--if (rBuadCnt=1) then
				--if (rBuadCnt=412) then
					--if (rDataCnt=9) then
						--rDataCnt  <= conv_std_logic_vector(cDataCnt,4);
					--else
						--rDataCnt <= rDataCnt + 1;
					--end if;
				--else
					--rDataCnt <= rDataCnt;
				end if;
			end if;
		end if;
	End Process u_rDataCnt;

----------------------------------------------------------------------------------
-- DFF 
----------------------------------------------------------------------------------
	u_rSerDataIn : Process (Clk) Is
	Begin
		if ( rising_edge(Clk) ) then
			rSerDataIn		<= SerDataIn;
		end if;
	End Process u_rSerDataIn;

	u_rState : Process (Clk) Is
	Begin
		if rising_edge(Clk) then
			if ( RstB='0') then
				rState <= stWtFirstData;
			else
				case ( rState) is
				
					when stWtFirstData 	=>
						-- addnewdata
						if (rSerDataIn = '0') then
							rState <= stWtEnd;
						else
							rState <= stWtFirstData;
						end if;
						
					when stWtEnd 	=>
						if ((rBuadCnt =430) and (rDataCnt=10)) then --- finish reading for sure
							rState <= stWtNextData;
						else
							rState <= stWtEnd;
						end if;
					
					when stWtNextData 	=>
						if (rSerDataIn = '0') then
							rState <= stWtEnd;
						else
							rState <= stWtNextData;
						end if;
				
				end case;
			end if;
		end if;
	End Process u_rState;
	---------------------------------------------------------------------------------
	--------------------------------------------------------------------
	u_rRxFfWrEn : Process (Clk) Is
	Begin
		if (rising_edge(Clk)) then
			if (RstB='0') then
				 rRxFfWrEn<= '0';
			else
				--if ( (SerDataIn = '1') and (RxFfFull = '0') )  then
				--if ( (rSerData(9) = '1') and (rSerData(0)='0') and (RxFfFull = '0') )  then
				--if ( (rDataCnt = 9) and (rBuadCnt=430) and (RxFfFull = '0') )  then
				if ( (rSerDataIn = '1') and (rDataCnt = 10) and (rBuadEndShift='1') and (RxFfFull = '0') )  then
				--if ( (rSerDataIn = '1') and (rDataCnt = 9) and (rBuadEndS='1') and (RxFfFull = '0') )  then -- Data need to ready before WrEn
					rRxFfWrEn <= '1';
				else
					rRxFfWrEn <= '0';
				end if;
			end if;
		end if;
	End Process u_rRxFfWrEn;
	---------------------------------------------------------------			
	u_rRxFfWrData : Process(Clk) Is
    Begin
		if (rising_edge(Clk)) then
			if (RstB='0') then
				rRxFfWrData <= (others => '1');
			else
				if (rstate = stWtEnd) then
					--if ((rBuadEnd ='1') and (rDataCnt=9) and (rRxFfWrEn = '1')) then
					--if ((rSerData(0) ='0') and (rSerData(9)='1')and (rDataCnt=9) and (rRxFfWrEn = '1')) then
					--if ((rSerData(0) ='0') and (rSerData(9)='1') and (rRxFfWrEn = '1')) then
					if ((rSerData(0) ='0') and (rSerData(9)='1') and (rRxFfWrEn = '1')) then
						rRxFfWrData <= rSerData(8 downto 1);
					else
						rRxFfWrData <= rRxFfWrData;
					end if;
				else
					rRxFfWrData <= rRxFfWrData;
				end if;
			end if;
		end if;
	End Process u_rRxFfWrData;

	---------------------------------------------------------------------------
	u_rSerData : Process (Clk) Is
	Begin
		if ( rising_edge(Clk)) then
			if ( RstB='0') then
				rserData <= (others => '1');
			else
				if (rState = stWtEnd) then
					if ( rBuadEnd = '1') then
						--rserData <= SerDataIn & rserData(9 downto 1);
						rserData <= rSerDataIn & rserData(9 downto 1);
					else
						--if ((rBuadCnt =1) and (rDataCnt=9)) then
							--rserData <= (others => '1');
						--else
							--rserData <= rserData;
						--end if;
					end if;
				elsif (rState = stWtNextData) and (rSerDataIn ='0')then
					rserData <= (others => '1');
				else
					rserData <= rserData;
				end if;
			end if;
		end if;
	End Process u_rSerData;
	
End Architecture rtl;