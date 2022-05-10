    ; Unsigned multiplying
    main section code
    org 0
    ld a,0xbf    ; common header

    ld a,0x23
    ld c,0x56
    mul wa,c    ; $BC2
    cp wa,0x23*0x56
    jp ne,bad_end

    ld w,0x12
    ld a,0x67
    mul wa,a    ; $67*$67 = $2971
    cp wa,0x67*0x67
    jp ne,bad_end

    ld bc,0x1234
    ld a,0x67
    mul bc,a
    cp bc,0x34*0x67
    jp ne,bad_end

    ld de,0x7788
    ld l,0x33
    mul de,l
    cp de,0x88*0x33
    jp ne,bad_end

    ld hl,0xcafe
    ld w,0x15
    mul hl,w
    cp hl,0xfe*0x15
    jp ne,bad_end

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