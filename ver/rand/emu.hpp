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
	flags &= FLAG_NH; // H=1
	flags &= FLAG_NN; // N=0
	flags &= FLAG_NC; // C=0
	parity( rs, flags );
	set_sz( rs, flags );
	return rs;
}

template <typename T> T xor_op( T a, T b, uint8_t &flags ) {
	T rs = a ^ b;
	flags &= FLAG_NH; // H=1
	flags &= FLAG_NN; // N=0
	flags &= FLAG_NC; // C=0
	parity( rs, flags );
	set_sz( rs, flags );
	return rs;
}

template <typename T> T extz( T a ) {
	T rs;
	if (sizeof(T)==2)
		rs = a & 0x00ff;
	else
		rs = a & 0x0000ffff;
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
		int ld, add, ccf, decf, incf, rcf, scf, zcf, and_op, or_op, xor_op, adc, extz, exts;
	} stats;
	Bank *rf;
	int rfp; // Register File Pointer
	uint8_t flags,fdash;
	void Reset(Mem& m) {
		pc.q = m.Rd32(0xffff00);
		for( int k=0;k<4; k++ ) {
			rr[k].xwa.q = rr[k].xbc.q = rr[k].xde.q = rr[k].xhl.q = 0;
		}
		xix.q = xiy.q = xiz.q = 0;
		xsp.q = 0x100;
		rfp = 0;
		rf=&rr[0];
		flags = fdash = 0;
		memset(&stats,0,sizeof(stats));
	}
	int Exec(Mem &m) {
		uint8_t op[12];
		op[0] = m.Rd8(pc.q++);
		int fetched=1;
		int r,R, len;
		if( op[0]==0x12 ) { stats.ccf++;  flags &= FLAG_NN; flags = flags ^ 1; } // CCF
		if( op[0]==0x11 ) { stats.scf++;  flags &= FLAG_NH; flags &= FLAG_NN; flags |= FLAG_C;} // SCF
		if( op[0]==0x10 ) { stats.rcf++;  flags &= FLAG_NH; flags &= FLAG_NN; flags &= FLAG_NC;} // RCF
		if( op[0]==0x13 ) { stats.zcf++;  flags &= FLAG_NN; if ( flags & FLAG_Z ) flags &= FLAG_NC; else flags |= FLAG_C; } // ZCF
		if( op[0]==0x0C ) { stats.incf++; rfp++; rfp&=3; rf=&rr[rfp]; } // INCF
		if( op[0]==0x0D ) { stats.decf++; rfp--; rfp&=3; rf=&rr[rfp]; } // DECF
		if( MASKCP(op[0],0xc8) && !MASKCP(op[0],0x30) ) {
			r = op[0]&7;
			len = (op[0]>>4)&3;
			op[1] = m.Rd8(pc.q++);
			R = op[1]&7;
			fetched++;
			if( MASKCP2(op[1],0xF8,0x80) ) {  // ADD R,r
				stats.add++;
				switch(len) {
					case 0: *shortReg8(R)  = add( (int8_t)*shortReg8(R), (int8_t)*shortReg8(r),  flags ); break;
					case 1: *shortReg16(R) = add( (int16_t)*shortReg16(R), (int16_t)*shortReg16(r), flags ); break;
					case 2: shortReg(R)->q = add( shortReg(R)->qs, shortReg(r)->qs, flags ); break;
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
			else if( op[1]==0x12 ) {  //  EXTZ r
				stats.extz++;
				switch(len) {
					case 0: break;
					case 1: *shortReg16(r) = extz((int16_t)*shortReg16(r)); break;
					case 2: shortReg(r)->q   = extz(shortReg(r)->qs); break;
				}
			}
			else if( op[1]==0x13 ) {  //  EXTS r
				stats.exts++;
				switch(len) {
					case 0: break;
					case 1: *shortReg16(r) = exts((int16_t)*shortReg16(r)); break;
					case 2: shortReg(r)->q   = exts(shortReg(r)->qs); break;
				}
			}
			else if( op[1]==0x03 ) { // LD r,#
				auto aux = m.Rd32(pc.q);
				auto f2 = assign( r, len, aux );
				fetched += f2;
				pc.q += f2;
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
	uint32_t assign( int r, int len, uint32_t v ) {
		switch(len ) {
			case 0: *shortReg8(r)  = v; return 1;
			case 1: *shortReg16(r) = v; return 2;
			case 2: shortReg(r)->q = v; return 4;
		}
		return 0;
	}
};
