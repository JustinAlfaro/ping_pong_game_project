// =============================================================================
// Top-level — Sistema Embebido Pong Multijugador
// Board  : Nexys A7-100T (XC7A100T-CSG324)
// Clocks : 100 MHz onboard oscillator → Clocking Wizard → MicroBlaze V
// =============================================================================
module top_pong_project (
    // --- Clock & Reset ---
    input  wire        CLK100MHZ,
    input  wire        CPU_RESETN,      // activo bajo

    // --- Botones (jugador) ---
    input  wire        BTNU,
    input  wire        BTND,
    input  wire        BTNC,
    input  wire        BTNL,
    input  wire        BTNR,

    // --- Switch modo 1P/2P ---
    input  wire        SW,              // SW[0] solamente

    // --- LEDs ---
    output wire [15:0] LED,

    // --- VGA ---
    output wire [3:0]  VGA_R,
    output wire [3:0]  VGA_G,
    output wire [3:0]  VGA_B,
    output wire        VGA_HS,
    output wire        VGA_VS,

    // --- UART (USB-UART integrado Nexys A7) ---
    input  wire        UART_RXD_OUT,   // D4 : USB→FPGA (RX del FPGA)
    output wire        UART_TXD_IN,    // C4 : FPGA→USB (TX del FPGA)

    // --- SPI inter-FPGA (pines PMOD por confirmar con otro grupo) ---
    output wire        SPI_SCK,
    output wire        SPI_MOSI,
    input  wire        SPI_MISO,
    output wire        SPI_CS_N,

    // --- DDR2 SDRAM (MT47H64M16HR-25E) ---
    inout  wire [15:0] ddr2_dq,
    inout  wire [1:0]  ddr2_dqs_p,
    inout  wire [1:0]  ddr2_dqs_n,
    output wire [12:0] ddr2_addr,
    output wire [2:0]  ddr2_ba,
    output wire        ddr2_ras_n,
    output wire        ddr2_cas_n,
    output wire        ddr2_we_n,
    output wire [0:0]  ddr2_ck_p,
    output wire [0:0]  ddr2_ck_n,
    output wire [0:0]  ddr2_cke,
    output wire [0:0]  ddr2_cs_n,
    output wire [1:0]  ddr2_dm,
    output wire [0:0]  ddr2_odt
);

// -----------------------------------------------------------------------------
// Señales internas SPI (AXI Quad SPI — modo master standard)
// -----------------------------------------------------------------------------
wire spi_io0_i, spi_io0_o, spi_io0_t;
wire spi_io1_i, spi_io1_o, spi_io1_t;
wire spi_sck_i, spi_sck_o, spi_sck_t;
wire [0:0] spi_ss_i, spi_ss_o;
wire spi_ss_t;

// En modo master: SCK, MOSI y CS son salidas; MISO es entrada
assign SPI_SCK   = spi_sck_o;
assign SPI_MOSI  = spi_io0_o;
assign SPI_CS_N  = spi_ss_o[0];
assign spi_io1_i = SPI_MISO;
assign spi_io0_i = 1'b0;
assign spi_sck_i = 1'b0;
assign spi_ss_i  = 1'b1;

// DDR2 calibration status (conectar a LED[15] como indicador de arranque)
wire ddr2_calib_done;
assign LED[15] = ddr2_calib_done;

// -----------------------------------------------------------------------------
// Instancia del Block Design MicroBlaze V SoC
// -----------------------------------------------------------------------------
microblaze_v_wrapper u_soc (
    // Reloj y reset
    .clk_100MHz            (CLK100MHZ),
    .reset_rtl_0           (CPU_RESETN),

    // DDR2 calibración completada
    .init_calib_complete_0 (ddr2_calib_done),

    // GPIO0 — botones [4:0] = {BTNR, BTNL, BTNC, BTND, BTNU}
    .gpio_rtl_0_tri_i      ({BTNR, BTNL, BTNC, BTND, BTNU}),

    // GPIO1 — SW[0] (modo 1P/2P)
    .gpio_rtl_1_tri_i      (SW),

    // GPIO2 — LEDs [14:0] (LED[15] reservado para DDR2 calib)
    .gpio_rtl_2_tri_o      (LED[14:0]),

    // UART
    .uart_rtl_0_rxd        (UART_RXD_OUT),
    .uart_rtl_0_txd        (UART_TXD_IN),

    // SPI
    .spi_rtl_0_io0_i       (spi_io0_i),
    .spi_rtl_0_io0_o       (spi_io0_o),
    .spi_rtl_0_io0_t       (spi_io0_t),
    .spi_rtl_0_io1_i       (spi_io1_i),
    .spi_rtl_0_io1_o       (spi_io1_o),
    .spi_rtl_0_io1_t       (spi_io1_t),
    .spi_rtl_0_sck_i       (spi_sck_i),
    .spi_rtl_0_sck_o       (spi_sck_o),
    .spi_rtl_0_sck_t       (spi_sck_t),
    .spi_rtl_0_ss_i        (spi_ss_i),
    .spi_rtl_0_ss_o        (spi_ss_o),
    .spi_rtl_0_ss_t        (spi_ss_t),

    // DDR2
    .DDR2_0_dq             (ddr2_dq),
    .DDR2_0_dqs_p          (ddr2_dqs_p),
    .DDR2_0_dqs_n          (ddr2_dqs_n),
    .DDR2_0_addr           (ddr2_addr),
    .DDR2_0_ba             (ddr2_ba),
    .DDR2_0_ras_n          (ddr2_ras_n),
    .DDR2_0_cas_n          (ddr2_cas_n),
    .DDR2_0_we_n           (ddr2_we_n),
    .DDR2_0_ck_p           (ddr2_ck_p),
    .DDR2_0_ck_n           (ddr2_ck_n),
    .DDR2_0_cke            (ddr2_cke),
    .DDR2_0_cs_n           (ddr2_cs_n),
    .DDR2_0_dm             (ddr2_dm),
    .DDR2_0_odt            (ddr2_odt),

    // VRAM Port B (VGA lee píxeles directamente)
    .BRAM_PORTB_0_addr     (vram_portb_addr),
    .BRAM_PORTB_0_clk      (vram_portb_clk),
    .BRAM_PORTB_0_din      (vram_portb_din),
    .BRAM_PORTB_0_dout     (vram_portb_dout),
    .BRAM_PORTB_0_en       (vram_portb_en),
    .BRAM_PORTB_0_rst      (vram_portb_rst),
    .BRAM_PORTB_0_we       (vram_portb_we)
);

// -----------------------------------------------------------------------------
// VRAM Port B — señales internas hacia subsistema VGA
// MicroBlaze escribe por Port A (AXI), VGA lee por Port B
// -----------------------------------------------------------------------------
wire [31:0] vram_portb_addr;
wire        vram_portb_clk;
wire [31:0] vram_portb_din;
wire [31:0] vram_portb_dout;
wire        vram_portb_en;
wire        vram_portb_rst;
wire [3:0]  vram_portb_we;

// TODO: conectar vram_portb_* a vga_controller / bram_dualport del Proyecto 1
assign vram_portb_clk  = CLK100MHZ;
assign vram_portb_addr = 32'h0;
assign vram_portb_din  = 32'h0;
assign vram_portb_en   = 1'b0;
assign vram_portb_rst  = 1'b0;
assign vram_portb_we   = 4'b0;

// -----------------------------------------------------------------------------
// Subsistema VGA (módulos Proyecto 1 — TODO: integrar)
// -----------------------------------------------------------------------------
assign VGA_R  = 4'h0;
assign VGA_G  = 4'h0;
assign VGA_B  = 4'h0;
assign VGA_HS = 1'b1;
assign VGA_VS = 1'b1;

endmodule
