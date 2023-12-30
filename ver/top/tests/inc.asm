    ; Arithmetic operations that read & write to memory
    maxmode on
    relaxed on
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
    incw bp3,(xix)
    ld bc,(xix)
    cpw (xix),3
    jp ne,bad_end
    or ra3,8

    include finish.inc
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    end