    ; Arithmetic operations that read & write to memory
    main section code
    org 0
    ld a,0xbf    ; common header

    ld a,7
    inc 3,a
    cp a,10
    jp ne,bad_end
    or ra3,1

    inc 1,a
    cp a,11
    jp ne,bad_end
    or ra3,2

    lda xix,data
    ld b,(xix)
    inc 3,(xix)
    ld c,(xix)
    sub c,b
    cp c,3
    jp ne,bad_end
    or ra3,4

    ldf 3
    ldw (xix),0
    incw 3,(xix)
    ld bc,(xix)
    cp (xix),3
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
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    end