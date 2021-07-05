#include "jt900h.h"
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
/*

Cargar en mem el fichero ngp_bios.ngp (terminar)


Movimiento de los buses en el codigo
*/

void dump_bin( int v, int w, char* symbol, FILE *fpvcd) {
    
    int mask=1<< (w-1); // b100000000 bit w-1 = 1, others 0
    fprintf(fpvcd, "b");
    while( w-->0 ) { // w post-decrement
        fputc(v&mask ? '1' : '0', fpvcd);
        v<<=1;
    }
    fprintf(fpvcd, " %s\n",symbol);
}

void dump_vcd(int k, struct TLCS900 dut, struct TLCS900 dut_last, FILE *fpvcd){
    //Generate data for a .VCD file.

        fprintf(fpvcd, "#%d\n", k);
        
        fprintf(fpvcd, "%dx\n", dut.pins.X1);
        
        if( dut_last.pins.RESETn != dut.pins.RESETn){
            fprintf(fpvcd, "%dr\n", dut.pins.RESETn);
        }
          
        if( dut_last.pins.CLK != dut.pins.CLK){
            fprintf(fpvcd, "%dc\n", dut.pins.CLK);
        }
        
        if( dut_last.pins.A != dut.pins.A ) {
            dump_bin( dut.pins.A, 24, "a", fpvcd );
        }

        if( dut_last.regs.pc != dut.regs.pc ) {
            dump_bin( dut.regs.pc, 32, "p", fpvcd );
        }

        if( dut_last.pins.Din != dut.pins.Din ) {
            dump_bin( dut.pins.Din, 16, "d", fpvcd );
        }
        
        
}

void ngpbios_check(unsigned char mem[]){
    int n, ln;
    FILE *fpbios;
    fpbios = fopen("ngp_bios.ngp","rb");
    if(fpbios == NULL)
    {
        printf("Error opening file\n");
        exit(1);
    }
    printf("Testing fread() function: \n\n");

    for (n = 0, ln = 0; n < 16; n++, ln++){
        fread(mem, 1, 65536, fpbios);    
        if ( ln >= 16){
            ln = 0;
            printf("\n");
        } 
        printf("%02x ", mem[n]); 
    }
 
    fclose(fpbios);
}

int main() {
    struct TLCS900 dut, dut_last; // Device Under Test - UUT Unit Under Test
    unsigned char mem[0x10000]; // 64kB
    int MAXMEM=0xFFFF;

    memset( &dut_last, 0, sizeof(dut_last) );
    TLCS_reset( &dut );
    // Reset vector falls beyond the allocated 4MB
    // so we gate the address to avoid a segment violation error
    mem[0xffff00 & MAXMEM] = 0xfe;
    mem[0xffff01 & MAXMEM] = 0xca;
    mem[0xffff02 & MAXMEM] = 0x77;

    ngpbios_check(mem);

    FILE *fpvcd;
    fpvcd =fopen("dump_vcd.vcd", "w");
    
    fprintf(fpvcd, "$date \n"
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
    "bx d\n"
    "$end\n");
           
    if (fpvcd == NULL){
                printf("Error opening file (write)\n");
                exit(1);
            }
    
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
        dump_vcd(k, dut, dut_last, fpvcd);
        dut_last = dut;

    }
    fclose(fpvcd);
    return 0;
}

