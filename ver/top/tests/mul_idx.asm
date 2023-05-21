    ; Immediate value multiplying
    maxmode on
    relaxed on
    org 0
    ld a,0xbf    ; common header

    ld xix,data

    ld a,0x23
    mul wa,(xix)
    cp wa,0x23*0xfe
    jp ne,bad_end
    or ra1,1

    ld de,0x1324
    mul xde,(xix+2)
    cp xde,0x1324*0xbeef
    jp ne,bad_end
    or ra1,2

    ld bc,8
    muls bc,(xix+4)
    cp bc,0xfff8
    jp ne,bad_end
    or ra1,4

    include finish.inc
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    dw 0,0,0,0,0,0,0,0,0,0
    end