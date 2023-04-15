    main section code
    org 0
    ld wa,0xbf    ; common header

    ld xsp,0x00000000
    ld xiz,0x00000000
    ld xiy,xsp
    ld xix,xiz

    cp xiy,xix
    jp ne,bad_end
    cp xsp,xiz
    jp ne,bad_end

    ld xsp,0xffffffff
    ld xiz,0xffffffff
    ld xiy,xsp
    ld xix,xiz

    cp xiy,xix
    jp ne,bad_end
    cp xsp,xiz
    jp ne,bad_end

    sub xsp,xsp
    xor xiz,xiz
    ld xiy,xsp
    ld xix,xiz

    cp xiy,xix
    jp ne,bad_end
    cp xsp,xiz
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
    dw 0x0000, 0x0000, 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    end