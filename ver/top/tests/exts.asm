    ; CPL
    maxmode on
    relaxed on
    org 0
    ld a,0xbf    ; common header

    ld a,0x12
    exts wa
    sub w,0
    jp ne,bad_end

    or b,1
    ld a,0x80
    exts wa
    sub w,0
    jp eq,bad_end

    or b,2
    ld de,0x7fff
    exts xde
    sub xde,0x7fff
    jp ne,bad_end

    or b,4
    ld de,0x8000
    exts xde
    sub xde,0
    jp eq,bad_end

    or b,8
    include finish.inc
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    end