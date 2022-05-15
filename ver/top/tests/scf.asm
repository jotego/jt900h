    ; set/reset/~zero to carry flag
    main section code
    org 0
    ld a,0xbf    ; common header

    jp c,bad_end
    scf
    jp nc,bad_end
    rcf
    jp c,bad_end

    ld a,0
    add a,a
    jp nz,bad_end
    zcf
    jp c,bad_end
    add a,1
    jp z,bad_end
    zcf
    jp nc,bad_end

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