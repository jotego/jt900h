//JT900H main
//TLCS-900H based

#include <string.h>
#include "jt900h.h"

void TLCS_reset(struct TLCS900 *cpu){
    cpu->pins.HWRn = 1;
    cpu->pins.WRn  = 1;
    cpu->pins.A    = 0;
    cpu->pins.RDn  = 1;
    cpu->pins.RASn = 1;
    cpu->pins.CASn = 1;
    // ...
    // Set all registers to zero
    memset( &cpu->regs, 0, sizeof(cpu->regs) );
}

void TLCS_eval(struct TLCS900 *cpu) {
    if( !cpu->pins.RESETn ) {
        cpu->state = reset;
        cpu->pins.HWRn = 1;
        cpu->pins.WRn  = 1;
        cpu->pins.RDn  = 1;
        cpu->pins.RASn = 1;
        cpu->pins.CASn = 1;
        cpu->regs.pc   = 0x8000;
        cpu->regs.xsp  = 0x100;
        cpu->rst_st    = 0;
    } else if( !cpu->pins.X1 && cpu->pins.X1_last ) { // negative edge
        cpu->pins.CLK_last = cpu->pins.CLK;
        cpu->pins.CLK = (~cpu->pins.CLK)&1; // generate output clock
        
        switch( cpu->state ) {
            case reset: 
                if( !cpu->pins.CLK_last && cpu->pins.CLK ) { // rise edge
                    cpu->pins.A = cpu->rst_st>1 ? 0xffff02 : 0xffff00;
                }
                if( cpu->pins.CLK_last && !cpu->pins.CLK ) { // fall edge
                    cpu->pins.RDn = 0;
                    switch( cpu->rst_st ) {
                    case 1:
                        cpu->regs.pc = cpu->pins.Din;
                        break;
                    case 3:
                        cpu->regs.pc |= cpu->pins.Din<<16; // PC = PC | (Din << 16) 16 lower bits unaffected
                        cpu->state = normal;
                        cpu->pins.RDn = 1;
                        break;
                    }
                    cpu->rst_st++;
                }
                break;
            case normal:
                break;
            case irq:
                break;
        }
    }
    // Keep values
    cpu->pins.X1_last = cpu->pins.X1 & 1;
}