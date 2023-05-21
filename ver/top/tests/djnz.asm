    ; CPL
    maxmode on
    relaxed on
    org 0
    ld a,0xbf    ; common header

    ld a,0x12
    ld w,3
loop:
    add a,a
    nop
    djnz w,loop
    ld b,a
    sub a,0x90
    jp ne,bad_end

    include finish.inc
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    end