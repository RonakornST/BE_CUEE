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
	signal rDataCnt		: std_logic_vector( 3 downto 0);
	

	signal rserData : std_logic_vector( 9 downto 0);
	signal rRxFfWrData	: std_logic_vector( 7 downto 0 );
    signal rRxFfWrEn	: std_logic;

	
	type	StateType is
					(
					 stWtData,
					 stWtEnd
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
				if (rBuadCnt=434) then --  rbaudend is 1 at the middle of the bit from 686 length
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
				rState <= stWtData;
			else
				case ( rState) is
				
					when stWtData 	=>
						if (SerDataIn = '0') then
							rState <= stWtEnd;
						else
							rState <= stWtData;
						end if;
						
					when stWtEnd 	=>
			
						if ((rBuadCnt =1) and (rDataCnt=9)) then --- ?????????????

							rState <= stWtData;
							
						else
							rState <= stWtEnd;
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
				if ( (SerDataIn = '1') and (RxFfFull = '0') )  then
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
					if ((rBuadEnd ='1') and (rDataCnt=9) and (rRxFfWrEn = '1')) then
					
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
				rserData <= SerDataIn & rserData(9 downto 1);
			end if;
		end if;
	End Process u_rSerData;
	 
	
	
End Architecture rtl;