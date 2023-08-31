#include <cstdio>
#include <cstdlib>
#include <cstdint>
#include <cstring>

#define MASKCP(a,b) ((a&b)==b)
#define MASKCP2(a,b,c) ((a&b)==c)

typedef union {
	std::uint8_t b[4];
	std::uint16_t w[2];
	std::uint32_t q;

	std::int8_t bs[4];
	std::int16_t ws[2];
	std::int32_t qs;
} Reg32;

struct Mem {
	uint8_t *p;
	Mem() {
		p = new uint8_t[0x10'00000]; // 16 MB
		for( int k=0; k<0x10'00000; k++ ) {
			p[k] = std::rand();
		}
	}
	~Mem() { if(p) delete []p; }
	uint8_t Rd8( uint32_t a ) { return p[a]; }
	uint16_t Rd16(uint32_t a) {
		Reg32 aux;
		aux.b[0] = p[a];
		aux.b[1] = p[a+1];
		return aux.w[0];
	}
	uint32_t Rd32(uint32_t a) {
		if( (a&3)==0 ) {
			return *(((uint32_t*)p)+(a>>2));
		}
		Reg32 aux;
		if( (a&3)==2 ) {
			uint16_t *p16 = (uint16_t*)p;
			p16 += a>>1;
			aux.w[0] = *p16++;
			aux.w[1] = *p16;
		} else {
			aux.b[0] = p[a];
			aux.b[1] = p[a+1];
			aux.b[2] = p[a+2];
			aux.b[3] = p[a+3];
		}
		return aux.q;
	}
};

const uint8_t FLAG_Z = 0x40, FLAG_NZ=(uint8_t)~FLAG_Z,
              FLAG_S = 0x80, FLAG_NS=(uint8_t)~FLAG_S,
              FLAG_H = 0x10, FLAG_NH=(uint8_t)~FLAG_H,
              FLAG_V = 0x04, FLAG_NV=(uint8_t)~FLAG_V,
              FLAG_N = 0x02, FLAG_NN=(uint8_t)~FLAG_N,
              FLAG_C = 0x01, FLAG_NC=(uint8_t)~FLAG_C;

template<typename T> void set_sz( T a, uint8_t& flags ) {
	const T MSB = 1 << (8*sizeof(a)-1);
	if( a==0  ) flags |= FLAG_Z; else flags &= FLAG_NZ;
	if( a&MSB ) flags |= FLAG_S; else flags &= FLAG_NS;
}
template<typename T> void parity( T data, uint8_t& flags){
	data ^= data >> 8;
	data ^= data >> 4;
	data ^= data >> 2;
 	data ^= data >> 1;
  	if ( !(data & 1) ) flags |= FLAG_V; else flags &= FLAG_NV;
}

template <typename T> T add( T a, T b, uint8_t &flags ) {
	T rs = a+b;
	const int64_t MASK=sizeof(T)==1 ? 0xff : sizeof(T)==2 ? 0xffff : 0xffffffff;
	int64_t u = (((int64_t)a)&MASK)+(((int64_t)b)&MASK);
	flags &= FLAG_NN; // N=0
	set_sz( rs, flags );
	if( (a>0 && b>0 && rs<0) || (a<0 && b<0 && rs>=0) )
		flags |= FLAG_V;
	else
		flags &= FLAG_NV;
	if( (a&0xf)+(b&0xf) > 0xf )
		flags |= FLAG_H;
	else
		flags &= FLAG_NH;
	if( u>MASK )
		flags |= FLAG_C;
	else
		flags &= FLAG_NC;
	// printf("Add %X+%X = %X (%X)\n",(int)a&MASK,(int)b&MASK,(unsigned)rs,(int)u);
	return rs;
}

template <typename T> T adc( T a, T b, uint8_t &flags ) {
	T rs = a+b+(flags&FLAG_C);
	const int64_t MASK=sizeof(T)==1 ? 0xff : sizeof(T)==2 ? 0xffff : 0xffffffff;
	int64_t u = (((int64_t)a)&MASK)+(((int64_t)b)&MASK)+(flags&FLAG_C);
	T v = (a ^ rs) & (b ^ rs);
	const T MSB = sizeof(T)==1 ? (v >> 7) & 1 : sizeof(T)==2 ? (v >> 15) & 1 : (v >> 31) & 1;
	flags &= FLAG_NN; // N=0
	set_sz( rs, flags );
	if( ((a&0xf)+(b&0xf)+(flags&FLAG_C)) > 0xf )
		flags |= FLAG_H;
	else
		flags &= FLAG_NH;
	if( MSB )
		flags |= FLAG_V;
	else
		flags &= FLAG_NV;
	if( u>MASK )
		flags |= FLAG_C;
	else
		flags &= FLAG_NC;
	return rs;
}

template <typename T> T sub( T a, T b, uint8_t &flags ) {
	T rs = a-b;
	T c = a ^ b ^ rs;
  	T v = (a ^ b) & (a ^ rs);
  	const T carryH = (c & 0x10) >> 4;
	const T MSB = sizeof(T)==1 ? (v >> 7) & 1 : sizeof(T)==2 ? (v >> 15) & 1 : (v >> 31) & 1;
	const T carry = sizeof(T)==1 ? (c ^ v) >> 7 : sizeof(T)==2 ? (c ^ v) >> 15 : (c ^ v) >> 31;
	flags |= FLAG_N; // N=1
	set_sz( rs, flags );
	if( MSB )
		flags |= FLAG_V;
	else
		flags &= FLAG_NV;
	if( carryH )
		flags |= FLAG_H;
	else
		flags &= FLAG_NH;
	if( carry )
		flags |= FLAG_C;
	else
		flags &= FLAG_NC;
	return rs;
}

template <typename T> void cp( T a, T b, uint8_t &flags ) {
	T rs = a-b;
	T c = a ^ b ^ rs;
  	T v = (a ^ b) & (a ^ rs);
  	const T carryH = (c & 0x10) >> 4;
	const T MSB = sizeof(T)==1 ? (v >> 7) & 1 : sizeof(T)==2 ? (v >> 15) & 1 : (v >> 31) & 1;
	const T carry = sizeof(T)==1 ? (c ^ v) >> 7 : sizeof(T)==2 ? (c ^ v) >> 15 : (c ^ v) >> 31;
	flags |= FLAG_N; // N=1
	set_sz( rs, flags );
	if( MSB )
		flags |= FLAG_V;
	else
		flags &= FLAG_NV;
	if( carryH )
		flags |= FLAG_H;
	else
		flags &= FLAG_NH;
	if( carry )
		flags |= FLAG_C;
	else
		flags &= FLAG_NC;
}

template <typename T> T sbc( T a, T b, uint8_t &flags ) {
	T rs = a-b-(flags&FLAG_C);
	T c = a ^ b ^ rs;
  	T v = (a ^ b) & (a ^ rs);
  	const T carryH = (c & 0x10) >> 4;
	const T MSB = sizeof(T)==1 ? (v >> 7) & 1 : sizeof(T)==2 ? (v >> 15) & 1 : (v >> 31) & 1;
	const T carry = sizeof(T)==1 ? (c ^ v) >> 7 : sizeof(T)==2 ? (c ^ v) >> 15 : (c ^ v) >> 31;
	flags |= FLAG_N; // N=1
	set_sz( rs, flags );
	if( MSB )
		flags |= FLAG_V;
	else
		flags &= FLAG_NV;
	if( carryH )
		flags |= FLAG_H;
	else
		flags &= FLAG_NH;
	if( carry )
		flags |= FLAG_C;
	else
		flags &= FLAG_NC;
	return rs;
}

template <typename T> T neg( T a, uint8_t &flags ) {
	T rs = 0-a;
	T c = 0 ^ a ^ rs;
  	T v = (0 ^ a) & (0 ^ rs);
  	const T carryH = (c & 0x10) >> 4;
	const T MSB = sizeof(T)==1 ? (v >> 7) & 1 : sizeof(T)==2 ? (v >> 15) & 1 : (v >> 31) & 1;
	const T carry = sizeof(T)==1 ? (c ^ v) >> 7 : sizeof(T)==2 ? (c ^ v) >> 15 : (c ^ v) >> 31;
	flags |= FLAG_N; // N=1
	set_sz( rs, flags );
	if( MSB )
		flags |= FLAG_V;
	else
		flags &= FLAG_NV;
	if( carryH )
		flags |= FLAG_H;
	else
		flags &= FLAG_NH;
	if( carry )
		flags |= FLAG_C;
	else
		flags &= FLAG_NC;
	return rs;
}

template <typename T> T and_op( T a, T b, uint8_t &flags ) {
	T rs = a & b;
	flags |= FLAG_H; // H=1
	flags &= FLAG_NN; // N=0
	flags &= FLAG_NC; // C=0
	parity( rs, flags );
	set_sz( rs, flags );
	return rs;
}

template <typename T> T or_op( T a, T b, uint8_t &flags ) {
	T rs = a | b;
	flags &= FLAG_NH; // H=0
	flags &= FLAG_NN; // N=0
	flags &= FLAG_NC; // C=0
	parity( rs, flags );
	set_sz( rs, flags );
	return rs;
}

template <typename T> T xor_op( T a, T b, uint8_t &flags ) {
	T rs = a ^ b;
	flags &= FLAG_NH; // H=0
	flags &= FLAG_NN; // N=0
	flags &= FLAG_NC; // C=0
	parity( rs, flags );
	set_sz( rs, flags );
	return rs;
}

template <typename T> T inc_op( T a, T b, uint8_t &flags ) {
	if( !b ) b = 8;
	T rs = a+b;
	if ( sizeof(T)==1 ) {
		flags &= FLAG_NN; // N=0
		set_sz( rs, flags );
		if( (a>0 && b>0 && rs<0) || (a<0 && b<0 && rs>=0) )
			flags |= FLAG_V;
		else
			flags &= FLAG_NV;
		if( (a&0xf)+(b&0xf) > 0xf)
			flags |= FLAG_H;
		else
			flags &= FLAG_NH;
	}
	return rs;
}
template <typename T> T dec_op( T a, T b, uint8_t &flags ) {
	if( !b ) b = 8;
	T rs = a-b;
	T c = a ^ b ^ rs;
  	T v = (a ^ b) & (a ^ rs);
  	const T carryH = (c & 0x10) >> 4;
	const T MSB = sizeof(T)==1 ? (v >> 7) & 1 : sizeof(T)==2 ? (v >> 15) & 1 : (v >> 31) & 1;
  	if ( sizeof(T)==1 ) {
		flags |= FLAG_N; // N=1
		set_sz( rs, flags );
		if( MSB )
			flags |= FLAG_V;
		else
			flags &= FLAG_NV;
		if( carryH )
			flags |= FLAG_H;
		else
			flags &= FLAG_NH;
	}
	return rs;
}

template <typename T> T sll(T a, int b, uint8_t &flags ) {
	if( !b ) b = 16;
    T rs = a << b;
    T c = a << (b - 1);
	const T MSB = sizeof(T)==1 ? (c >> 7) & 1 : sizeof(T)==2 ? (c >> 15) & 1 : (c >> 31) & 1;
    flags &= FLAG_NH; // H=0
    flags &= FLAG_NN; // N=0
    parity( rs, flags );
    set_sz( rs, flags );
    if( MSB )
		flags |= FLAG_C;
	else
		flags &= FLAG_NC;
    return rs;
}

template <typename T> T srl(T a, int b, uint8_t &flags ) {
    if( !b ) b = 16;
    T rs = a >> b;
    T c = a >> (b - 1);
    const T LSB = sizeof(T)==1 ? (c & 1) : sizeof(T)==2 ? (c & 1 ): (c & 1);
    flags &= FLAG_NH; // H=0
    flags &= FLAG_NN; // N=0
    parity( rs, flags );
    set_sz( rs, flags );
    if( LSB )
        flags |= FLAG_C;
    else
        flags &= FLAG_NC;
    return rs;
}

template <typename T> T sra(T a, int b, uint8_t &flags ) {
    if( !b ) b = 16;
    const T nb = sizeof(T) * 8;
    T rs = a;
    for (int i = 0; i < b ; i++) {
    	if ( i == (b-1) ) {
    		const T LSB = sizeof(T)==1 ? (rs & 1) : sizeof(T)==2 ? (rs & 1 ): (rs & 1);
	    	if( LSB )
		        flags |= FLAG_C;
		    else
		        flags &= FLAG_NC;
    	}
    	const T MSB = sizeof(T)==1 ? (rs >> 7) & 1 : sizeof(T)==2 ? (rs >> 15) & 1 : (rs >> 31) & 1;
    	rs = (rs >> 1) | (MSB << (nb -1));
    }
    flags &= FLAG_NH; // H=0
    flags &= FLAG_NN; // N=0
    parity( rs, flags );
    set_sz( rs, flags );
    return rs;
}

template <typename T> T rlc(T a, int b, uint8_t &flags ) {
    if( !b ) b = 16;
    const T nb = sizeof(T) * 8;
    T rs = (a << b) | (a >> (nb - b));
    T c = rs & 1;
    flags &= FLAG_NH; // H=0
    flags &= FLAG_NN; // N=0
    parity( rs, flags );
    set_sz( rs, flags );
    if( c )
        flags |= FLAG_C;
    else
        flags &= FLAG_NC;
    return rs;
}

template <typename T> T rrc(T a, int b, uint8_t &flags ) {
    if( !b ) b = 16;
    const T nb = sizeof(T) * 8;
    T rs = (a >> b) | (a << (nb - b));
    const T MSB = sizeof(T)==1 ? (rs >> 7) & 1 : sizeof(T)==2 ? (rs >> 15) & 1 : (rs >> 31) & 1;
    flags &= FLAG_NH; // H=0
    flags &= FLAG_NN; // N=0
    parity( rs, flags );
    set_sz( rs, flags );
    if( MSB )
        flags |= FLAG_C;
    else
        flags &= FLAG_NC;
    return rs;
}

template <typename T> T rl_op(T a, int b, uint8_t &flags ) {
    if( !b ) b = 16;
    T rs = a;
    for (int i = 0; i < b ; i++) {
        T MSB = sizeof(T)==1 ? (rs >> 7) & 1 : sizeof(T)==2 ? (rs >> 15) & 1 : (rs >> 31) & 1;
       	rs = (rs << 1) | flags&FLAG_C;
        if( MSB )
            flags |= FLAG_C;
        else
            flags &= FLAG_NC;
    }
    flags &= FLAG_NH; // H=0
    flags &= FLAG_NN; // N=0
    parity( rs, flags );
    set_sz( rs, flags );
    return rs;
}

template <typename T> T rr_op(T a, int b, uint8_t &flags ) {
    if( !b ) b = 16;
    T rs = a;
    const T nb = sizeof(T) * 8;
    for (int i = 0; i < b ; ++i) {
    	T c = rs & 1;
        rs = (rs >> 1) | (flags&FLAG_C) << (nb -1);
        if( c )
            flags |= FLAG_C;
        else
            flags &= FLAG_NC;
    }
    flags &= FLAG_NH; // H=0
    flags &= FLAG_NN; // N=0
    parity( rs, flags );
    set_sz( rs, flags );
    return rs;
}

template <typename T> void andcf( T a, int b, uint8_t &flags )  {
    a = (a >> b) & 1;
    T rs = (flags&FLAG_C) && a;
    if ( rs )
        flags |= FLAG_C;
    else
        flags &= FLAG_NC;
}

template <typename T> void xorcf( T a, int b, uint8_t &flags )  {
    a = (a >> b) & 1;
    T rs = (flags&FLAG_C) ^ a;
    if ( rs )
        flags |= FLAG_C;
    else
        flags &= FLAG_NC;
}

template <typename T> void orcf( T a, int b, uint8_t &flags )  {
    // printf(" ORCF a=%X b=%X \n",a,b );
    a = (a >> b) & 1;
    T rs = (flags&FLAG_C) || a;
    if ( rs )
        flags |= FLAG_C;
    else
        flags &= FLAG_NC;
}

template <typename T> void bit_op( T a, int b, uint8_t &flags )  {
	a = (a >> b) & 1;
    if ( a )
    	flags &= FLAG_NZ;
    else
    	flags |= FLAG_Z;
	flags |= FLAG_H; // H=1
    flags &= FLAG_NN; // N=0
}

template <typename T> T cpl( T a, uint8_t &flags ) {
	T rs = ~a;
	flags |= FLAG_H;
	flags |= FLAG_N;
	return rs;
}

template <typename T> T stcf( T a, int b, uint8_t &flags) {
	if ( flags&FLAG_C )
		a |= (1 << b);
	else
		a &= ~(1 << b);
	return a;
}

template <typename T> void ldcf( T a, int b, uint8_t &flags) {
	a = (a >> b) & 1;
	if ( !a )
    	flags &= FLAG_NC;
    else
    	flags |= FLAG_C;
}

template <typename T> T tset( T a, int b, uint8_t &flags )  {
    T rs = a | (1 << b);
    a ^= (1 << b);
    if ( a!=rs )
    	flags &= FLAG_NZ;
    else
    	flags |= FLAG_Z;
    flags |= FLAG_H; // H=1
    flags &= FLAG_NN; // N=0
    return rs;
}

template <typename T> T exts( T a ) {
	T rs;
	if (sizeof(T)==2)
		rs = ((a & 0x0080) ? 0xFF00 : 0x0000) | (a & 0x00FF);
	else
		rs = ((a & 0x00008000) ? 0xFFFF0000 : 0x00000000) | (a & 0x0000FFFF);
	return rs;
}

struct T900H {
	Reg32 xix,xiy,xiz,xsp, pc;
	struct Bank{
		Reg32 xwa,xbc,xde,xhl;
	} rr[4];
	struct {
		int ld, add, ccf, decf, incf, rcf, scf, zcf, and_op, or_op, xor_op, adc, sub, sbc, cp, andcf, orcf, xorcf, bit_op,
			neg, extz, exts, paa, inc, dec, cpl, ex, rl_op, rr_op, rlc, rrc, sla, sra, sll, srl, res_op, set_op, chg, tset,
			stcf, ldcf, mul, muls, div, divs;
	} stats;
	Bank *rf;
	int rfp; // Register File Pointer
	uint8_t flags,fdash, nx_fdash;
	void Reset(Mem& m) {
		pc.q = m.Rd32(0xffff00);
		for( int k=0;k<4; k++ ) {
			rr[k].xwa.q = rr[k].xbc.q = rr[k].xde.q = rr[k].xhl.q = 0;
		}
		xix.q = xiy.q = xiz.q = 0;
		xsp.q = 0x100;
		rfp = 0;
		rf=&rr[0];
		flags = nx_fdash = 0;
		memset(&stats,0,sizeof(stats));
	}
	int Exec(Mem &m) {
		fdash = nx_fdash;
		uint8_t op[12];
		op[0] = m.Rd8(pc.q++);
		int fetched=1;
		int r,R, len, num3,num4, RR;
		if( op[0]==0x12 ) { stats.ccf++;  flags &= FLAG_NN; flags = flags ^ 1; } // CCF
		if( op[0]==0x11 ) { stats.scf++;  flags &= FLAG_NH; flags &= FLAG_NN; flags |= FLAG_C;} // SCF
		if( op[0]==0x10 ) { stats.rcf++;  flags &= FLAG_NH; flags &= FLAG_NN; flags &= FLAG_NC;} // RCF
		if( op[0]==0x13 ) { stats.zcf++;  flags &= FLAG_NN; if ( flags & FLAG_Z ) flags &= FLAG_NC; else flags |= FLAG_C; } // ZCF
		if( op[0]==0x16 ) { stats.ex++; nx_fdash = flags; flags = fdash; } // EXFF
		if( op[0]==0x0C ) { stats.incf++; rfp++; rfp&=3; rf=&rr[rfp]; } // INCF
		if( op[0]==0x0D ) { stats.decf++; rfp--; rfp&=3; rf=&rr[rfp]; } // DECF
		if( MASKCP(op[0],0xc8) && !MASKCP(op[0],0x30) ) {
			auto A = (rf->xwa.b[0])&0x0f; // (*rf).xwa.b[1]
			r = op[0]&7;
			len = (op[0]>>4)&3;
			op[1] = m.Rd8(pc.q++);
			// if (op[1] & 1) RR=op[1]&7;
			// else RR=1;
			R = op[1]&7;
			num3 = op[1]&7;
			fetched++;
			if( MASKCP2(op[1],0xF8,0x80) ) {  // ADD R,r
				stats.add++;
				switch(len) {
					case 0: *shortReg8(R)  = add( (int8_t)*shortReg8(R), (int8_t)*shortReg8(r),  flags ); break;
					case 1: *shortReg16(R) = add( (int16_t)*shortReg16(R), (int16_t)*shortReg16(r), flags ); break;
					case 2: shortReg(R)->q = add( shortReg(R)->qs, shortReg(r)->qs, flags ); break;
				}
			}
			else if( MASKCP2(op[1],0xF8,0x40) ) {  // MUL RR,r
				stats.mul++;
				switch(len) {
					case 0: *extReg16(R) = (uint16_t)*extReg8(R) * (uint16_t)*shortReg8(r); break;
					case 1: shortReg(R)->q = (uint32_t)*shortReg16(R) * (uint32_t)*shortReg16(r); break;
				}
			}
			else if( MASKCP2(op[1],0xF8,0x48) ) {  // MULS RR,r
				stats.muls++;
				switch(len) {
					case 0: *extReg16(R) = (int16_t)((int8_t)*extReg8(R) * (int8_t)*shortReg8(r)); break;
					case 1: shortReg(R)->qs = (int32_t)((int16_t)*shortReg16(R) * (int16_t)*shortReg16(r)); break;
				}
			}
			else if( MASKCP2(op[1],0xF8,0x60) ) {  //  INC #3,r
				stats.inc++;
				switch(len) {
					case 0: *shortReg8(r)  = inc_op( (int8_t)*shortReg8(r), (int8_t)num3,  flags ); break;
					case 1: *shortReg16(r) = inc_op( (int16_t)*shortReg16(r), (int16_t)num3, flags ); break;
					case 2: shortReg(r)->q = inc_op( shortReg(r)->qs, num3, flags ); break;
				}
			}
			else if( MASKCP2(op[1],0xF8,0x68) ) {  //  DEC #3,r
				stats.dec++;
				switch(len) {
					case 0: *shortReg8(r)  = dec_op( (int8_t)*shortReg8(r), (int8_t)num3,  flags ); break;
					case 1: *shortReg16(r) = dec_op( (int16_t)*shortReg16(r), (int16_t)num3, flags ); break;
					case 2: shortReg(r)->q = dec_op( shortReg(r)->qs, num3, flags ); break;
				}
			}
			else if( MASKCP2(op[1],0xF8,0x90) ) {  // ADC R,r
				stats.adc++;
				switch(len) {
					case 0: *shortReg8(R)  = adc( (int8_t)*shortReg8(R), (int8_t)*shortReg8(r),  flags ); break;
					case 1: *shortReg16(R) = adc( (int16_t)*shortReg16(R), (int16_t)*shortReg16(r), flags ); break;
					case 2: shortReg(R)->q = adc( shortReg(R)->qs, shortReg(r)->qs, flags ); break;
				}
			}
			else if( MASKCP2(op[1],0xF8,0xA0) ) {  // SUB R,r
				stats.sub++;
				switch(len) {
					case 0: *shortReg8(R)  = sub( (int8_t)*shortReg8(R), (int8_t)*shortReg8(r),  flags ); break;
					case 1: *shortReg16(R) = sub( (int16_t)*shortReg16(R), (int16_t)*shortReg16(r), flags ); break;
					case 2: shortReg(R)->q = sub( shortReg(R)->qs, shortReg(r)->qs, flags ); break;
				}
			}
			else if( MASKCP2(op[1],0xF8,0xD8) ) {  // CP r,#3
				stats.cp++;
				switch(len) {
					case 0: cp( (int8_t)*shortReg8(r), (int8_t)num3,  flags ); break;
					case 1: cp( (int16_t)*shortReg16(r), (int16_t)num3, flags ); break;
					case 2: break;
				}
			}
			else if( MASKCP2(op[1],0xF8,0xF0) ) {  // CP R,r
				stats.cp++;
				switch(len) {
					case 0: cp( (int8_t)*shortReg8(R), (int8_t)*shortReg8(r),  flags ); break;
					case 1: cp( (int16_t)*shortReg16(R), (int16_t)*shortReg16(r), flags ); break;
					case 2: cp( shortReg(R)->qs, shortReg(r)->qs, flags ); break;
				}
			}
			else if( MASKCP2(op[1],0xF8,0xB0) ) {  // SBC R,r
				stats.sbc++;
				switch(len) {
					case 0: *shortReg8(R)  = sbc( (int8_t)*shortReg8(R), (int8_t)*shortReg8(r),  flags ); break;
					case 1: *shortReg16(R) = sbc( (int16_t)*shortReg16(R), (int16_t)*shortReg16(r), flags ); break;
					case 2: shortReg(R)->q = sbc( shortReg(R)->qs, shortReg(r)->qs, flags ); break;
				}
			}
			else if( MASKCP2(op[1],0xF8,0xB8) ) {  // EX R,r
				stats.ex++;
				int temp = 0;
				switch(len) {
					case 0:	temp = *shortReg8(R);
							*shortReg8(R) = *shortReg8(r);
							*shortReg8(r) = temp;
							break;
					case 1: temp = *shortReg16(R);
							*shortReg16(R) = *shortReg16(r);
							*shortReg16(r) = temp;
							break;
					case 2: break;
				}

			}
			else if( MASKCP2(op[1],0xF8,0xC0) ) {  // AND R,r
				stats.and_op++;
				switch(len) {
					case 0: *shortReg8(R)  = and_op( (int8_t)*shortReg8(R), (int8_t)*shortReg8(r),  flags ); break;
					case 1: *shortReg16(R) = and_op( (int16_t)*shortReg16(R), (int16_t)*shortReg16(r), flags ); break;
					case 2: shortReg(R)->q = and_op( shortReg(R)->qs, shortReg(r)->qs, flags ); break;
				}
			}
			else if( MASKCP2(op[1],0xF8,0xD0) ) {  // XOR R,r
				stats.xor_op++;
				switch(len) {
					case 0: *shortReg8(R)  = xor_op( (int8_t)*shortReg8(R), (int8_t)*shortReg8(r),  flags ); break;
					case 1: *shortReg16(R) = xor_op( (int16_t)*shortReg16(R), (int16_t)*shortReg16(r), flags ); break;
					case 2: shortReg(R)->q = xor_op( shortReg(R)->qs, shortReg(r)->qs, flags ); break;
				}
			}
			else if( MASKCP2(op[1],0xF8,0xE0) ) {  // OR R,r
				stats.or_op++;
				switch(len) {
					case 0: *shortReg8(R)  = or_op( (int8_t)*shortReg8(R), (int8_t)*shortReg8(r),  flags ); break;
					case 1: *shortReg16(R) = or_op( (int16_t)*shortReg16(R), (int16_t)*shortReg16(r), flags ); break;
					case 2: shortReg(R)->q = or_op( shortReg(R)->qs, shortReg(r)->qs, flags ); break;
				}
			}
			else if( MASKCP2(op[1],0xF8,0x88) ) {  // LD R,r
				stats.ld++;
				switch(len) {
					case 0: *shortReg8(R)  = *shortReg8(r); break;
					case 1: *shortReg16(R) = *shortReg16(r); break;
					case 2: *shortReg(R)   = *shortReg(r); break;
				}
			}
			else if( MASKCP2(op[1],0xF8,0x98) ) {  // LD r,R
				stats.ld++;
				switch(len) {
					case 0: *shortReg8(r)  = *shortReg8(R); break;
					case 1: *shortReg16(r) = *shortReg16(R); break;
					case 2: *shortReg(r)   = *shortReg(R); break;
				}
			}
			else if( op[1]==0x06 ) {  //  CPL r
				stats.cpl++;
				switch(len) {
					case 0: *shortReg8(r)  = cpl((int8_t)*shortReg8(r), flags); break;
					case 1: *shortReg16(r) = cpl((int16_t)*shortReg16(r), flags); break;
					case 2: break;
				}
			}
			else if( op[1]==0x07 ) {  //  NEG r
				stats.neg++;
				switch(len) {
					case 0: *shortReg8(r)  = neg((int8_t)*shortReg8(r), flags); break;
					case 1: *shortReg16(r) = neg((int16_t)*shortReg16(r), flags); break;
					case 2: shortReg(r)->q = neg(shortReg(r)->qs, flags); break;
				}
			}
			else if( op[1]==0x20 ) {  // ANDCF #4,r
                op[2] = m.Rd8(pc.q++);
            	num4 = op[2];
            	stats.andcf++;
                switch(len) {
                    case 0: andcf(*shortReg8(r), num4, flags ); break;
                    case 1: andcf(*shortReg16(r), num4, flags ); break;
                 }
            }
            else if( op[1]==0x21 ) {  // ORCF #4,r
                op[2] = m.Rd8(pc.q++);
            	num4 = op[2];
            	stats.orcf++;
                switch(len) {
                    case 0: orcf(*shortReg8(r), num4, flags ); break;
                    case 1: orcf(*shortReg16(r), num4, flags ); break;
                }
            }
            else if( op[1]==0x22 ) {  // XORCF #4,r
                op[2] = m.Rd8(pc.q++);
            	num4 = op[2];
            	stats.xorcf++;
                switch(len) {
                    case 0: xorcf(*shortReg8(r), num4, flags ); break;
                    case 1: xorcf(*shortReg16(r), num4, flags ); break;
                }
            }
            else if( op[1]==0x23 ) {  // LDCF #4,r
                op[2] = m.Rd8(pc.q++);
            	num4 = op[2];
            	stats.ldcf++;
                switch(len) {
                    case 0: ldcf(*shortReg8(r), num4, flags); break;
                    case 1: ldcf(*shortReg16(r), num4, flags); break;
                }
            }
            else if( op[1]==0x24 ) {  // STCF #4,r
                op[2] = m.Rd8(pc.q++);
            	num4 = op[2];
            	stats.stcf++;
                switch(len) {
                    case 0: *shortReg8(r) = stcf(*shortReg8(r), num4, flags); break;
                    case 1: *shortReg16(r) = stcf(*shortReg16(r), num4, flags); break;
                }
            }
            else if( op[1]==0x30 ) {  // RES #4,r
                op[2] = m.Rd8(pc.q++);
            	num4 = op[2];
            	stats.res_op++;
                switch(len) {
                    case 0: *shortReg8(r) &= ~(1 << num4); break;
                    case 1: *shortReg16(r) &= ~(1 << num4); break;
                }
            }
            else if( op[1]==0x31 ) {  // SET #4,r
                op[2] = m.Rd8(pc.q++);
            	num4 = op[2];
            	stats.set_op++;
                switch(len) {
                    case 0: *shortReg8(r) |= (1 << num4); break;
                    case 1: *shortReg16(r) |= (1 << num4); break;
                }
            }
            else if( op[1]==0x32 ) {  // CHG #4,r
                op[2] = m.Rd8(pc.q++);
            	num4 = op[2];
            	stats.chg++;
                switch(len) {
                    case 0: *shortReg8(r) ^= (1 << num4); break;
                    case 1: *shortReg16(r) ^= (1 << num4); break;
                }
            }
            else if( op[1]==0x33 ) {  // BIT #4,r
                op[2] = m.Rd8(pc.q++);
            	num4 = op[2];
            	stats.bit_op++;
                switch(len) {
                    case 0: bit_op((int8_t)*shortReg8(r), num4, flags ); break;
                    case 1: bit_op((int16_t)*shortReg16(r), num4, flags ); break;
                }
            }
            else if( op[1]==0x34 ) {  // TSET #4,r
                op[2] = m.Rd8(pc.q++);
            	num4 = op[2];
            	stats.tset++;
                switch(len) {
                    case 0: *shortReg8(r)  = tset(*shortReg8(r), num4, flags ); break;
                    case 1: *shortReg16(r) = tset(*shortReg16(r), num4, flags ); break;
                }
            }
			else if( op[1]==0xF8 ) {  // RLC A,r
                stats.rlc++;
                switch(len) {
                    case 0: *shortReg8(r)  = rlc( *shortReg8(r), A, flags ); break;
                    case 1: *shortReg16(r) = rlc( *shortReg16(r), A, flags ); break;
                    case 2: shortReg(r)->q = rlc( shortReg(r)->q, A, flags ); break;
                }
            }
            else if( op[1]==0xE8 ) {  // RLC #4,r
            	op[2] = m.Rd8(pc.q++);
            	num4 = op[2];
                stats.rlc++;
                switch(len) {
                    case 0: *shortReg8(r)  = rlc( *shortReg8(r), num4, flags ); break;
                    case 1: *shortReg16(r) = rlc( *shortReg16(r), num4, flags ); break;
                    case 2: shortReg(r)->q = rlc( shortReg(r)->q, num4, flags ); break;
                }
            }
            else if( op[1]==0xF9 ) {  // RRC A,r
                stats.rrc++;
                switch(len) {
                    case 0: *shortReg8(r)  = rrc( *shortReg8(r), A, flags ); break;
                    case 1: *shortReg16(r) = rrc( *shortReg16(r), A, flags ); break;
                    case 2: shortReg(r)->q = rrc( shortReg(r)->q, A, flags ); break;
             	}
            }
            else if( op[1]==0xE9 ) {  // RRC #4,r
            	op[2] = m.Rd8(pc.q++);
            	num4 = op[2];
                stats.rrc++;
                switch(len) {
                    case 0: *shortReg8(r)  = rrc( *shortReg8(r), num4, flags ); break;
                    case 1: *shortReg16(r) = rrc( *shortReg16(r), num4, flags ); break;
                    case 2: shortReg(r)->q = rrc( shortReg(r)->q, num4, flags ); break;
                }
            }
            else if( op[1]==0xFA ) {  // RL A,r
                stats.rl_op++;
                switch(len) {
                    case 0: *shortReg8(r)  = rl_op( *shortReg8(r), A, flags ); break;
                    case 1: *shortReg16(r) = rl_op( *shortReg16(r), A, flags ); break;
                    case 2: shortReg(r)->q = rl_op( shortReg(r)->q, A, flags ); break;
                }
            }
            else if( op[1]==0xEA ) {  // RL #4,r
            	op[2] = m.Rd8(pc.q++);
            	num4 = op[2];
                stats.rl_op++;
                switch(len) {
                    case 0: *shortReg8(r)  = rl_op( *shortReg8(r), num4, flags ); break;
                    case 1: *shortReg16(r) = rl_op( *shortReg16(r), num4, flags ); break;
                    case 2: shortReg(r)->q = rl_op( shortReg(r)->q, num4, flags ); break;
                }
            }
            else if( op[1]==0xFB ) {  // RR A,r
                stats.rr_op++;
                switch(len) {
                    case 0: *shortReg8(r)  = rr_op( *shortReg8(r), A, flags ); break;
                    case 1: *shortReg16(r) = rr_op( *shortReg16(r), A, flags ); break;
                    case 2: shortReg(r)->q = rr_op( shortReg(r)->q, A, flags ); break;
                }
            }
            else if( op[1]==0xEB ) {  // RR #4,r
            	op[2] = m.Rd8(pc.q++);
            	num4 = op[2];
                stats.rr_op++;
                switch(len) {
                    case 0: *shortReg8(r)  = rr_op( *shortReg8(r), num4, flags ); break;
                    case 1: *shortReg16(r) = rr_op( *shortReg16(r), num4, flags ); break;
                    case 2: shortReg(r)->q = rr_op( shortReg(r)->q, num4, flags ); break;
                }
            }
			else if( op[1]==0xFC ) {  // SLA A,r
				stats.sla++;
				switch(len) {
					case 0: *shortReg8(r)  = sll( *shortReg8(r), A,  flags ); break;
					case 1: *shortReg16(r) = sll( *shortReg16(r), A, flags ); break;
					case 2: shortReg(r)->q = sll( shortReg(r)->qs, A, flags ); break;
				}
			}
			else if( op[1]==0xEC ) {  // SLA #4,r
				op[2] = m.Rd8(pc.q++);
            	num4 = op[2];
            	stats.sla++;
				switch(len) {
					case 0: *shortReg8(r)  = sll( *shortReg8(r), num4, flags ); break;
					case 1: *shortReg16(r) = sll( *shortReg16(r), num4, flags ); break;
					case 2: shortReg(r)->q = sll( shortReg(r)->q, num4, flags ); break;
				}
			}
			else if( op[1]==0xFD ) {  // SRA A,r
				stats.sra++;
				switch(len) {
					case 0: *shortReg8(r)  = sra( *shortReg8(r), A,  flags ); break;
					case 1: *shortReg16(r) = sra( *shortReg16(r), A, flags ); break;
					case 2: shortReg(r)->q = sra( shortReg(r)->q, A, flags ); break;
				}
			}
			else if( op[1]==0xED ) {  // SRA #4,r
				op[2] = m.Rd8(pc.q++);
            	num4 = op[2];
            	stats.sra++;
				switch(len) {
					case 0: *shortReg8(r)  = sra( *shortReg8(r), num4, flags ); break;
					case 1: *shortReg16(r) = sra( *shortReg16(r), num4, flags ); break;
					case 2: shortReg(r)->q = sra( shortReg(r)->q, num4, flags ); break;
				}
			}
			else if( op[1]==0xFE ) {  // SLL A,r
				stats.sll++;
				switch(len) {
					case 0: *shortReg8(r)  = sll( *shortReg8(r), A,  flags ); break;
					case 1: *shortReg16(r) = sll( *shortReg16(r), A, flags ); break;
					case 2: shortReg(r)->q = sll( shortReg(r)->q, A, flags ); break;
				}
			}
			else if( op[1]==0xEE ) {  // SLL #4,r
				op[2] = m.Rd8(pc.q++);
            	num4 = op[2];
            	stats.sll++;
				switch(len) {
					case 0: *shortReg8(r)  = sll( *shortReg8(r), num4, flags ); break;
					case 1: *shortReg16(r) = sll( *shortReg16(r), num4, flags ); break;
					case 2: shortReg(r)->q = sll( shortReg(r)->q, num4, flags ); break;
				}
			}
			else if( op[1]==0xFF ) {  // SRL A,r
                stats.srl++;
                switch(len) {
                    case 0: *shortReg8(r)  = srl( *shortReg8(r), A,  flags ); break;
                    case 1: *shortReg16(r) = srl( *shortReg16(r), A, flags ); break;
                    case 2: shortReg(r)->q = srl( shortReg(r)->q, A, flags ); break;
                }
            }
            else if( op[1]==0xEF ) {  // SRL #4,r
				op[2] = m.Rd8(pc.q++);
            	num4 = op[2];
            	stats.srl++;
				switch(len) {
					case 0: *shortReg8(r)  = srl( *shortReg8(r), num4, flags ); break;
					case 1: *shortReg16(r) = srl( *shortReg16(r), num4, flags ); break;
					case 2: shortReg(r)->q = srl( shortReg(r)->q, num4, flags ); break;
				}
			}
			else if( op[1]==0x12 ) {  //  EXTZ r
				stats.extz++;
				switch(len) {
					case 0: break;
					case 1: *shortReg16(r) = (int16_t)*shortReg16(r) & 0x00ff; break;
					case 2: shortReg(r)->q = shortReg(r)->qs & 0x0000ffff; break;
				}
			}
			else if( op[1]==0x13 ) {  //  EXTS r
				stats.exts++;
				switch(len) {
					case 0: break;
					case 1: *shortReg16(r) = exts((int16_t)*shortReg16(r)); break;
					case 2: shortReg(r)->q = exts(shortReg(r)->qs); break;
				}
			}
			else if( op[1]==0x14 ) {  //  PAA r a + (a & 1)
				stats.paa++;
				switch(len) {
					case 0: *shortReg8(r)  = (int8_t)*shortReg8(r) + ((int8_t)*shortReg8(r) & 1 ); break;
					case 1: *shortReg16(r) = (int16_t)*shortReg16(r) + ((int16_t)*shortReg16(r) & 1); break;
					case 2: shortReg(r)->q = shortReg(r)->qs + (shortReg(r)->qs & 1); break;
				}
			}
			else if( op[1]==0x03 ) { // LD r,#
				auto aux = m.Rd32(pc.q);
				auto f2 = assign( r, len, aux );
				fetched += f2;
				pc.q += f2;
			}
			else if( op[1]==0xC8 ) { // ADD r,#
				auto aux = m.Rd32(pc.q);
				auto f2 = assignadd( r, len, aux );
				fetched += f2;
				pc.q += f2;
			}
			else if( op[1]==0xC9 ) { // ADC r,#
				auto aux = m.Rd32(pc.q);
				auto f2 = assignadc( r, len, aux );
				fetched += f2;
				pc.q += f2;
			}
			else if( op[1]==0xCF ) { // CP r,#
				auto aux = m.Rd32(pc.q);
				auto f2 = assigncp( r, len, aux );
				fetched += f2;
				pc.q += f2;
			}
			else if( op[1]==0xCA ) { // SUB r,#
				auto aux = m.Rd32(pc.q);
				auto f2 = assignsub( r, len, aux );
				fetched += f2;
				pc.q += f2;
			}
			else if( op[1]==0xCB ) { // SBC r,#
				auto aux = m.Rd32(pc.q);
				auto f2 = assignsbc( r, len, aux );
				fetched += f2;
				pc.q += f2;
				// printf("r=%X len=%X aux=%X \n",r,len,aux);
			}

		}
		return fetched;
	}
private:
	Reg32* shortReg( int r ) {
		switch(r&7) {
		case 0:  return &rf->xwa;
		case 1:  return &rf->xbc;
		case 2:  return &rf->xde;
		case 3:  return &rf->xhl;
		case 4:  return &xix;
		case 5:  return &xiy;
		case 6:  return &xiz;
		default: return &xsp;
		}
	}
	uint16_t* shortReg16( int r ) {
		switch(r) {
		case 0:  return &rf->xwa.w[0];
		case 1:  return &rf->xbc.w[0];
		case 2:  return &rf->xde.w[0];
		case 3:  return &rf->xhl.w[0];
		case 4:  return &xix.w[0];
		case 5:  return &xiy.w[0];
		case 6:  return &xiz.w[0];
		default: return &xsp.w[0];
		}
	}
	uint8_t* shortReg8( int r ) {
		switch(r) {
		case 0:  return &rf->xwa.b[1];
		case 1:  return &rf->xwa.b[0];
		case 2:  return &rf->xbc.b[1];
		case 3:  return &rf->xbc.b[0];
		case 4:  return &rf->xde.b[1];
		case 5:  return &rf->xde.b[0];
		case 6:  return &rf->xhl.b[1];
		default: return &rf->xhl.b[0];
		}
	}

	uint16_t* extReg16( int r ) {
		switch(r) {
		case 0: return &rf->xwa.w[0];
		case 1: return &rf->xwa.w[0];
		case 2: return &rf->xbc.w[0];
		case 3: return &rf->xbc.w[0];
		case 4: return &rf->xde.w[0];
		case 5: return &rf->xde.w[0];
		case 6: return &rf->xhl.w[0];
		default: return &rf->xhl.w[0];
		}
	}

	uint8_t* extReg8( int r ) {
		switch(r) {
		case 0: return &rf->xwa.b[0];
		case 1: return &rf->xwa.b[0];
		case 2: return &rf->xbc.b[0];
		case 3: return &rf->xbc.b[0];
		case 4: return &rf->xde.b[0];
		case 5: return &rf->xde.b[0];
		case 6: return &rf->xhl.b[0];
		default: return &rf->xhl.b[0];
		}
	}

	uint32_t assign( int r, int len, uint32_t v ) {
		stats.ld++;
		switch(len ) {
			case 0: *shortReg8(r)  = v; return 1;
			case 1: *shortReg16(r) = v; return 2;
			case 2: shortReg(r)->q = v; return 4;
		}
		return 0;
	}
	uint32_t assignadd( int r, int len, uint32_t v ) {
		stats.add++;
		switch(len ) {
			case 0: *shortReg8(r)  = add( (int8_t)*shortReg8(r), (int8_t)v, flags ); return 1;
			case 1: *shortReg16(r) = add( (int16_t)*shortReg16(r), (int16_t)v, flags ); return 2;
			case 2: shortReg(r)->q = add( shortReg(r)->qs, (int32_t)v, flags ); return 4;
		}
		return 0;
	}
	uint32_t assignadc( int r, int len, uint32_t v ) {
		stats.adc++;
		switch(len ) {
			case 0: *shortReg8(r)  = adc( (int8_t)*shortReg8(r), (int8_t)v, flags ); return 1;
			case 1: *shortReg16(r) = adc( (int16_t)*shortReg16(r), (int16_t)v, flags ); return 2;
			case 2: shortReg(r)->q = adc( shortReg(r)->qs, (int32_t)v, flags ); return 4;
		}
		return 0;
	}
	uint32_t assigncp( int r, int len, uint32_t v ) {
		stats.cp++;
		switch(len) {
			case 0: cp( (int8_t)*shortReg8(r), (int8_t)v,  flags ); return 1;
			case 1: cp( (int16_t)*shortReg16(r), (int16_t)v, flags ); return 2;
			case 2: cp( shortReg(r)->qs, (int32_t)v, flags ); return 4;
		}
		return 0;
	}
	uint32_t assignsub( int r, int len, uint32_t v ) {
		stats.sub++;
		switch(len ) {
			case 0: *shortReg8(r)  = sub( (int8_t)*shortReg8(r), (int8_t)v, flags ); return 1;
			case 1: *shortReg16(r) = sub( (int16_t)*shortReg16(r), (int16_t)v, flags ); return 2;
			case 2: shortReg(r)->q = sub( shortReg(r)->qs, (int32_t)v, flags ); return 4;
		}
		return 0;
	}
	uint32_t assignsbc( int r, int len, uint32_t v ) {
		stats.sbc++;
		switch(len ) {
			case 0: *shortReg8(r)  = sbc( (int8_t)*shortReg8(r), (int8_t)v, flags ); return 1;
			case 1: *shortReg16(r) = sbc( (int16_t)*shortReg16(r), (int16_t)v, flags ); return 2;
			case 2: shortReg(r)->q = sbc( shortReg(r)->qs, (int32_t)v, flags ); return 4;
		}
		return 0;
	}
};
