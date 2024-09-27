library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_mealy_fsm is
end tb_mealy_fsm;

architecture tb_arch of tb_mealy_fsm is

    -- Constants for clock periods
    constant clk_100mhz_period : time := 20 ns;
    constant clk_25mhz_period  : time := 80 ns;

    -- Signals for testbench
    signal clk_in_tb       : std_logic := '0';
    signal clk_hssl_tb        : std_logic := '0';
    signal data_hssl_sender_tb : std_logic := '0';
    signal reset_tb            : std_logic := '0';
    signal DATA_WIDTH  : natural := 48;
    signal GAP_BITS  : natural := 8;
    signal output_data      :  std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal counting_gap          :   std_logic := '0' ;
    signal reading_data          :   std_logic := '0';
    signal data_valid            :   std_logic := '0';
    --
    signal idle_state            :   std_logic := '0' ;
    signal gap_counting_state    :   std_logic := '0' ;
    signal data_reading_state    :   std_logic := '0' ;
    signal output_data_state     :   std_logic := '0' ;
    signal clk_hssl_sync        : std_logic  := '0';
    signal synced_data_hssl      : std_logic  := '0';        
    signal error_hssl            : std_logic := '0';     
    signal error_out             : std_logic := '0';     

begin

    -- Instantiate the DUT (Design Under Test)
    dut : entity work.HSSL_Reader
        generic map (
            GAP_BITS   => GAP_BITS, -- Set your desired GAP_BITS value
            DATA_WIDTH => DATA_WIDTH -- Set your desired DATA_WIDTH value
        )
        port map (
            clk_in           => clk_in_tb,
            clk_hssl         => clk_hssl_tb,
            data_hssl_sender => data_hssl_sender_tb,
            reset            => reset_tb,
            error_hssl       => error_hssl,
            error_out        => error_out,
            output_data      => output_data
        );

    -- Clock process for clk_100mhz
    process
    begin
        while now < 100000 ns loop  -- Simulate for 400 ns
            clk_in_tb <= '0';
            wait for clk_100mhz_period / 2;
            clk_in_tb <= '1';
            wait for clk_100mhz_period / 2;
        end loop;
        wait;
    end process;

    -- Stimulus process for data_hssl_sender_tb
    process
    begin
        wait for 20 ns;  -- Wait before starting stimulus

        -- Burst 1
        data_hssl_sender_tb <= '1';
        clk_hssl_tb <= '1';
        for i in 1 to DATA_WIDTH-5 loop  -- Send 8 data bits
            wait for clk_25mhz_period/2;
            clk_hssl_tb <= '0';
            data_hssl_sender_tb <= '0';
            wait for clk_25mhz_period/2;
            data_hssl_sender_tb <= '1';
            clk_hssl_tb <= '1';
        end loop;

        -- Gap between bursts
        data_hssl_sender_tb <= '0';
        clk_hssl_tb <= '0';  -- Hold clk_25mhz_tb low during gap
        wait for GAP_BITS * clk_25mhz_period;
        clk_hssl_tb <= '1';  -- Bring clk_25mhz_tb back high after gap

        -- Burst 2
        data_hssl_sender_tb <= '0';
        for i in 1 to DATA_WIDTH loop  -- Send 8 data bits
            wait for clk_25mhz_period/2;
            clk_hssl_tb <= '0';
            data_hssl_sender_tb <= '0';
            wait for clk_25mhz_period/2;
            data_hssl_sender_tb <= '0';
            clk_hssl_tb <= '1';
        end loop;

        -- Gap between bursts
        data_hssl_sender_tb <= '0';
        clk_hssl_tb <= '0';  -- Hold clk_25mhz_tb low during gap
        wait for GAP_BITS * clk_25mhz_period;
        clk_hssl_tb <= '1';  -- Bring clk_25mhz_tb back high after gap

        -- Burst 3
        data_hssl_sender_tb <= '1';
        for i in 1 to DATA_WIDTH loop  -- Send 8 data bits
            wait for clk_25mhz_period/2;
            clk_hssl_tb <= '0';
            data_hssl_sender_tb <= '0';
            wait for clk_25mhz_period/2;
            data_hssl_sender_tb <= '1';
            clk_hssl_tb <= '1';
        end loop;
        
        -- Gap between bursts
        data_hssl_sender_tb <= '0';
        clk_hssl_tb <= '0';  -- Hold clk_25mhz_tb low during gap
        wait for GAP_BITS * clk_25mhz_period;
        clk_hssl_tb <= '1';  -- Bring clk_25mhz_tb back high after gap

        -- Burst 3
        data_hssl_sender_tb <= '0';
        for i in 1 to DATA_WIDTH loop  -- Send 8 data bits
            wait for clk_25mhz_period/2;
            clk_hssl_tb <= '0';
            data_hssl_sender_tb <= '1';
            wait for clk_25mhz_period/2;
            data_hssl_sender_tb <= '0';
            clk_hssl_tb <= '1';
        end loop;

        wait;
    end process;

    -- Reset process
    process
    begin
        reset_tb <= '0';
        wait for 10 ns;
        reset_tb <= '1';
        wait;
    end process;

end tb_arch;
