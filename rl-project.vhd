----------------------------------------------------------------------------------
--
-- Prova Finale (Progetto di Reti Logiche)
-- Prof. Fabio Salice - Anno Accademico 2021/2022
--
-- Filippo Fini (codice persona: XXXX, matricola: XXXX)
-- Francesca Grimaldi (codice persona: XXXX, matricola: XXXX)
-- 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity project_reti_logiche is
    port (
    i_clk : in std_logic;
    i_rst : in std_logic;
    i_start : in std_logic;
    i_data : in std_logic_vector(7 downto 0);
    o_address : out std_logic_vector(15 downto 0);
    o_done : out std_logic;
    o_en : out std_logic;
    o_we : out std_logic;
    o_data : out std_logic_vector (7 downto 0)
    );
    end project_reti_logiche;

architecture Behavioral of project_reti_logiche is

    type state_type is (IDLE, READ_W, READ_NUM, READ_MEM_WAIT, SERIALIZE_NUM, CONV, DESERIALIZE_NUM, WRITE_MEM_WAIT, WRITE_MEM, DONE);
    type state_type_conv is (S_00, S_01, S_10, S_11);
    signal conv_current_state, conv_next_state : state_type_conv;
    signal current_state, next_state, return_state, next_return_state : state_type;
    signal o_address_next, o_address_copy : std_logic_vector(15 downto 0) := (others => '0'); 
    signal o_done_next, o_en_next, o_we_next : std_logic;
    signal o_data_next : std_logic_vector(7 downto 0);
    signal words_number, words_number_next : integer range 0 to 255;
    signal count_read, count_read_next : integer range 0 to 255;
    signal count_write, count_write_next : integer range 0 to 510;
    signal i, i_next : integer range 7 downto -1;
    signal j, j_next : integer range 7 downto 0;
    signal new_out_1, new_out_2, new_out_1_next, new_out_2_next : std_logic;
    signal new_number, new_number_next : std_logic_vector(7 downto 0);
    signal signal_out, signal_out_next : std_logic;

    begin  
    
        state_reg: process(i_clk, i_rst)
        begin
            if (i_rst='1') then
                o_address <= (others => '0');
                o_done <= '0';
                o_en <= '1';
                o_we <= '0';
                o_data <= (others => '0');
                o_address_copy <= (others => '0');
                current_state <= IDLE;
                return_state <= IDLE;
                conv_current_state <= S_00;
                words_number <= 0;
                count_read <= 0;
                count_write <= 0;
                i <= 7;
                j <= 7;
                signal_out <= '0';
                new_number <= (others => '0');
                new_out_1 <= '0';
                new_out_2 <= '0';
                
            elsif (rising_edge(i_clk)) then
                o_address <= o_address_next;
                o_done <= o_done_next;
                o_en <= o_en_next; 
                o_we <= o_we_next;
                o_data <= o_data_next;   
                o_address_copy <= o_address_next;             
                current_state <= next_state;
                conv_current_state <= conv_next_state;
                return_state <= next_return_state;
                count_read <= count_read_next;
                count_write <= count_write_next;
                words_number <= words_number_next;
                i <= i_next;
                j <= j_next;
                new_number <= new_number_next;
                signal_out <= signal_out_next;
                new_number <= new_number_next;
                new_out_1 <= new_out_1_next;
                new_out_2 <= new_out_2_next;
            end if;
        end process;

        cod_conv : process(i_start, i_data, current_state, return_state, count_read, count_write, words_number, i, j, conv_current_state, o_address_copy, signal_out, new_out_1, new_out_2, new_number)
        begin
            o_address_next <= (others => '0');
            o_done_next <= '0';
            o_en_next <= '0';
            o_we_next <= '0';
            o_data_next <= (others => '0');
            new_number_next <= new_number;
            next_state <= current_state;
            conv_next_state <= conv_current_state;
            next_return_state <= return_state;
            count_read_next <= count_read;
            count_write_next <= count_write;
            words_number_next <= words_number;
            i_next <= i;
            j_next <= j;
            signal_out_next <= signal_out;
            new_out_1_next <= new_out_1;
            new_out_2_next <= new_out_2;
        
            case current_state is
                when IDLE =>
                    if (i_start = '1') then
                        o_en_next <= '1';
                        o_address_next <= o_address_copy;
                        next_return_state <= READ_W;
                        next_state <= READ_MEM_WAIT;
                    else
                        conv_next_state <= S_00;
                        words_number_next <= 0;
                        count_read_next <= 0;
                        count_write_next <= 0;
                        i_next <= 7;
                        j_next <= 7;
                        next_state <= IDLE;
                    end if;
                    
                when READ_MEM_WAIT=>  
                    o_address_next <= o_address_copy; 
                    o_en_next <= '1';
                    next_state <= return_state;
                    
                when READ_W =>
                    if ( to_integer(unsigned(i_data)) = 0 ) then
                        o_done_next <= '1';
                        next_state <= DONE;
                    else
                        words_number_next <= to_integer(unsigned(i_data));
                        o_address_next <= "0000000000000001";
                        next_return_state <= READ_NUM;  
                        next_state <= READ_MEM_WAIT;  
                    end if;
                
                when READ_NUM =>
                    if (count_read = words_number) then
                        o_done_next <= '1';
                        next_state <= DONE;
                    else
                        o_en_next <= '1';
                        o_address_next <= std_logic_vector("0000000000000001" + to_unsigned(count_read,16));
                        next_return_state <= SERIALIZE_NUM;  
                        next_state <= READ_MEM_WAIT;  
                    end if;
                
                when SERIALIZE_NUM =>
                    if (i >= 0) then
                        signal_out_next <= i_data(i);
                        i_next <= i-1;
                        o_address_next <= o_address_copy;
                        next_state <= CONV;
                    else
                        i_next <= 7;
                        count_read_next <= count_read+1;
                        next_state <= READ_NUM;
                    end if;
    
                when CONV =>
                    case conv_current_state is
                        when S_00 =>
                            if (signal_out = '0') then
                                new_out_1_next <= '0';
                                new_out_2_next <= '0';
                                conv_next_state <= S_00;
                            else
                                new_out_1_next <= '1';
                                new_out_2_next <= '1';
                                conv_next_state <= S_10;
                            end if;
    
                        when S_01 =>
                            if (signal_out = '0') then
                                new_out_1_next <= '1';
                                new_out_2_next <= '1';
                                conv_next_state <= S_00;
                            else
                                new_out_1_next <= '0';
                                new_out_2_next <= '0';
                                conv_next_state <= S_10;
                            end if;
    
                        when S_10 =>
                            if (signal_out = '0') then
                                new_out_1_next <= '0';
                                new_out_2_next <= '1';
                                conv_next_state <= S_01;
                            else
                                new_out_1_next <= '1';
                                new_out_2_next <= '0';
                                conv_next_state <= S_11;
                            end if;
                          
                        when S_11 =>
                            if (signal_out = '0') then
                                new_out_1_next <= '1';
                                new_out_2_next <= '0';
                                conv_next_state <= S_01;
                            else
                                new_out_1_next <= '0';
                                new_out_2_next <= '1';
                                conv_next_state <= S_11;
                            end if;
                            
                    end case;
                    o_address_next <= o_address_copy;
                    next_state <= DESERIALIZE_NUM;
    
                when DESERIALIZE_NUM =>
                     new_number_next(j) <= new_out_1;
                     new_number_next(j-1) <= new_out_2;
                     j_next <= j-2;
                     if ( j>2 ) then
                          o_address_next <= o_address_copy;
                          next_state <= SERIALIZE_NUM;
                            
                      else
                          o_address_next <= std_logic_vector("0000001111101000" + to_unsigned(count_write,16));
                          o_en_next <= '1';
                          o_we_next <= '1';
                          o_data_next <= new_number;
                          next_state <= WRITE_MEM_WAIT;
                      end if;
         
                when WRITE_MEM_WAIT =>
                    o_address_next <= o_address_copy; 
                    o_en_next <= '1';
                    o_we_next <= '1';
                    o_data_next <= new_number;
                    next_state <= WRITE_MEM;
                
                when WRITE_MEM =>
                    o_en_next <= '1';
                    j_next <= 7;
                    count_write_next <= count_write+1;
                    o_address_next <= std_logic_vector("0000000000000001" + to_unsigned(count_read,16));
                    next_return_state <= SERIALIZE_NUM;
                    next_state <= READ_MEM_WAIT;
    
                when DONE =>
                    if (i_start = '0') then                                 
                        next_state <= IDLE;
                     else
                        next_state <= DONE;
                    end if;
                    
            end case;
        
    end process;

end Behavioral;