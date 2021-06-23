#include "jt900h.h"

int main() {
    TLCS900 dut; // Device Under Test - UUT Unit Under Test
    char mem[0x400000]; // 4MB


    TLCS900_reset( &dut );
    for( int k=0; k<10000; k++ ) {
        TLCS900_clkedge( &dut );
        if( !dut.RDn ) {
            dut.Din = mem[ dut.A ];
        }
        if( !dut.WRn ) {
            mem[ dut.A ] = dut.Dout;
        }
    }
    return 0;
}