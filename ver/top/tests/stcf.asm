    ; Store carry flag
    main section code
    org 0
    ld a,0xbf    ; common header

    ; STCF #4,r
    scf
    stcf 1,w
    cp w,2
    jp ne,bad_end
    scf
    stcf 7,w
    cp w,0x82
    jp ne,bad_end
    rcf
    stcf 7,w
    cp w,2
    jp ne,bad_end
    or ra1,1

    ; STCF A,r
    ld a,2
    ld c,0x88
    scf
    stcf a,c
    cp c,0x8c
    jp ne,bad_end
    or ra1,2

    rcf
    stcf a,c
    cp c,0x88
    jp ne,bad_end
    or ra1,4

    ; STCF #3,(mem)
    ld xix,data
    rcf
    stcf 3,(xix)
    ld a,0xf6
    cp a,(xix)
    jp ne,bad_end
    or ra1,8

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