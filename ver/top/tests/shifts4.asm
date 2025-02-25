    ; general shift test
    maxmode on
    relaxed on
    org 0
    ld a,0xbf    ; common header

    ld wa,0

    ld d,1
    ld a,1
    rcf
    rrc a,d
    jp nc,bad_end
    cp d,0x80
    jp ne,bad_end
    inc 1,w

    ld d,0x80
    rcf
    rl a,d
    jp nc,bad_end
    jp ne,bad_end
    inc 1,w

    ld d,1
    ld a,2
    scf
    rr a,d
    jp c,bad_end
    cp d,0xc0
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