    ; LDD
    maxmode on
    relaxed on
    org 0
    ld a,0xbf    ; common header

    ; ESTIMULAR IDX_RDREG_AUX Y IDX_RDREG_SEL (luego borrar comentario)
    
    ; ldf 0
    ldf 0
    ld a,3
    cp a,3
    jp ne,bad_end
    ldf 1
    ld c,1
    cp c,1
    jp ne,bad_end
    ldf 0
    ld a,2
    cp a,4
    jp eq,bad_end

    ; ldd (r32+r8) (r8=1)
    ld xwa,0xffffffff
    ld (xwa+a),xwa
    ld xbc,(xwa+a)
    cp xbc,0xffffffff
    jp ne,bad_end

    ; ldd (r32+r8) (r8=0)
    ld xwa,0x00000000
    ld (xwa+a),xwa
    ld xbc,(xwa+a)
    cp xbc,0x00000000
    jp ne,bad_end

    ; ldd (r32+r16) (r16=1)
    ld xwa,0x00000000
    ld (xwa+wa),xwa
    ld xbc,(xwa+wa)
    cp xbc,0x00000000
    jp ne,bad_end

    ; ldd (r32+r16) (r16=0)
    ld xwa,0x00000000
    ld (xwa+wa),xwa
    ld xbc,(xwa+wa)
    cp xbc,0x00000000
    jp ne,bad_end

end_loop:
    ldf 0
    ld hl,0xbabe
    ld (0xffff),0xff
    jp end_loop
bad_end:
    ld hl,0xdead
    ld (0xffff),0xff
    jp bad_end
data:
    dw 0x0011,0x2233,0x4455,0x6677,0x8899,0x0000,0x0000,0x0000
    dw 0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000
copy:
    dw 0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000
    end