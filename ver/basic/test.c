#include "jt900h.h"
#include <stdio.h>

int main() {
    struct TLCS900 dut; // Device Under Test - UUT Unit Under Test
    unsigned char mem[0x400000]; // 4MB
    int MAXMEM=0x3FFFFF;

    TLCS_reset( &dut );
    // Reset vector falls beyond the allocated 4MB
    // so we gate the address to avoid a segment violation error
    mem[0xffff00 & MAXMEM] = 0xfe;
    mem[0xffff01 & MAXMEM] = 0xca;
    mem[0xffff02 & MAXMEM] = 0x77;

    printf("X1  RESETn  CLK        A        PC   Din  \n");
    for( int k=0; k<24; k++ ) {
        dut.pins.X1 = 1-dut.pins.X1; // X1 clock
        dut.pins.RESETn = k<4 ? 0 : 1;

        if( !dut.pins.RDn ) {
            dut.pins.Din = mem[ (dut.pins.A+1) & MAXMEM ];
            dut.pins.Din <<=8;
            dut.pins.Din |= mem[  dut.pins.A    & MAXMEM ];
        }

        TLCS_eval( &dut );
        printf("%d     %d     %d    %8x   %8x  %2x\n",
            dut.pins.X1, dut.pins.RESETn, dut.pins.CLK, dut.pins.A,
            dut.regs.pc, dut.pins.Din&0xffff );
    }
    return 0;
}