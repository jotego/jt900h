    ; call
    main section code
    org 0
    ld a,0xbf    ; common header

    ld (0x00),5
    ldf 0
    ld a,0x08
    res 3,a
    cp a,0x00
    jp ne,bad_end
    ld (0x67),0x00
    res 0,(0x67)
    ld xbc,(0x67)
    cp c,0x00
    jp ne,bad_end
    call sum
    ld wa,0x12
    cp wa,0x21
    jp eq,bad_end
    jp ne,end_loop
sum:
    ld de,0x3421
    cp de,0x3421
    jp ne,bad_end
    ret
end_loop:
    ld hl,0xbabe
    ld (0xffff),0xff
    jp end_loop
bad_end:
    ld hl,0xdead
    jp bad_end
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
stack:
    dw 0,0,0,0,0,0,0,0,0,0
    end