    ; POP<W> (mem)
    main section code
    org 0
    ld a,0xbf    ; common header

    ld xsp,0x600
    ld xix,0x400

    ; Set known values to the RAM
    ld xwa,0
    ld (xix),xwa
    ld xwa,0x12345678
    ld (xsp),xwa
    sub xwa,xwa

    ld a,(xsp)
    popb (xix)
    cpb (xix),0x78
    jp ne,bad_end
    ld w,(xix)
    or ra3,1

    inc 1,xsp
    inc 2,xix
    popw (xix)
    cpw (xix),0x1234
    jp ne,bad_end
    ld bc,(xix)
    or ra3,2

end_loop:
    ld hl,0xbabe
    ld (0xffff),0xff
    jp end_loop
bad_end:
    ld hl,0xdead
    ld (0xffff),0xff
    jp bad_end
    align 2
    end