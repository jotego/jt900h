    ; Unsigned multiplying
    main section code
    org 0
    ld a,0xbf    ; common header

    ld a,0x23
    ld c,0x56
    muls wa,c    ; $BC2
    cp wa,0x23*0x56
    jp ne,bad_end
    or ra1,1

    ld w,0x82
    ld a,0x67
    muls wa,w
    cp wa,0xff82*0x67
    jp ne,bad_end
    or ra1,2

    ld bc,0x1234
    ld a,0xff
    muls bc,a
    cp bc,0xffcc
    jp ne,bad_end
    or ra1,4

    ld de,0x7788
    ld l,0x33
    muls de,l
    cp de,0xff88*0x33
    jp ne,bad_end
    or ra1,8

    ld hl,0xff
    ld w,0xfe
    muls hl,w
    cp hl,2
    jp ne,bad_end
    or ra1,0x10

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