    ; general shift test
    main section code
    org 0
    ld a,0xbf    ; common header

    ld xix,data
    ld wa,(xix)
    rl 1,wa
    rlw (xix)
    cp wa,(xix)
    jp ne,bad_end
    or ra3,1

    scf
    rlc 1,wa
    scf
    rlcw (xix)
    cp wa,(xix)
    jp ne,bad_end
    or ra3,2

    rr 1,wa
    rrw (xix)
    cp wa,(xix)
    jp ne,bad_end
    or ra3,4

    scf
    rrc 1,wa
    scf
    rrcw (xix)
    cp wa,(xix)
    jp ne,bad_end
    or ra3,8

end_loop:
    ld hl,0xbabe
    ld (0xffff),0xff
    jp end_loop
bad_end:
    ld hl,0xdead
    ld (0xffff),0xff
    jp bad_end

data:
    db 0x81,0x3,0x6,0xc,0x18,0x30,0x60,0xc0
    db 0x81,0x3,0x6,0xc,0x18,0x30,0x60,0xc0
    db 0x81,0x3,0x6,0xc,0x18,0x30,0x60,0xc0
    db 0x81,0x3,0x6,0xc,0x18,0x30,0x60,0xc0
    dw 0xffff,0xffff,0xffff,0xffff
stack:
    end