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
		std::memset( p, 0, 0x10'00000 );
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

struct T900H {
	Reg32 xix,xiy,xiz,xsp, pc;
	struct Bank{
		Reg32 xwa,xbc,xde,xhl;
	} rr[4];
	Bank *rf;
	int rfp; // Register File Pointer
	void Reset(Mem& m) {
		pc.q = m.Rd32(0xffff00);
		for( int k=0;k<4; k++ ) {
			rr[k].xwa.q = rr[k].xbc.q = rr[k].xde.q = rr[k].xhl.q = 0;
		}
		xix.q = xiy.q = xiz.q = 0;
		xsp.q = 0x100;
		rfp = 0;
		rf=&rr[0];
	}
	int Exec(Mem &m) {
		uint8_t op[12];
		op[0] = m.Rd8(pc.q++);
		int fetched=1;
		int r,R, len;
		if( MASKCP(op[0],0xc8) && !MASKCP(op[0],0x30) ) {
			r = op[0]&7;
			len = (op[0]>>4)&3;
			op[1] = m.Rd8(pc.q++);
			fetched++;
			if( MASKCP2(op[1],0xF8,0x80) ) {  // ADD R,r
				R = op[1]&7;
				switch(len) {
					case 0: *shortReg8(R)  += *shortReg8(r); break;
					case 1: *shortReg16(R) += *shortReg16(r); break;
					case 2: shortReg(R)->q += shortReg(r)->q; break;
				}
			}
			if( MASKCP2(op[1],0xF8,0x88) ) {  // LD R,r
				R = op[1]&7;
				switch(len) {
					case 0: *shortReg8(R)  = *shortReg8(r); break;
					case 1: *shortReg16(R) = *shortReg16(r); break;
					case 2: *shortReg(R)   = *shortReg(r); break;
				}
			}
			if( op[1]==0x03 ) { // LD r,#
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
