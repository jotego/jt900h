    ; Arithmetic operations that read & write to memory
    main section code
    org 0
    ld a,0xbf    ; common header

    ld (xwa),0x00
    ld (xwa+),0x00
    ld a,0x01 
    incw 2,(xwa)
    ld xwa,(xwa+2)
    cp a,0
    jp ne,bad_end
    or ra3,1

    ld (xwa),0x1234
    incw 5,(xwa)
    ld xwa,(xwa+5)
    cp a,0xf5
    jp ne,bad_end
    or ra3,2

    ld (xix),0x00
    ld (xix+),0x00
    ld xix,0x01 
    incw 2,(xix)
    ld xix,(xix+2)
    cp xix,0
    jp eq,bad_end
    or ra3,1

    ld (xix),0x1234
    incw 5,(xix)
    ld xix,(xix+5)
    cp xix,0xf5
    jp eq,bad_end
    or ra3,2

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