    ; PUSH<W> #
    main section code
    org 0
    ld a,0xbf    ; common header

    ld xsp, stack
    pushw 0x1234
    ld wa,(xsp)
    cp wa,0x1234
    jp ne, bad_end

    push 0xca
    ld b,(xsp)
    cp b,0xca
    jp ne,bad_end

    ld xde,stack
    sub xde,3
    cp xsp,xde
    jp ne,bad_end

end_loop:
    ld hl,0xbabe
    ld (0xffff),0xff
    jp end_loop
bad_end:
    ld hl,0xdead
    jp bad_end
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
stack:
    dw 0,0,0,0,0,0,0,0,0,0
    end