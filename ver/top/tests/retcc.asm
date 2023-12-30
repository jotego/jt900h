    ; ret cc
    maxmode on
    relaxed on
    org 0
    ld a,0xbf    ; common header

    ld xsp,stack
    call noret
    jp bad_end

noret:
    ld qh,1
    ld a,1
    add a,1
    ret c
    ret z
    ret ov

    ld qh,2
    sub a,3
    ret p
    ret nc

    ld qh,3
    sub a,a
    ret nz


    ld qh,4
    ld xix,doret1
    push xix
    rcf
    ret nc
    jp bad_end
doret1:
    ld qh,5
    ld xix,doret2
    push xix
    scf
    ret c
    jp bad_end
doret2:
    ld qh,6
    ld xix,doret3
    push xix
    ld a,4
    dec 4,a
    ret z
    jp bad_end
doret3:

    include finish
data:
    dw 0x0011,0x2233,0x4455,0x6677,0x8899,0x0000,0x0000,0x0000
    dw 0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000
copy:
    dw 0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000
stack:
    end