    ; Arithmetic operations that read & write to memory
    maxmode on
    relaxed on
    org 0

    ldf 2

    ld qh,1
    ld a,0x7f
    inc 3,a
    jp nov,bad_end
    jp p,bad_end
    cp a,0x82
    jp ne,bad_end
    or ra3,1

    ld qh,2
    ld a,0x10
    inc 1,a
    jp c,bad_end
    jp z,bad_end
    cp a,0x11
    jp ne,bad_end

    ; inc #3,r on word/long word should not change the flags
    ld qh,3
    ld wa,0x7fff
    inc 3,wa
    jp ov,bad_end
    cp wa,0x8002
    jp ne,bad_end

    ld qh,4
    ld xwa,0
    cpl wa
    cpl qwa
    inc 1,xwa
    jp ov,bad_end
    and xwa,xwa
    jp nz,bad_end

    ld qh,5
    ld xwa,-1
    or xwa,xwa      ; set flags
    jp z,bad_end
    jp nov,bad_end
    inc 1,xwa       ; flags should not change
    jp z,bad_end
    jp nov,bad_end
    or xwa,xwa
    jp nz,bad_end


    ; inc #3,(mem) should change the flags
    ld qh,6
    lda xix,data
    ld b,(xix)
    inc 3,(xix)
    jp z,bad_end
    jp m,bad_end
    ld c,(xix)
    sub c,b
    cp c,3
    jp ne,bad_end

    ld qh,7
    ldb (xix),0x7f
    inc 1,(xix)
    jp nov,bad_end
    cp (xix),0x80
    jp ne,bad_end

    ld qh,8
    ldw (xix),0xfff8
    incw 8,(xix)
    jp nz,bad_end

    include finish.inc
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    end