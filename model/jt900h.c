//JT900H main
//TLCS-900H based

#include <string.h>
#include "jt900h.h"

void TLCS_reset(struct TLCS900 *cpu){
    cpu->pins.HWRn = 1;
    cpu->pins.WRn  = 1;
    cpu->pins.A    = 0xffff00;
    // ...
    // Set all registers to zero
    memset( &cpu->regs, 0, sizeof(cpu->regs) );
}

void TLCS_eval(struct TLCS900 *cpu) {
    if( !cpu->pins.RESETn ) {
        cpu->state = reset;
        cpu->pins.HWRn = 1;
        cpu->pins.WRn  = 1;
    } else {
        if( !cpu->pins.X1 && cpu->pins.X1_last ) { // negative edge
            cpu->pins.CLK = (~cpu->pins.CLK)&1;
        }
    }
    // Keep values
    cpu->pins.X1_last = cpu->pins.X1 & 1;
}