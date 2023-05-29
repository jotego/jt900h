    ; CP (mem),R
    maxmode on
    relaxed on
    org 0
    ld xix,data
    ld wa,0
    cp (xix+4),wa   ; 0xffff-0
    jp ule,bad_end  ; ULE = unsigned less or equal: carry or zero set

    include finish.inc
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    end