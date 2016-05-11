----------------------------------------------------------------------------------
-- Company:        IIHE - ULB
-- Engineer:       Thomas Lenzi (thomas.lenzi@cern.ch)
-- 
-- Create Date:    08:37:33 07/07/2015 
-- Design Name:    GLIB v2
-- Module Name:    ipbus_counters - Behavioral 
-- Project Name:   GLIB v2
-- Target Devices: xc6vlx130t-1ff1156
-- Tool versions:  ISE  P.20131013
-- Description: 
--
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.ipbus.all;
use work.system_package.all;
use work.user_package.all;

entity control is
port(

    ipb_clk_i           : in std_logic;
    reset_i             : in std_logic;
    
    ipb_mosi_i          : in ipb_wbus;
    ipb_miso_o          : out ipb_rbus;
    
    tk_rx_polarity_o    : out std_logic_vector(3 downto 0);
    tk_tx_polarity_o    : out std_logic_vector(3 downto 0)
);
end control;

architecture control_arch of control is
    
    -- IPbus registers
    type ipb_state_t is (IDLE, RSPD, RST);
    signal ipb_state                : ipb_state_t := IDLE;    
    signal ipb_reg_sel              : integer range 0 to 15;
    signal ipb_read_reg_data        : std32_array_t(0 to 15);
    signal ipb_write_reg_data       : std32_array_t(0 to 15);
    
    signal tk_rx_polarity           : std_logic_vector(3 downto 0) := (others => '0');
    signal tk_tx_polarity           : std_logic_vector(3 downto 0) := (others => '0');
    
begin

    tk_rx_polarity_o <= tk_rx_polarity;
    tk_tx_polarity_o <= tk_tx_polarity;

    ipb_read_reg_data(0)(3 downto 0) <= tk_rx_polarity;
    tk_rx_polarity                   <= ipb_write_reg_data(0)(3 downto 0);
    ipb_read_reg_data(1)(3 downto 0) <= tk_tx_polarity;
    tk_tx_polarity                   <= ipb_write_reg_data(1)(3 downto 0);

    --================================--
    -- IPbus
    --================================--

    process(ipb_clk_i)       
    begin    
        if (rising_edge(ipb_clk_i)) then      
            if (reset_i = '1') then    
                ipb_miso_o <= (ipb_ack => '0', ipb_err => '0', ipb_rdata => (others => '0'));    
                ipb_state <= IDLE;
                ipb_reg_sel <= 0;
                
                ipb_write_reg_data <= (others => (others => '0'));
            else         
                case ipb_state is
                    when IDLE =>                    
                        ipb_reg_sel <= to_integer(unsigned(ipb_mosi_i.ipb_addr(8 downto 0)));
                        if (ipb_mosi_i.ipb_strobe = '1') then
                            ipb_state <= RSPD;
                        end if;
                    when RSPD =>
                        ipb_miso_o <= (ipb_ack => '1', ipb_err => '0', ipb_rdata => ipb_read_reg_data(ipb_reg_sel));
                        if (ipb_mosi_i.ipb_write = '1') then
                            ipb_write_reg_data(ipb_reg_sel) <= ipb_mosi_i.ipb_wdata;
                        end if;
                        ipb_state <= RST;
                    when RST =>
                        ipb_miso_o.ipb_ack <= '0';
                        ipb_state <= IDLE;
                    when others => 
                        ipb_miso_o <= (ipb_ack => '0', ipb_err => '0', ipb_rdata => (others => '0'));    
                        ipb_state <= IDLE;
                        ipb_reg_sel <= 0;
                    end case;
            end if;        
        end if;        
    end process;

end control_arch;