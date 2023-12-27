    ; CALL #24
    maxmode on
    relaxed on
    org 0
    ld a,0xbf    ; common header

    ld xix,0xfff000
    ld xiy,orig
    ld bc,data-orig
    srl 1,bc
    jp c,bad_end        ; adjust so orig-data is an even number
    ldirw (xix+),(xiy+)
    call 0xfff000
    ldf 3
    sub xde,xbc
    cp xde,0x2222
    jp ne,bad_end
    ldf 0

    include finish.inc
    align 2
orig:
    ld xwa3,0x1b0a
    ld xbc3,0x3d2c
    ld xde3,0x5f4e
    ret
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    end