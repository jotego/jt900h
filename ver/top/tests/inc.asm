    ; Arithmetic operations that read & write to memory
    main section code
    org 0
    ld a,0xbf    ; common header

    ld a,7
    inc 3,a
    cp a,10
    jp ne,bad_end

    inc 1,a
    cp a,11
    jp ne,bad_end

    lda xix,data
    ld b,(xix)
    inc 3,(xix)
    ld c,(xix)
    sub c,b
    cp c,3
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