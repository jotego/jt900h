    ; overflow tests
    maxmode on
    relaxed on
    org 0
    ld a,0xbf    ; common header

    ; 8-bit operands
    ; no overflow add
    ld a,0x40
    add a,0x3f  ; a=0x7f
    jp ov,bad_end
    cp a,0x7f
    jp ne,bad_end
    or xiy,1

    ; overflow add
    ld w,0x7f
    add w,1 ; w=0x80=-128
    jp nov,bad_end
    or xiy,2

    ; no overflow sub
    ld b,0xff
    sub b,1      ; b=0xfe=-2
    jp ov,bad_end
    or xiy,4

    ; overflow sub
    ld c,0x80
    sub c,1      ; c=0x7f=127
    jp nov,bad_end
    or xiy,8

    ; 16-bit operands
    incf
    ld wa,0x7ffe
    ld hl,1
    add wa,hl
    jp ov,bad_end
    or xiy,0x10

    ld bc,0x8000
    sub bc,hl
    jp nov,bad_end
    or xiy,0x20

    ; 32-bit operands
    incf
    ld xwa,0x7ffffffe
    ld xhl,1
    add xwa,xhl
    jp ov,bad_end
    or xiy,0x40

    ; the assembler introduces an unknown (for now)
    ; ed26 instruction after the ld xbc, and ruins
    ; the test, so I comment it out for now
    ; ld xbc,0xffff8000
    ; sub xbc,xhl
    ; jp nov,bad_end
    ; or xiy,0x80

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
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    end