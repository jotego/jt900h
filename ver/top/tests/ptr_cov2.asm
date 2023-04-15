    main section code
    org 0
    ld wa,0xbf    ; common header

    ld qspl,0x00
    ld sph,0x00
    cp a,sph
    jp eq,bad_end
    cp a,qspl
    jp eq,bad_end

    ld a,0xff
    ld c,0x01
    ld qspl,0xff
    ld sph,0xff
    cp a,sph
    jp ne,bad_end
    cp c,qspl
    jp eq,bad_end

    ld qspl,0x00
    ld sph,0x00
    cp a,qspl
    jp eq,bad_end
    ld a,0x00
    cp a,qspl
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