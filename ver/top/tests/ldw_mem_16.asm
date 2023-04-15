    main section code
    org 0
    ld a,0xbf    ; common header

    ld xix,(data+2)
    ld xwa,0x1234

    ld (xix),(65535)
    ld (xde),(4095)
    ld (xbc),(255)
    ld (xwa),(15)

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
    end