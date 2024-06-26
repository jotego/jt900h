#include "emu.hpp"
#include <fstream>
#include "UUT.h"
#include "UUT_jt900h.h"
#include "UUT_jt900h_regs.h"
#include "verilated_vcd_c.h"

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
            // single byte instructions
            if( op[op_len]==0x10 || // RCF
                op[op_len]==0x11 || // SCF
                op[op_len]==0x12 || // CCF
                op[op_len]==0x13 || // ZCF
                op[op_len]==0x16 || // EX F,F'
                //op[op_len]==0x18 || // PUSH F
                // op[op_len]==0x19 || // POP F
                op[op_len]==0x0c || // INCF
                op[op_len]==0x0d    // DECF
            ) { op_len++; break; }
        }
        // second byte
        int len=0;
        if( MASKCP(op[0],0xc8) ) {
            if( !MASKCP2(op[0],0x30,0x30) ) {
                len=(op[0]>>4)&3;
                while(true) {
                    op[op_len] = (char)rand();
                    if( MASKCP2(op[op_len],0xF0,0x70) && (op[0]&0x20)==0 ) { op_len++; break; } // SCC cc,r
                    if( MASKCP2(op[op_len],0xF8,0x40) && (op[0]&0x20)==0 ) { op_len++; break; } // MUL RR,r
                    if( MASKCP2(op[op_len],0xF8,0x48) && (op[0]&0x20)==0 ) { op_len++; break; } // MULS RR,r
                    if( MASKCP2(op[op_len],0xF8,0xB8) && (op[0]&0x20)==0 ) { op_len++; break; } // EX R,r
                    if( MASKCP2(op[op_len],0xF8,0xD8) && (op[0]&0x20)==0 ) { op_len++; break; } // CP r,#3
                    if( MASKCP2(op[op_len],0xF8,0x60) ) { op_len++; break; } // INC #3,r
                    if( MASKCP2(op[op_len],0xF8,0x68) ) { op_len++; break; } // DEC #3,r
                    if( MASKCP2(op[op_len],0xF8,0x80) ) { op_len++; break; } // ADD R,r
                    if( MASKCP2(op[op_len],0xF8,0x88) ) { op_len++; break; } // LD R,r
                    if( MASKCP2(op[op_len],0xF8,0x98) ) { op_len++; break; } // LD r,R
                    if( MASKCP2(op[op_len],0xF8,0xA8) ) { op_len++; break; } // LD r,#3
                    if( MASKCP2(op[op_len],0xF8,0x90) ) { op_len++; break; } // ADC R,r
                    if( MASKCP2(op[op_len],0xF8,0xA0) ) { op_len++; break; } // SUB R,r
                    if( MASKCP2(op[op_len],0xF8,0xB0) ) { op_len++; break; } // SBC R,r
                    if( MASKCP2(op[op_len],0xF8,0xC0) ) { op_len++; break; } // AND R,r
                    if( MASKCP2(op[op_len],0xF8,0xD0) ) { op_len++; break; } // XOR R,r
                    if( MASKCP2(op[op_len],0xF8,0xE0) ) { op_len++; break; } // OR R,r
                    if( MASKCP2(op[op_len],0xF8,0xF0) ) { op_len++; break; } // CP R,r
                    // if( MASKCP2(op[op_len],0xF8,0x50) && (op[0]&0x20)==0) { op_len++; break; } // DIV RR,r

                    if( op[op_len]==0x06 && (op[0]&0x20)==0 ) { op_len++; break; } // CPL r
                    if( op[op_len]==0x07 && (op[0]&0x20)==0 ) { op_len++; break; } // NEG r
                    //if( op[op_len]==0x28 && (op[0]&0x20)==0 ) { op_len++; break; } // ANDCF A,r
                    if( op[op_len]==0x12 ) { op_len++; break; } // EXTZ r
                    if( op[op_len]==0x13 ) { op_len++; break; } // EXTS r
                    if( op[op_len]==0x14 ) { op_len++; break; } // PAA r
                    if( op[op_len]==0xF8 ) { op_len++; break; } // RLC A,r
                    if( op[op_len]==0xF9 ) { op_len++; break; } // RRC A,r
                    if( op[op_len]==0xFA ) { op_len++; break; } // RL A,r
                    if( op[op_len]==0xFB ) { op_len++; break; } // RR A,r
                    if( op[op_len]==0xFC ) { op_len++; break; } // SLA A,r
                    if( op[op_len]==0xFD ) { op_len++; break; } // SRA A,r
                    if( op[op_len]==0xFE ) { op_len++; break; } // SLL A,r
                    if( op[op_len]==0xFF ) { op_len++; break; } // SRL A,r

                    if( op[op_len]==0x03 ||     // LD r,#
                        op[op_len]==0xC8 ||     // ADD r,#
                        op[op_len]==0xC9 ||     // ADC r,#
                        op[op_len]==0xCA ||     // SUB r,#
                        op[op_len]==0xCB ||     // SBC r,#
                        op[op_len]==0xCC ||     // AND r,#
                        op[op_len]==0xCD ||     // XOR r,#
                        op[op_len]==0xCE ||     // OR r,#
                        op[op_len]==0xCF ) {    // CP r,#
                            op_len++;
                            op_len+=make_imm(len, &op[op_len] );
                            break;
                    }
                    if(( op[op_len]==0x20 ||    // ANDCF #4,r
                         op[op_len]==0x21 ||    // ORCF #4,r
                         op[op_len]==0x22 ||    // XORCF #4,r
                         op[op_len]==0x23 ||    // LDCF #4,r
                         op[op_len]==0x24 ||    // STCF #4,r
                         op[op_len]==0x30 ||    // RES #4,r
                         op[op_len]==0x31 ||    // SET #4,r
                         op[op_len]==0x32 ||    // CHG #4,r
                         op[op_len]==0x33 ||    // BIT #4,r
                         op[op_len]==0x34 )     // TSET #4,r
                        && (op[0]&0x20)==0) {
                            op_len++;
                            if ( !len )
                                op[op_len] = ((char)rand()&0x07);
                            else
                                op[op_len] = ((char)rand()&0x0f);
                            op_len++;
                            break;
                    }
                    if( op[op_len]==0xE8 ||     // RLC #4,r
                        op[op_len]==0xE9 ||     // RRC #4,r
                        op[op_len]==0xEA ||     // RL #4,r
                        op[op_len]==0xEB ||     // RR #4,r
                        op[op_len]==0xEC ||     // SLA #4,r
                        op[op_len]==0xED ||     // SRA #4,r
                        op[op_len]==0xEE ||     // SLL #4,r
                        op[op_len]==0xEF ) {    // SRL #4,r
                            op_len++;
                            op[op_len] = ((char)rand()&0x0f);
                            op_len++;
                            break;
                    }
                    if( MASKCP(op[0],0xd8) ) {
                        if( op[op_len]==0x0E ) { op_len++; break; } // BS1F r
                        if( op[op_len]==0x0F ) { op_len++; break; } // BS1B r
                        if( op[op_len]==0x16 ) { op_len++; break; } // MIRR r
                        if( op[op_len]==0x19 && (op[0]&7)!=3 ) { op_len++; break; } // MULA rr
                        if( op[op_len]==0x38 && (op[0]&0x20)==0 ||      // MINC1 #,r
                            op[op_len]==0x39 && (op[0]&0x20)==0 ||      // MINC2 #,r
                            op[op_len]==0x3A && (op[0]&0x20)==0 ||      // MINC4 #,r
                            op[op_len]==0x3C && (op[0]&0x20)==0 ||      // MDEC1 #,r
                            op[op_len]==0x3D && (op[0]&0x20)==0 ||      // MDEC2 #,r
                            op[op_len]==0x3E && (op[0]&0x20)==0 ) {     // MDEC4 #,r
                                op_len++;
                                op_len+=make_imm(len, &op[op_len] );
                                break;
                        }
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
        c.pc.q, c.rr[0].xwa.q, c.rr[0].xbc.q, c.rr[0].xde.q, c.rr[0].xhl.q,
        c.xix.q, c.xiy.q, c.xiz.q, c.xsp.q );
    for( ; fetched--; ) {
        printf("%02X", m.Rd8(old_pc++) );
    }
    putchar('\n');
}

vluint64_t simtime=0;
void clock(UUT& uut, Mem &m, VerilatedVcdC* tracer, int times) {
    times <<= 2;
    while( times-->0 ) {
        if(tracer) tracer->dump(simtime);
        uut.clk=1-uut.clk;
        if( uut.clk==0 ) {
            uut.cen=1-uut.cen;
            uut.din = m.Rd16(uut.addr<<1);
        }
        uut.eval();
        simtime += 5;
    }
}

void reset(UUT& uut, Mem &m, VerilatedVcdC* tracer) {
    uut.rst = 1;
    clock(uut, m, tracer, 4);
    uut.rst = 0;
}

bool cmp( UUT& uut, T900H& emu ) {
    if( uut.jt900h->u_regs->xwa0 != emu.rr[0].xwa.q ) return false;
    if( uut.jt900h->u_regs->xbc0 != emu.rr[0].xbc.q ) return false;
    if( uut.jt900h->u_regs->xde0 != emu.rr[0].xde.q ) return false;
    if( uut.jt900h->u_regs->xhl0 != emu.rr[0].xhl.q ) return false;

    if( uut.jt900h->u_regs->xwa1 != emu.rr[1].xwa.q ) return false;
    if( uut.jt900h->u_regs->xbc1 != emu.rr[1].xbc.q ) return false;
    if( uut.jt900h->u_regs->xde1 != emu.rr[1].xde.q ) return false;
    if( uut.jt900h->u_regs->xhl1 != emu.rr[1].xhl.q ) return false;

    if( uut.jt900h->u_regs->xwa2 != emu.rr[2].xwa.q ) return false;
    if( uut.jt900h->u_regs->xbc2 != emu.rr[2].xbc.q ) return false;
    if( uut.jt900h->u_regs->xde2 != emu.rr[2].xde.q ) return false;
    if( uut.jt900h->u_regs->xhl2 != emu.rr[2].xhl.q ) return false;

    if( uut.jt900h->u_regs->xwa3 != emu.rr[3].xwa.q ) return false;
    if( uut.jt900h->u_regs->xbc3 != emu.rr[3].xbc.q ) return false;
    if( uut.jt900h->u_regs->xde3 != emu.rr[3].xde.q ) return false;
    if( uut.jt900h->u_regs->xhl3 != emu.rr[3].xhl.q ) return false;

    if( uut.jt900h->u_regs->xix != emu.xix.q ) return false;
    if( uut.jt900h->u_regs->xiy != emu.xiy.q ) return false;
    if( uut.jt900h->u_regs->xiz != emu.xiz.q ) return false;
    if( uut.jt900h->u_regs->xsp != emu.xsp.q ) return false;

    if( uut.jt900h->rfp != emu.rfp ) return false;
    if( uut.jt900h->flags != emu.flags ) return false;
    return true;
}


void show_comp( UUT& uut, T900H& emu ) {
    #define PCMP(s,a,b) printf( s ":%08X (%08X)%c  ", a.q, b, a.q!=b ? '*' : ' ' );
    #define PCFL(s,a,b) printf( s ":%02X (%02X)%c  ", a, b, a!=b ? '*' : ' ' );
    #define PRFP(s,a,b) printf( s ":  %X ( %2X)%c  ", a, b, a!=b ? '*' : ' ' );
    auto regs = uut.jt900h->u_regs;
    PCMP( "XWA0", emu.rr[0].xwa, regs->xwa0 ) PCMP( "XWA1", emu.rr[1].xwa, regs->xwa1 ) PCMP( "XWA2", emu.rr[2].xwa, regs->xwa2 ) PCMP( "XWA3", emu.rr[3].xwa, regs->xwa3 ) putchar('\n');
    PCMP( "XBC0", emu.rr[0].xbc, regs->xbc0 ) PCMP( "XBC1", emu.rr[1].xbc, regs->xbc1 ) PCMP( "XBC2", emu.rr[2].xbc, regs->xbc2 ) PCMP( "XBC3", emu.rr[3].xbc, regs->xbc3 ) putchar('\n');
    PCMP( "XDE0", emu.rr[0].xde, regs->xde0 ) PCMP( "XDE1", emu.rr[1].xde, regs->xde1 ) PCMP( "XDE2", emu.rr[2].xde, regs->xde2 ) PCMP( "XDE3", emu.rr[3].xde, regs->xde3 ) putchar('\n');
    PCMP( "XHL0", emu.rr[0].xhl, regs->xhl0 ) PCMP( "XHL1", emu.rr[1].xhl, regs->xhl1 ) PCMP( "XHL2", emu.rr[2].xhl, regs->xhl2 ) PCMP( "XHL3", emu.rr[3].xhl, regs->xhl3 ) putchar('\n');
    putchar('\n');
    PCMP( "XIX ", emu.xix, regs->xix ) putchar('\n');
    PCMP( "XIY ", emu.xiy, regs->xiy ) PRFP( "RFP", emu.rfp, uut.jt900h->rfp ) putchar('\n');
    PCMP( "XIZ ", emu.xiz, regs->xiz ) PCFL( "F  ", emu.flags, uut.jt900h->flags ) putchar('\n');
    PCMP( "XSP ", emu.xsp, regs->xsp ) PCMP( "PC ", emu.pc, uut.jt900h->pc ) putchar('\n');
    printf("-----------------------------------------------\n");
    #undef PCMP
}

int main(int argc, char *argv[]) {
    const int MAXCYCLES=20;
    T900H cpu;
    Mem m;
    VerilatedContext context;
    context.commandArgs(argc, argv);
    Verilated::traceEverOn(true);
    VerilatedVcdC tracer;
    auto verbose=false;

    for( int k=1; k<argc; k++ ) {
        if( strcmp(argv[k],"-v")==0 || strcmp(argv[k],"--verbose" )==0) {
            verbose=true;
            continue;
        }
        printf("Unknown argument %s\n",argv[k]);
        return 1;
    }

    try{
        UUT uut{&context};
        uut.trace( &tracer, 99 );
        tracer.open("test.vcd");
        reset(uut,m, &tracer);
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
        uint32_t end = (rom_bank<<16) | 0xf000;
        cpu.Reset(m);
        auto matched = false;
        int icount=0;
        while( cpu.pc.q<end ) {
            auto pc_old = cpu.pc.q;
            auto fetched = cpu.Exec( m );
            // if( verbose ) show(cpu, m, pc_old, fetched);
            matched = false;
            for( int k=0, pcok=0; k<MAXCYCLES;  ) {
                clock( uut, m, &tracer, 1 );
                if( uut.jt900h->alu_busy ) continue;
                k++;
                if( uut.jt900h->pc >= cpu.pc.q ) pcok=1;
                if( pcok ) {
                    if( cmp(uut,cpu) ) {
                        matched=true;
                        break;
                    } /*else if(uut.jt900h->pc == cpu.pc.q){
                        show_comp(uut,cpu);
                    }*/

                }
            }
            if( !matched ) {
                printf("JT900H and the CPU model diverged after %d instructions (%lu ps)\n", icount, simtime);
                if(!verbose) show(cpu, m, pc_old, fetched);
                printf("register: model (verilog)\n");
                show_comp( uut, cpu );
                break;
            }
            if( verbose ) {
                show_comp( uut, cpu );
            }
            icount++;
        }
        if( matched ) {
            printf("Finished after %d instructions (%lu ps)\nInstructions run per type:\n", icount, simtime);
            printf("\t%d ADD\n", cpu.stats.add);
            printf("\t%d ADC\n", cpu.stats.adc);
            printf("\t%d MUL\n", cpu.stats.mul);
            printf("\t%d MULS\n", cpu.stats.muls);
            printf("\t%d SUB\n", cpu.stats.sub);
            printf("\t%d CP\n", cpu.stats.cp);
            printf("\t%d SBC\n", cpu.stats.sbc);
            printf("\t%d AND\n", cpu.stats.and_op);
            printf("\t%d ANDCF\n", cpu.stats.andcf);
            printf("\t%d ORCF\n", cpu.stats.orcf);
            printf("\t%d XORCF\n", cpu.stats.xorcf);
            printf("\t%d STCF\n", cpu.stats.stcf);
            printf("\t%d LDCF\n", cpu.stats.ldcf);
            printf("\t%d BIT\n", cpu.stats.bit_op);
            printf("\t%d RES\n", cpu.stats.res_op);
            printf("\t%d SET\n", cpu.stats.set_op);
            printf("\t%d CHG\n", cpu.stats.chg);
            printf("\t%d TSET\n", cpu.stats.tset);
            printf("\t%d OR\n", cpu.stats.or_op);
            printf("\t%d XOR\n", cpu.stats.xor_op);
            printf("\t%d LD\n", cpu.stats.ld);
            printf("\t%d NEG\n", cpu.stats.neg);
            printf("\t%d EXTZ\n", cpu.stats.extz);
            printf("\t%d EXTS\n", cpu.stats.exts);
            printf("\t%d PAA\n", cpu.stats.paa);
            printf("\t%d CCF\n", cpu.stats.ccf);
            printf("\t%d RCF\n", cpu.stats.rcf);
            printf("\t%d SCF\n", cpu.stats.scf);
            printf("\t%d ZCF\n", cpu.stats.zcf);
            printf("\t%d SCC\n", cpu.stats.scc);
            printf("\t%d EX\n", cpu.stats.ex);
            printf("\t%d DECF\n", cpu.stats.decf);
            printf("\t%d INCF\n", cpu.stats.incf);
            printf("\t%d INC\n", cpu.stats.inc);
            printf("\t%d DEC\n", cpu.stats.dec);
            printf("\t%d CPL\n", cpu.stats.cpl);
            printf("\t%d SLL\n", cpu.stats.sll);
            printf("\t%d SLA\n", cpu.stats.sla);
            printf("\t%d SRA\n", cpu.stats.sra);
            printf("\t%d SRL\n", cpu.stats.srl);
            printf("\t%d RL\n", cpu.stats.rl_op);
            printf("\t%d RR\n", cpu.stats.rr_op);
            printf("\t%d RLC\n", cpu.stats.rlc);
            printf("\t%d RRC\n", cpu.stats.rrc);
            printf("\t%d MIRR\n", cpu.stats.mirr);
            printf("\t%d BS1F\n", cpu.stats.bs1f);
            printf("\t%d BS1B\n", cpu.stats.bs1b);
            printf("\t%d MULA\n", cpu.stats.mula);
            printf("\t%d MINC1\n", cpu.stats.minc1);
            printf("\t%d MINC2\n", cpu.stats.minc2);
            printf("\t%d MINC4\n", cpu.stats.minc4);
            printf("\t%d MDEC1\n", cpu.stats.mdec1);
            printf("\t%d MDEC2\n", cpu.stats.mdec2);
            printf("\t%d MDEC4\n", cpu.stats.mdec4);
            printf("\t%d PUSHF\n", cpu.stats.pushF);
            printf("\t%d POPF\n", cpu.stats.popF);
        }
        tracer.flush();
    } catch( const char *error ) {
        fputs(error,stderr);
        fputc('\n',stderr);
        return 1;
    }
    return 0;
}