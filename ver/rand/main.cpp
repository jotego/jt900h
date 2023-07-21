#include "emu.hpp"
#include <fstream>
#include "UUT.h"
#include "UUT_jt900h.h"
#include "UUT_jt900h_regs.h"

using namespace std;

int make_imm( int len, uint8_t *p ) {
    switch(len) {
    case 0: *p=rand(); return 1;
    case 1: *p++=rand(); *p=rand(); return 2;
    case 2: *p++=rand(); *p++=rand(); *p++=rand(); *p=rand(); return 4;
    }
    return 0;
}

void fill( Mem& m, int bank ) {
    enum { _11zz1rrrr } opbyte1;
    uint8_t *p = m.p + (bank<<16);
    for( int k=0; k<0x1'0000; ) {
        uint8_t op[12];
        int op_len=0;
        // 1st byte
        while(true) {
            op[op_len] = (uint8_t)rand();
            if( MASKCP(op[op_len],0xc8) ) {
                // 11zz-1rrr
                if( MASKCP(op[op_len],0x30) ) {
                    // unsupported for now
                    continue;
                }
                op_len++;
                break;
            }
        }
        // second byte
        int len=0;
        if( MASKCP(op[0],0xc8) ) {
            if( !MASKCP2(op[0],0x30,0x30) ) {
                len=(op[0]>>4)&3;
                while(true) {
                    op[op_len] = (char)rand();
                    if( MASKCP2(op[op_len],0xF8,0x88) ) { op_len++; break; } // LD R,r
                    if( op[op_len]==3 ) { // LD r,#
                        op_len++;
                        op_len+=make_imm(len, &op[op_len] );
                        break;
                    }
                }
            }
        }
        // copy to memory
        if( op_len+k > 0x1'0000 ) break;
        memcpy( p+k, op, op_len );
        k+=op_len;
    }
}

void dump( Mem& m ) {
    ofstream of("mem.bin", ios_base::binary);
    of.write( (const char*)m.p,0x10'00000);
}

void show( T900H& c, Mem &m, uint32_t old_pc, int fetched ) {
    printf("PC=%08X XWA0=%08X XBC0=%08X XDE0=%08X XHL0=%08X XIX=%08X XIY=%08X XIZ=%08X XSP=%08X  ",
        c.pc.q, c.xwa.q, c.xbc.q, c.xde.q, c.xhl.q,
        c.xix.q, c.xiy.q, c.xiz.q, c.xsp.q );
    for( ; fetched--; ) {
        printf("%02X", m.Rd8(old_pc++) );
    }
    putchar('\n');
}

void clock(UUT& uut, int times) {
    while( times-->0 ) {
        uut.clk=0;
        uut.cen=0;
        uut.eval();
        uut.clk=1;
        uut.eval();
        uut.clk=0;
        uut.cen=1;
        uut.eval();
        uut.clk=1;
        uut.eval();
    }
}

void reset(UUT& uut) {
    uut.rst = 1;
    clock(uut,4);
    uut.rst = 0;
}

bool cmp( UUT& uut, T900H& emu ) {
    bool equal = true;
    if( uut.jt900h->u_regs->__PVT__xix != emu.xix.q ) { equal=false; printf("> xix=%08X-%08X ",uut.jt900h->u_regs->__PVT__xix,emu.xix.q); }
    if( !equal ) putchar('\n');
    return equal;
}

int main(int argc, char *argv[]) {
    T900H cpu;
    Mem m;
    VerilatedContext context;
    context.commandArgs(argc, argv);

    try{
        UUT uut{&context};
        reset(uut);
        srand(0);
        int rom_bank=0xff;
        //do { rom_bank = rand() % 0x100; } while( rom_bank==0 ); // bank 0 is the default
        // for the stack, leave it alone for now
        fill( m, rom_bank );
        // Set PC start at reset
        m.p[0xffff00]= 0; //rom_bank<<16;
        m.p[0xffff01]= 0;
        m.p[0xffff02]= 0xff;
        m.p[0xffff03]= 0;
        dump(m);
        uint32_t end = (rom_bank<<16) | 0x0080;
        cpu.Reset(m);
        while( cpu.pc.q<end ) {
            auto pc_old = cpu.pc.q;
            auto fetched = cpu.Exec( m );
            show(cpu, m, pc_old, fetched);
            if( !cmp(uut, cpu) ) {
                printf("JT900H and the CPU model diverged\n");
                break;
           }
        }
    } catch( const char *error ) {
        fputs(error,stderr);
        fputc('\n',stderr);
        return 1;
    }
    return 0;
}