struct TLCS900_bank {
    int xwa, xbc, xde, xhl, xix, xiy, xiz, xsp;    
};

struct TLCS900_pins {
    int A, CLK, Din, Dout, RDn, WRn, WAITn;
};

struct TLCS900 {
    TLCS900_bank banks[4];
    int pc, sr;
    int f[2];

    TLCS900_pins pins;
};

void TLCS900_reset( TLCS900 *tlcs );
void TLCS900_clkedge( TLCS900 *tlcs );