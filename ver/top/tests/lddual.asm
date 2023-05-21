    ; LD data read from memory into memory
    maxmode on
    relaxed on
    org 0
    ld a,0xbf    ; common header

    ld a,0

    ldw (data),0x1234
    ld xix,data
    ld de,(xix)
    cp de,0x1234
    jp ne,bad_end

    incf
    ld (data),0x55
    ld d,(xix)
    cp d,0x55
    jp ne,bad_end

    include finish.inc
    align 2
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    dw 0,0,0,0,0,0,0,0,0,0
    align 4
stack:
    end