    main section code
    org 0
    ld wa,0xbf    ; common header

    incf ; bank 1

    ld xsp,0xffffffff
    cp xsp,0xfff1
    jp eq,bad_end
    ld xsp,0x00000000
    cp xsp,0xffffffff
    jp eq,bad_end

    incf ; bank 2

    ld xsp,0xffffffff
    cp xsp,0xffffffff
    jp ne,bad_end
    ld xsp,0x00000000
    cp xsp,0x00120000
    jp eq,bad_end

    incf ; bank 3

    ld xiy,0xffffffff
    cp xiy,xwa
    jp eq,bad_end
    ld xiy,0x00000000
    cp xiy,0x00
    jp ne,bad_end

    ld xsp,0xffffffff
    cp xsp,xiy
    jp eq,bad_end
    ld xsp,0x00000000
    cp xsp,xiy
    jp ne,bad_end

    incf ; bank 0

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