library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use ieee.std_logic_1164.STD_LOGIC.;
Entity RxSerial Is
Port(
	RstB		: in	std_logic;
	Clk			: in	std_logic;
	
	SerDataIn	: in	std_logic;
	
	RxFfFull	: in	std_logic;
	RxFfWrData	: out	std_logic_vector( 7 downto 0 );
	RxFfWrEn	: out	std_logic
	--TxFfRdEn	: out	std_logic
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
	signal rDataCnt		: std_logic_vector( 3 downto 0);
	

	signal rserData : std_logic_vector( 9 downto 0);
	
	signal rTxFfRdEn 	: std_logic_vector( 1 downto 0);
	signal rRxFfWrData	: std_logic_vector( 7 downto 0 );
	
	type	StateType is
					(stIdle,
					 stRdReq,
					 stWtData,
					 stWtEnd,
					 stWtNewData
					);
	signal rState	: StateType;

Begin

----------------------------------------------------------------------------------
-- Output assignment
	TxFfRdEn <= rTxFfRdEn;
	RxFfWrData <= rRxFfWrData;

----------------------------------------------------------------------------------

	u_rBuadCnt : Process (Clk) Is 
	Begin
		if (rising_edge(Clk)) then
			if (RstB='0') then
				rBuadCnt <= conv_std_logic_vector(cbuadCnt,10);
			else
				if (rState = stWtEnd) then
				--if (rTxFfRdEn(1)='1') then --  
					
					if ( rBuadCnt =1) then
						rBuadCnt <= conv_std_logic_vector(cbuadCnt,10);
					else
						rBuadCnt <= rBuadCnt - 1;
					end if;
				
				else
					rBuadCnt <= rBuadCnt;
				end if;
			end if;
		end if;
	End Process u_rBuadCnt;

	u_rBuadEnd : Process (Clk) Is
	Begin
		if (rising_edge(Clk)) then
			if (RstB='0') then
				rBuadEnd <= '0';
			else
				--if (rBuadCnt=1) then
				if (rBuadCnt=686) then
					rBuadEnd <= '1';
				else
					rBuadEnd <= '0';
				end if;
			end if;
		end if;
	End Process u_rBuadEnd;
	
	u_rDataCnt	: Process (Clk) Is 
	Begin
		if (rising_edge(Clk)) then
			if (RstB='0') then
				rDataCnt <= conv_std_logic_vector(cDataCnt,4);
			else
				if (rBuadEnd='1') then
					if (rDataCnt=9) then
						rDataCnt  <= conv_std_logic_vector(cDataCnt,4);
					else
						rDataCnt <= rDataCnt + 1;
					end if;
				else
					rDataCnt <= rDataCnt;
				end if;
			end if;
		end if;
	End Process u_rDataCnt;

----------------------------------------------------------------------------------
-- DFF 
----------------------------------------------------------------------------------
							
	
	u_rState : Process (Clk) Is
	Begin
		if rising_edge(Clk) then
			if ( RstB='0') then
				rState <= stIdle;
			else
				case ( rState) is
					when stIdle		=>
						rState <= stRdReq
						
					when stRdReq 	=>					
						rState <= stWtData;
						
					when stWtData 	=>
						if ( (rTxFfRdEn(1) = '1') and (SerDataIn = '0') )then
							
							rState <= stWtEnd;
						else
							rState <= stWtData;
						end if;
						
					when stWtEnd 	=>
			
						if ((rBuadEnd ='1') and (rDataCnt=9)) then --- ?????????????
	
							rState <= stWtNewData
							
						else
							rState <= stWtEnd;
						end if;
						
					when stWtNewData =>
						if (SerDataIn='0') then
							rState <= stWtEnd;
						else
							rState <= stWtNewData;
						end if;
								
				end case;
			end if;
		end if;
	End Process u_rState;
	---------------------------------------------------------------------------------
	u_rTxFfRdEn : Process (Clk) Is
	Begin
		if (rising_edge(Clk)) then
			if (RstB='0') then
				rTxFfRdEn <= "00";
			else
				rTxFfRdEn(1) <= rTxFfRdEn(0);
				if (rState = stRdReq) then
					rTxFfRdEn(0) <= '1';
				else
					rTxFfRdEn(0) <= '0';
				end if;
			end if;
		end if;
	End Process u_rTxFfRdEn;
	--------------------------------------------------------------------
	u_rRxFfWrEn : Process (Clk) Is
	Begin
		if (rising_edge(Clk)) then
			if (RstB='0') then
				rTxFfRdEn <= "00";
			else
				if ( (SerDataIn = '1') and (RxFfFull = '0') )  then
					rRxFfWrEn <= '1';
				else
					rRxFfWrEn <= '0';
				end if;
			end if;
		end if;
	End Process u_rRxFfWrEn;
	---------------------------------------------------------------			
	u_rRxFfData : Process(Clk) then
		if (rising_edge(Clk)) then
			if (RstB='0') then
				rRxFfData <= (others => '1');;
			else
				if (state = stWtEnd) then
					if ((rBuadEnd ='1') and (rDataCnt=9) and (RxFfWrEn = '1')) then
					
						rRxFfWrData <= rSerDataIn(8 downto 1);
					else
						rRxFfWrData <= rRxFfData;
					end if;
				else
					rRxFfWrData <= rRxFfData;
				end if;
			end if;
		end if;
	End Process u_rRxFfData;
	-- u_rSerDataIn : Process (Clk) Is
	-- Begin
		-- if ( rising_edge(Clk) ) then
			-- rSerDataIn		<= SerDataIn;
		-- end if;
	-- End Process u_rSerDataIn;
	---------------------------------------------------------------------------
	u_rSerData : Process (Clk) Is
	Begin
		if ( rising_edge(Clk)) then
			if ( RstB='0') then
				rserData <= (others => '1');
			else
				-- --if (Start='1') then
				-- --if ( rTxFfRdEn(1) ='1') then
				-- if (rSerDataIn = '0') then
					-- rserData(9) <='1';
					-- rserData(8 downto 1) <= TxFfRdData( 7 downto 0);
					-- rserData(0) <= '0';
				-- elsif ( rBuadEnd ='1') then
					-- rserData <= '1'& rserData(9 downto 1) ;
				-- else
					-- rserData <= rserData;
				-- end if;
				rserData <= SerDataIn & rserData(3 downto 1);
			end if;
		end if;
	End Process u_rSerData;
	 
	
	
End Architecture rtl;