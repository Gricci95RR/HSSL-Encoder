--! @file HSSL_Reader.vhdl
--! @brief High Speed Serial Link (HSSL) Reader Entity
--! @details This VHDL code describes the implementation of an HSSL Reader, which reads data from 
--!          a high-speed serial link and outputs data words after detecting a specified number of 
--!          gap bits. The module uses clock domain crossing (CDC) components to synchronize signals 
--!          between different clock domains.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Xilinx library for XPM_CDC
library XPM;
use XPM.VCOMPONENTS.ALL;

--! @brief HSSL_Reader entity
--! @param GAP_BITS Number of gap bits between one data word and the other
--! @param DATA_WIDTH Number of data bits
entity HSSL_Reader is
    generic(
        GAP_BITS   : integer := 8;  --!< Number of gap bits between data words
        DATA_WIDTH : integer := 48  --!< Number of data bits
    );
    Port (
        clk_in           : in  std_logic;  --!< Main clock input, must be 4 times the frequency of 'clk_hssl'
        clk_hssl         : in  std_logic;  --!< Secondary clock input, must be 1/4th the frequency of 'clk_in'
        data_hssl_sender : in  std_logic;  --!< Data input from HSSL sender
        reset            : in  std_logic;  --!< Asynchronous reset input (active low)
        error_hssl       : in  std_logic;  --!< Error input from HSSL sender (acrive high)
        error_out        : out  std_logic; --!< Error output signal
        output_data      : out std_logic_vector(DATA_WIDTH - 1 downto 0)  --!< Output data word           
    );
end HSSL_Reader;

architecture Behavioral of HSSL_Reader is

    --! @brief State type declaration
    type state_type is (IDLE, GAP_COUNTING, DATA_READING, OUTPUT_DATA_S);
    signal current_state, next_state : state_type;
    
    --! @brief FSM control signals
    signal counting_gap : std_logic := '0';
    signal reading_data : std_logic := '0';
    signal data_valid   : std_logic := '0';
    signal finish_reading : std_logic := '0';

    --! @brief Synchronized clk_25mhz signal
    signal clk_hssl_sync : std_logic;

    --! @brief Signals for edge detection and gap detection
    signal sck_prev    : std_logic := '0';
    signal sck_counter : unsigned(8 downto 0) := (others => '0'); --!< 4-bit counter for data bits
    signal gap_counter : unsigned(8 downto 0) := (others => '0'); --!< Counter for gap bits

    --! @brief Synchronized data_hssl_sender signal
    signal synced_data_hssl : std_logic;
    
    --! @brief Buffer for output data
    signal buffer_out : std_logic_vector(DATA_WIDTH - 1 downto 0) := (others => 'U');
    
begin

    --! @brief XPM_CDC_SINGLE instantiation for clk_25mhz
    xpm_cdc_single_clk25_inst : xpm_cdc_single
    generic map (
        DEST_SYNC_FF => 2,   --!< Number of synchronizer stages, must be 2 or more
        SRC_INPUT_REG => 0   --!< Source input register, 0 for direct input
    )
    port map (
        dest_out => clk_hssl_sync,  --!< Synchronized output signal
        dest_clk => clk_in,          --!< Destination clock domain (clk_in)
        src_clk => '0',
        src_in => clk_hssl           --!< Source input signal (clk_25mhz)
    );

    --! @brief XPM_CDC_SINGLE instantiation for data_hssl_sender
    xpm_cdc_single_data_inst : xpm_cdc_single
    generic map (
        DEST_SYNC_FF => 2,           --!< Number of synchronizer stages, must be 2 or more
        SRC_INPUT_REG => 0           --!< Source input register, 0 for direct input
    )
    port map (
        dest_out => synced_data_hssl,  --!< Synchronized output signal
        dest_clk => clk_in,        --!< Destination clock domain (clk_100mhz)
        src_clk => '0',
        src_in => data_hssl_sender     --!< Source input signal (data_hssl_sender)
    );

    --! @brief FSM process
    process(clk_in, reset)
    begin
        if reset = '0' then
            current_state <= IDLE;
        elsif rising_edge(clk_in) then
            current_state <= next_state;
        end if;
    end process;

    --! @brief Next state logic process
    process(current_state, clk_in)
    begin
        case current_state is
            when IDLE =>
                if (counting_gap = '1') then
                    next_state <= GAP_COUNTING;
                else
                    next_state <= IDLE;
                end if;

            when GAP_COUNTING =>
                if (gap_counter = (GAP_BITS*4)-2) then
                    next_state <= DATA_READING;
                else
                    next_state <= GAP_COUNTING;
                end if;

            when DATA_READING =>
                if (finish_reading = '1') then
                    next_state <= OUTPUT_DATA_S;
                else
                    next_state <= DATA_READING;
                end if;
                
            when OUTPUT_DATA_S =>
                next_state <= IDLE;
                
            when others =>
                next_state <= IDLE;
        end case;
    end process;

    --! @brief Output logic process
    process(current_state)
    begin
        case current_state is
            when IDLE =>
                data_valid <= '0';
            when GAP_COUNTING =>
                data_valid <= '0';
            when DATA_READING =>
                data_valid <= '0';
            when OUTPUT_DATA_S =>
                data_valid <= '1';
            when others =>
                data_valid <= '0';
        end case;
    end process;

    --! @brief Edge detection process
    process(clk_in, reset)
    begin
        if reset = '0' or error_hssl = '1' then
            sck_prev <= '0';
            sck_counter <= (others => '0');
            counting_gap <= '0';
            reading_data <= '0';
            buffer_out <= (others => '0');
        elsif rising_edge(clk_in) then
            sck_prev <= clk_hssl_sync;
            
            if reading_data = '0' then 
                sck_counter <= (others => '0');
                finish_reading <= '0';
            end if;
            
            if clk_hssl_sync = '0' and synced_data_hssl = '0' then
                if gap_counter < (GAP_BITS*4) then
                    gap_counter <= gap_counter + 1;
                    counting_gap <= '1';
                else 
                    gap_counter <= (others => '0');
                    counting_gap <= '0';
                end if;
            else
                gap_counter <= (others => '0');
                counting_gap <= '0';
            end if;
            
            if (sck_prev = '0' and clk_hssl_sync = '1' and current_state = DATA_READING) then
                if (sck_counter = DATA_WIDTH-1) then
                    --sck_counter <= sck_counter + 1;
                    sck_counter <= (others => '0');
                    finish_reading <= '1';
                    buffer_out <= buffer_out(DATA_WIDTH - 2 downto 0) & synced_data_hssl;
                    reading_data <= '0';
                else
                    sck_counter <= sck_counter + 1;
                    buffer_out <= buffer_out(DATA_WIDTH - 2 downto 0) & synced_data_hssl;
                    reading_data <= '1';
                    finish_reading <= '0';
                end if;
            end if;
        end if;
    end process;
    
    --! @brief Data Valid Process
    --! @details This process handles the output data when the data_valid signal is asserted.
    --!          When data_valid is '1', the process assigns the contents of buffer_out to 
    --!          the output_data signal.
    --! @param data_valid Signal indicating the availability of valid data.
    process(data_valid)
    begin
        --! @brief Data Output Assignment
        --! @details If data_valid signal is '1', assign buffer_out to output_data.
        if data_valid = '1' then 
            output_data <= buffer_out;
        end if;
    end process;
    
    error_out <= error_hssl;

end Behavioral;
