# Diagrama de bloques del proyecto Pong

El siguiente diagrama resume la arquitectura general del proyecto: entradas físicas de la Nexys A7-100T, sincronización y antirrebote, SoC MicroBlaze V, bus AXI, framebuffer, pipeline VGA, salidas físicas, DDR2, MicroSD y comunicación SPI inter-FPGA.

![Diagrama de bloques del proyecto Pong](docs/diagrama_bloques.png)

## Versión simplificada en Mermaid

```mermaid
flowchart LR
    A[Entradas físicas\nNexys A7-100T\nCLK100MHz, reset, SW0, botones] --> B[Sincronización y antirrebote\nDebounce.v + Sync_signal.v]
    B --> C[SoC MicroBlaze V\nCPU principal + LMB BRAM 64 KB]
    C --> D[AXI Interconnect\nBus interno del SoC]

    D --> E[GPIO entradas]
    D --> F[GPIO salidas\nLED]
    D --> G[BRAM Controller\nFramebuffer]
    D --> H[SPI Inter-FPGA\nModo 2 jugadores]
    D --> I[SPI MicroSD\nCarga de sprites]
    D --> J[UART Lite\nDiagnóstico]
    D --> K[DDR2 Controller\nSprites y assets]

    G --> L[Framebuffer BRAM]
    L --> M[Port B 32 bits\nVideo del pipeline]
    M --> N[Selector_nibble]
    N --> O[Paleta 4bpp a RGB 12-bit]
    O --> P[Pixel_mux.v]
    P --> Q[VGA_controller.v]
    Q --> R[Salida VGA\nVGA_R, VGA_G, VGA_B, HS, VS]

    S[Reloj y habilitación\nDiv_frec.v] --> Q
    K --> T[DDR2 128 MB\nSprites: ball, paddle, logo, gameover, menú, pausa]
    I --> T
    H --> U[FPGA Maestro / Esclavo\nMOSI, MISO, SCLK, CS, handshake]
```
