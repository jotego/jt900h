    ; Arithmetic operations that read & write to memory
    main section code
    org 0
    ld a,0xbf    ; common header

    ; LDCF #4, r
    ld wa,0x115
    ldcf 0,a

    ld b,0
    adc b,0
    cp b,1
    jp ne,bad_end

    ldcf 1,a
    jp c,bad_end

    ldcf 8,wa
    jp nc,bad_end

    ; LDCF A,r
    or e,1
    ld bc,0xa55
    ld A,1
    ldcf A,c
    jp c,bad_end

    ld A,11
    ldcf A,bc
    jp nc,bad_end

    ; LDCF #3,(mem)
    or e,2
    lda xix,data
    ldcf 0,(xix)
    jp c, bad_end
    ldcf 1,(xix)
    jp nc, bad_end

    ; LDCF A,(mem)
    or e,4
    ld A,0
    ldcf A,(xix)
    jp c, bad_end
    ld A,1
    ldcf A,(xix)
    jp nc, bad_end


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