//JT900H main
//TLCS-900H based

// Stages:
// 1. Fetch instruction
// 2. Decode and fetch operands
// 3. Execute
// 4. Write result

#include <string.h>
#include "jt900h.h"

#define BSP 12
#define WSP 6
#define QSP 3

void TLCS_eval(struct TLCS900 *cpu) {
    if( cpu->pins.rst ) {
        cpu->state = reset;
        cpu->pins.dsn  = 0;
        cpu->pins.wr   = 0;
        cpu->pins.rd   = 0;
        cpu->regs.pc   = 0x8000;
        cpu->regs.qsr[QSP]  = 0x100;
        cpu->rst_st    = 0;
    } else if( cpu->pins.clk && !cpu->pins.clk_last ) { // positive edge, clock gated
        if( cpu->pins.cen ) {
            cpu->cen_div = 1-cpu->cen_div;

            switch( cpu->state ) {
                case reset:
                    if( cpu->cen_div ) { // rise edge
                        cpu->pins.A = cpu->rst_st>1 ? 0xffff02 : 0xffff00;
                    }
                    if( !cpu->cen_div ) { // fall edge
                        cpu->pins.rd = 0;
                        switch( cpu->rst_st ) {
                        case 1:
                            cpu->regs.pc = cpu->pins.din;
                            break;
                        case 3:
                            cpu->regs.pc |= cpu->pins.din<<16; // PC = PC | (Din << 16) 16 lower bits unaffected
                            cpu->state = normal;
                            cpu->pins.rd = 1;
                            break;
                        }
                        cpu->rst_st++;
                    }
                    break;
                case normal:
                    // stage 1, fetch instruction
                    cpu->bufin = cpu->pins.din;
                    // stage 2, decode
                    switch( cpu->bufin ) {

                    }
                    break;
                case irq:
                    break;
            }
        }
        cpu->pins.cpu_cen = cpu->cen_div & cpu->pins.cen;
    }
    // Keep values
    cpu->pins.clk_last = cpu->pins.clk & 1;
}