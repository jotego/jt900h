    ; call[cc],mem
    main section code
    org 0
    ld wa,0xbf    ; common header

    ld xsp,stack
    ld xwa,data
    push wa
    ld xwa,data+2
    push wa
    call loop
    ld xwa,data+4
    cp xsp,stack
    jp ne,bad_end
    jp end_loop

loop:
    ld bc,(xsp+4)
    ld de,(xsp+6)
    retd 4
    jp bad_end

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
stack:
    end