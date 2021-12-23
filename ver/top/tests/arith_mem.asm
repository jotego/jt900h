    ; Arithmetic operations that read & write to memory
    main section code
    org 0
    ld a,0xbf    ; common header

    lda xix,data
    ld a,1
    add (xix),a
    ld b,(xix+)
    cp b,0xff
    jp ne,bad_end

    ld c,(xix)
    add c,0x10
    cp c,0xda
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
    end