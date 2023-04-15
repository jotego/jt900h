    ; Immediate value multiplying
    maxmode on
    relaxed on
    org 0
    ld a,0xbf    ; common header

    ld a,0x23
    mul wa,0x10
    cp wa,0x23*0x10
    jp ne,bad_end
    or ra1,1

    ld de,0x1324
    mul xde,0x2367
    cp xde,0x1324*0x2367
    jp ne,bad_end
    or ra1,2

    ; Signed mul
    ld a,0x8
    muls wa,0xff
    cp wa,0xfff8
    jp ne,bad_end
    or ra1,4

    ld bc,0x100
    muls xbc,0xfffe
    cp xbc,0xfffffe00
    jp ne,bad_end
    or ra1,8

end_loop:
    ld hl,0xbabe
    ld (0xffff),0xff
    jp end_loop
bad_end:
    ld hl,0xdead
    ld (0xffff),0xff
    jp bad_end
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    dw 0,0,0,0,0,0,0,0,0,0
    end