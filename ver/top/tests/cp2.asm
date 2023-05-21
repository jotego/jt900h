    ; CPL
    maxmode on
    relaxed on
    org 0
    ld a,0xbf    ; common header

    ld xix,data
    ld a,1
    ld b,0xfe
    cp b,(xix)
    jp ne,bad_end

    ld w,1
    ld b,0xca
    ld h,0
    cp b,(xix+1)
    jp ne,bad_end
    inc 1,w

    cp b,(xix+a)
    jp ne,bad_end
    inc 1,w

    include finish.inc
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    end