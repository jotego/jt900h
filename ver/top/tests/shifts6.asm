    ; general shift test
    maxmode on
    relaxed on
    org 0
    ld a,0xbf    ; common header

    ld xix,data
    ld a,1
    ld bc,(xix)
    sla a,bc
    slaw (xix)
    cp bc,(xix)
    jp ne,bad_end
    or ra3,1

    sll a,bc
    sllw (xix)
    cp bc,(xix)
    jp ne,bad_end
    or ra3,2

    sra a,bc
    sraw (xix)
    cp bc,(xix)
    jp ne,bad_end
    or ra3,4

    srl 1,bc
    srlw (xix)
    cp bc,(xix)
    jp ne,bad_end
    or ra3,8

    include finish.inc

data:
    db 0x81,0x3,0x6,0xc,0x18,0x30,0x60,0xc0
    db 0x81,0x3,0x6,0xc,0x18,0x30,0x60,0xc0
    db 0x81,0x3,0x6,0xc,0x18,0x30,0x60,0xc0
    db 0x81,0x3,0x6,0xc,0x18,0x30,0x60,0xc0
    dw 0xffff,0xffff,0xffff,0xffff
stack:
    end