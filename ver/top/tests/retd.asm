    ; call [cc],mem
    main section code
    org 0
    ld a,0xbf    ; common header

    ld xsp,stack
    ld wa,0xcafe
    push wa
    ld wa,0xbeef
    push wa
    call mymove
    ld wa,0xbabe
    cp xsp,stack
    jp ne,bad_end
    jp end_loop

mymove:
    ld bc,(xsp+4)
    ld de,(xsp+6)
    retd 4
    jp bad_end

end_loop:
    ldf 0
    ld hl,0xbabe
    ld (0xffff),0xff
    jp end_loop
bad_end:
    ld hl,0xdead
    ld (0xffff),0xff
    jp bad_end
data:
    dw 0x0011,0x2233,0x4455,0x6677,0x8899,0x0000,0x0000,0x0000
    dw 0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000
copy:
    dw 0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000
stack:
    end