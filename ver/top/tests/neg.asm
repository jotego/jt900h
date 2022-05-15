    ; Arithmetic operations that read & write to memory
    main section code
    org 0
    ld a,0xbf    ; common header

    ld a,0x23
    neg a
    add a,0x23
    jp ne,bad_end
    ld bc,1
    neg bc
    cp bc,0xffff
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
    end