#include "jt900h.h"
#include <stdio.h>

int main() {
    struct TLCS900 dut; // Device Under Test - UUT Unit Under Test
    char mem[0x400000]; // 4MB


    TLCS_reset( &dut );

    printf("X1  RESETn CLK  \n");
    for( int k=0; k<20; k++ ) {
        dut.pins.X1 = 1-dut.pins.X1; // X1 clock
        dut.pins.RESETn = k<4 ? 0 : 1;
        TLCS_eval( &dut );
        printf("%d     %d      %d\n",
            dut.pins.X1, dut.pins.RESETn, dut.pins.CLK );
    }
    return 0;
}