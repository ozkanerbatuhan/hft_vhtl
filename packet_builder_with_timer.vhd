library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity packet_builder_with_timer is
    Generic (
        TIMER_WIDTH : integer := 32;  -- Zaman sayacı genişliği
        FIFO_DEPTH  : integer := 16   -- Kaç adet işlem üst üste gelebilir? (Pipeline derinliği)
    );
    Port (
        i_clk          : in  STD_LOGIC;
        i_reset_n      : in  STD_LOGIC;
        
        -- GİRİŞ: ANN'e veri girdiği an tetiklenecek
        i_start_trigger: in  STD_LOGIC;  -- "Veri geldi" sinyali (Parser'dan)
        
        -- GİRİŞ: ANN sonucu hazır olduğunda tetiklenecek
        i_ann_result   : in  STD_LOGIC;  -- ANN'in 1 veya 0 sonucu
        i_ann_done     : in  STD_LOGIC;  -- "Sonuç hazır" sinyali (ANN'den)
        
        -- ÇIKIŞ: Ethernet'e gönderilecek paketlenmiş veri
        o_tx_data      : out STD_LOGIC_VECTOR(31 downto 0); -- 32-bit veri çıkışı
        o_tx_valid     : out STD_LOGIC   -- "Paket hazır, gönder" sinyali
    );
end packet_builder_with_timer;

architecture Behavioral of packet_builder_with_timer is

    -- 1. Global Kronometre
    signal r_timer_counter : unsigned(TIMER_WIDTH-1 downto 0) := (others => '0');

    -- 2. T1 Zamanlarını tutmak için FIFO (Dairesel Buffer)
    -- Neden FIFO? Çünkü 1. veri çıkmadan 2. veri girebilir (Pipeline).
    type t_timestamp_array is array (0 to FIFO_DEPTH-1) of unsigned(TIMER_WIDTH-1 downto 0);
    signal r_timestamp_fifo : t_timestamp_array := (others => (others => '0'));
    
    signal r_head_ptr : integer range 0 to FIFO_DEPTH-1 := 0; -- Yazma ibresi
    signal r_tail_ptr : integer range 0 to FIFO_DEPTH-1 := 0; -- Okuma ibresi
    
    -- Hesaplama Sinyalleri
    signal r_latency  : unsigned(TIMER_WIDTH-1 downto 0);
    signal r_t1_read  : unsigned(TIMER_WIDTH-1 downto 0);

begin

    -- =========================================================================
    -- SÜREÇ 1: Global Timer (Sürekli Sayar)
    -- =========================================================================
    process(i_clk, i_reset_n)
    begin
        if i_reset_n = '0' then
            r_timer_counter <= (others => '0');
        elsif rising_edge(i_clk) then
            r_timer_counter <= r_timer_counter + 1;
        end if;
    end process;

    -- =========================================================================
    -- SÜREÇ 2: Giriş Yakalama (T1 Kaydı) ve Çıkış Hesaplama (T2 - T1)
    -- =========================================================================
    process(i_clk, i_reset_n)
    begin
        if i_reset_n = '0' then
            r_head_ptr   <= 0;
            r_tail_ptr   <= 0;
            o_tx_valid   <= '0';
            o_tx_data    <= (others => '0');
        elsif rising_edge(i_clk) then
            
            -- Varsayılan değerler
            o_tx_valid <= '0';

            -- A) YENİ GİRİŞ VARSA: Zamanı (T1) FIFO'ya yaz
            if i_start_trigger = '1' then
                r_timestamp_fifo(r_head_ptr) <= r_timer_counter;
                
                -- Dairesel artış (Wrap around)
                if r_head_ptr = FIFO_DEPTH-1 then
                    r_head_ptr <= 0;
                else
                    r_head_ptr <= r_head_ptr + 1;
                end if;
            end if;

            -- B) SONUÇ HAZIRSA: FIFO'dan T1'i çek ve farkı hesapla
            if i_ann_done = '1' then
                -- FIFO boş değilse işlem yap (Basit koruma)
                if r_head_ptr /= r_tail_ptr then
                    
                    -- 1. FIFO'nun sonundaki T1 zamanını oku
                    r_t1_read <= r_timestamp_fifo(r_tail_ptr);
                    
                    -- 2. Gecikmeyi hesapla (Şu an - T1)
                    -- Not: Unsigned çıkarma işlemi otomatik overflow yönetir, sorun olmaz.
                    r_latency <= r_timer_counter - r_timestamp_fifo(r_tail_ptr);
                    
                    -- 3. Paketi Hazırla (32 Bit Örneği)
                    -- [31: Result] [30...0: Latency]
                    -- En üst bite ANN sonucunu koyuyoruz, geri kalanı süre.
                    o_tx_data(31) <= i_ann_result;
                    o_tx_data(30 downto 0) <= std_logic_vector(r_latency(30 downto 0));
                    
                    o_tx_valid <= '1';

                    -- 4. Okuma ibresini ilerlet
                    if r_tail_ptr = FIFO_DEPTH-1 then
                        r_tail_ptr <= 0;
                    else
                        r_tail_ptr <= r_tail_ptr + 1;
                    end if;
                end if;
            end if;
            
        end if;
    end process;

end Behavioral;