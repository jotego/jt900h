#include "jt900h.h"
#include <stdio.h>
#define MAX 1000
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
    printf("$var  wire 32 a A[31:0]	 $end\n");
    printf("$var  wire 32 p PC[31:0]  $end\n");
    printf("$var  wire 32 d Din[31:0] $end\n");
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
        

           
       
       
        
        //printf("%8x\n", dut.pins.A);

        /*printf("%d     %d     %d    %8x   %8x  %2x\n",
            dut.pins.X1, dut.pins.RESETn, dut.pins.CLK, dut.pins.A,
            dut.regs.pc, dut.pins.Din&0xffff );*/

   
    }
    return 0;


 
}

