    ; POPSR
    main section code
    org 0
    ld a,0xbf    ; common header

    ld xsp, stack
    ld wa,0x3ff
    push wa
    pop sr
    ld bc,3
    ld wa,0x2ff
    push wa
    pop sr
    ld bc,2
    ld wa,0x100
    push wa
    pop sr
    ld bc,1

end_loop:
    ld hl,0xbabe
    ld (0xffff),0xff
    jp end_loop
bad_end:
    ld hl,0xdead
    jp bad_end
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    dw 0,0,0,0,0,0,0,0,0,0
stack:
    end