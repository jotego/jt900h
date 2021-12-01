//JT900H header
//TLCS-900H based
#include <stdint.h>

struct TLCS900H_Pins{
    // inputs
    int clk, cen, din, rst;

    // outputs
    int cpu_cen, rd, addr, dout,
        wr, dsn;    // low/high byte write

    // last state
    int clk_last;
};

struct TLCS900H_Regs{
    union {
        uint8_t  bgr[0x40]; // general registers, banks 0-3
        uint16_t wgr[0x20];
        uint32_t qgr[0x10];
    };
    union {
        uint8_t  bsr[0x10]; // special registers
        uint16_t wsr[0x8];
        uint32_t qsr[0x4];
    };
    uint32_t pc;
};

struct TLCS900 {
    struct TLCS900H_Pins pins;
    struct TLCS900H_Regs regs;
    enum { reset=0, normal, irq } state;
    // Pipeline registers
    uint16_t bufin;

    // clock divider
    int cen_div;
    int rst_st;
    int norm_st;
    int irq_st;
};

void TLCS_eval(struct TLCS900 *cpu);