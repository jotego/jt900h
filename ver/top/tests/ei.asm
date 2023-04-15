    ; ei / push SR
    main section code
    org 0
    ld a,0xbf    ; common header

    ld xsp, stack
    ei 1
    push sr
    ld a,(xsp+1)
    cp a,0x98
    jp ne,bad_end

    ei 4
    incf
    push sr
    ld a,(xsp+1)
    cp a,0xc9
    jp ne, bad_end

    ei 2
    incf
    push sr
    ld a,(xsp+1)
    cp a,0xaa
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
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
stack:
    dw 0,0,0,0,0,0,0,0,0,0
    end