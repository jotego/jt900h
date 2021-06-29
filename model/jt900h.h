//JT900H header
//TLCS-900H based
#include <stdint.h>

struct TLCS900H_Pins{
    // inputs
    int X1, Din, WAITn, RESETn;

    // outputs
    int CLK, RD, A, Dout,
        WRn, HWRn,  // low/high byte write
        ALE,        // Address Latch Enable
        CSn;        // CS[2:0]

    // last state
    int X1_last;
};

struct TLCS900H_Registers{
    uint32_t xwa[4], xbc[4], xde[4], xhl[4];
    uint32_t dmas[4], dmad[4], dmac[4],dmam[4];
    uint32_t xix, xiy, xiz, xsp, pc;
    uint16_t sr, intnest;
    uint8_t f[2];
};

struct TLCS900 {
    struct TLCS900H_Pins pins;
    struct TLCS900H_Registers regs;
    enum { reset=0, normal, irq } state;
};

void TLCS_reset(struct TLCS900 *cpu);
void TLCS_eval(struct TLCS900 *cpu);