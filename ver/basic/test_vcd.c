#include "jt900h.h"
#include <stdio.h>

void dump_bin( int v, int w, char* symbol) {
    int mask=1<< (w-1); // b100000000 bit w-1 = 1, others 0
    printf("b");
    while( w>0 ) {
        if( v & mask ) {
            printf("1");
        } else {
            printf("0");
        }
        v<<=1;
        w--;
    }
    printf(" %s\n",symbol);
}


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

    printf("$date \n");
    printf("    Date text\n");
    printf("$end\n");
    printf("$version\n");
    printf("    VCD generator tool\n");
    printf("$end\n");
    printf("$comment\n");
    printf("    Version from C\n");
    printf("$end\n");
    printf("$timescale 1ns $end\n");
    printf("$scope module reset $end\n");
    printf("$var  wire 1 x	X1	 $end\n");
    printf("$var  wire 1 r	RESETn	 $end\n");
    printf("$var  wire 1 c	CLK	 $end\n");
    printf("$var  wire 24 a A[23:0]	 $end\n");
    printf("$var  wire 32 p PC[31:0]  $end\n");
    printf("$var  wire 16 d Din[15:0] $end\n");
    printf("$upscope $end\n");
    printf("$enddefinitions $end\n");
    printf("$dumpvars\n");
    printf("0x\n");
    printf("0r\n");
    printf("0c\n");
    printf("bx a\n");
    printf("b1000000000000000 p\n");
    printf("bx d\n");
   
    int x = 0;
    int r = 0;
    int c = 0;
    int a = 0, p=0, d=0;

    for( int k=0; k<24; k++ ) {

        dut.pins.X1 = 1-dut.pins.X1; // X1 clock
        dut.pins.RESETn = k<4 ? 0 : 1;

        if( !dut.pins.RDn ) {
            dut.pins.Din = mem[ (dut.pins.A+1) & MAXMEM ];
            dut.pins.Din <<=8;
            dut.pins.Din |= mem[  dut.pins.A    & MAXMEM ];
        } else {
            dut.pins.Din = 0xFFFF;
        }

        TLCS_eval( &dut );

        printf("#%d\n", k);
        
        printf("%dx\n", dut.pins.X1);
        if(r != dut.pins.RESETn){
            r=dut.pins.RESETn;
            printf("%dr\n", dut.pins.RESETn);
        }
          
        if(c != dut.pins.CLK){
            c=dut.pins.CLK;
            printf("%dc\n", dut.pins.CLK);
        }
        
        if( a != dut.pins.A ) {
            a = dut.pins.A;
            dump_bin( a, 24, "a" );
        }

        if( p!= dut.regs.pc ) {
            p = dut.regs.pc;
            dump_bin( p, 32, "p" );
        }

        if( d != dut.pins.Din ) {
            d = dut.pins.Din;
            dump_bin( d, 16, "d" );
        }
    }
    return 0;
}

