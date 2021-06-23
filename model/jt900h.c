#include "jt900h.h"

void TLCS900_reset( TLCS900 *tlcs ) {
    tlcs->pc=0;
    tlcs->RDn = 1;
    tlcs->WRn = 1;
    tlcs->Dout = 0;
}

void TLCS900_clkedge( TLCS900 *tlcs ) {
    //
}