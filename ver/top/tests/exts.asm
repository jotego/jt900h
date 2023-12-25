    ; CPL
    maxmode on
    relaxed on
    org 0
    ld a,0xbf    ; common header

    ld a,0x12
    exts wa
    cp wa,0
    jp m,bad_end
    neg wa
    jp p,bad_end
    neg wa
    exts xwa
    cp xwa,0
    jp m,bad_end

    or b,1
    ld a,0x81
    neg a
    jp m,bad_end
    neg a
    exts wa
    cp wa,0
    jp p,bad_end
    exts xwa
    cp xwa,0
    jp p,bad_end

    or b,2
    ld de,0x7fff
    exts xde
    cp xde,0
    jp m,bad_end

    or b,4
    inc 1,de    ; de=0x8000
    exts xde
    cp xde,0
    jp p,bad_end

    or b,8
    include finish.inc
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    end