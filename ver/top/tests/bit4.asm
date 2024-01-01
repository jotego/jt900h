    ; jump tests
    maxmode on
    relaxed on
    org 0

    ; Pocket Tennis checks bits beyond 7 in byte operands
    ; it looks like the way to handle this is to actually
    ; search the bit
    ld hl,0x4e0
    db 0xcf,0x33,0x0f   ; bit 0xf,l illegal encoding
    jp nz,bad_end
    db 0xcf,0x33,0x0e   ; bit 0xe,l illegal encoding
    jp nz,bad_end

    include finish.inc
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    end