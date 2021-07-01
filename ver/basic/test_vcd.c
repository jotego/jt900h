#include "jt900h.h"
#include <stdio.h>

/*

Cambiar mem a 64kB solo (ajustar MAXMEM)
Cargar en mem el fichero ngp_bios.ngp

pasar volcado VCD a dump_vcd

Secuencia de reset en NGP

*/

void dump_bin( int v, int w, char* symbol) {
    int mask=1<< (w-1); // b100000000 bit w-1 = 1, others 0
    printf("b");
    while( w-->0 ) { // w post-decrement
        putchar( v&mask ? '1' : '0' );
        v<<=1;
    }
    printf(" %s\n",symbol);
}

int main() {
    struct TLCS900 dut, dut_last; // Device Under Test - UUT Unit Under Test
    unsigned char mem[0x400000]; // 4MB
    int MAXMEM=0x3FFFFF;

    memset( &dut_last, 0, sizeof(dut_last) );
    TLCS_reset( &dut );
    // Reset vector falls beyond the allocated 4MB
    // so we gate the address to avoid a segment violation error
    mem[0xffff00 & MAXMEM] = 0xfe;
    mem[0xffff01 & MAXMEM] = 0xca;
    mem[0xffff02 & MAXMEM] = 0x77;

    printf("$date \n"
    "    Date text\n"
    "$end\n"
    "$version\n"
    "    VCD generator tool\n"
    "$end\n"
    "$comment\n"
    "    Version from C\n"
    "$end\n"
    "$timescale 1ns $end\n"
    "$scope module reset $end\n"
    "$var  wire 1 x	X1	 $end\n"
    "$var  wire 1 r	RESETn	 $end\n"
    "$var  wire 1 c	CLK	 $end\n"
    "$var  wire 24 a A[23:0]	 $end\n"
    "$var  wire 32 p PC[31:0]  $end\n"
    "$var  wire 16 d Din[15:0] $end\n"
    "$upscope $end\n"
    "$enddefinitions $end\n"
    "$dumpvars\n"
    "0x\n"
    "0r\n"
    "0c\n"
    "bx a\n"
    "b1000000000000000 p\n"
    "bx d\n");

    for( int k=0; k<24; k++ ) {

        dut.pins.X1 = 1-dut.pins.X1; // X1 clock
        dut.pins.RESETn = k<4 ? 0 : 1;

        if( !dut.pins.RDn ) {
            dut.pins.Din = mem[ (dut.pins.A+1) & MAXMEM ];
            dut.pins.Din <<=8; // Left shift by 8 bits
            dut.pins.Din |= mem[  dut.pins.A    & MAXMEM ];
        } else {
            dut.pins.Din = 0xFFFF;
        }

        TLCS_eval( &dut );
        // dump_vcd

/*
        printf("#%d\n", k);
        
        printf("%dx\n", dut.pins.X1);
        if( dut_last.pins.RESETn != dut.pins.RESETn){
            printf("%dr\n", dut.pins.RESETn);
        }
          
        if( dut_last.pins.CLK != dut.pins.CLK){
            printf("%dc\n", dut.pins.CLK);
        }
        
        if( dut_last.pins.A != dut.pins.A ) {
            dump_bin( dut.pins.A, 24, "a" );
        }

        if( dut_last.regs.pc = dut.regs.pc ) {
            dump_bin( dut.regs.pc, 32, "p" );
        }

        if( dut_last.pins.Din != dut.pins.Din ) {
            dump_bin( dut.pins.Din, 16, "d" );
        }
        */
        dut_last = dut;
    }
    return 0;
}

