    ; general shift test
    maxmode on
    relaxed on
    org 0
    ld a,0xbf    ; common header

    ld a,0
    ld w,0

    ld d,1
    rlc 1,d
    cp d,2
    jp ne,bad_end
    inc 1,w

    srl 1,d
    cp d,1
    jp ne,bad_end
    inc 1,w

    ld d,0x80
    sla 1,d
    jp nc,bad_end
    jp nz,bad_end
    inc 1,w

    ld d,2
    sll 1,d
    cp d,4
    jp ne,bad_end
    inc 1,w

    ld d,0x80
    sra 3,d
    cp d,0xf0
    jp ne,bad_end
    inc 1,w

    ld d,0x80
    scf
    srl 1,d
    cp d,0x40
    jp ne,bad_end
    inc 1,w

    include finish.inc

data:
    db 0x81,0x3,0x6,0xc,0x18,0x30,0x60,0xc0
    db 0x81,0x3,0x6,0xc,0x18,0x30,0x60,0xc0
    db 0x81,0x3,0x6,0xc,0x18,0x30,0x60,0xc0
    db 0x81,0x3,0x6,0xc,0x18,0x30,0x60,0xc0
    dw 0xffff,0xffff,0xffff,0xffff
stack:
    end