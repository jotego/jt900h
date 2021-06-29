//JT900H header
//TLCS-900H based
#include <stdint.h>

struct TLCS900H_TimingPins{
    int X1, CLK, nCS, R, Wn, A, ALE, AD_r, RDn_mxb, AD_w, HWRn_mxb, D_r, RDn_spb, D_w, HWRn_spb, WAITn; 
};

struct TLCS900H_Registers{
    uint32_t xwa[4], xbc[4], xde[4], xhl[4], xix, xiy, xiz, xsp, pc;
    uint32_t dmas[4], dmad[4], dmac[4],dmam[4];
    uint16_t sr, intnest;
    uint8_t f[2];
};

void TLCS_reset(TLCS900 *rst){

}