    maxmode on
    relaxed on
    org 0
    ld a,0xbf    ; common header

    ; SBC (mem),R

    ld xwa,0x02
    ld xbc,xwa
    ld xde,0x01

    sbc (xwa),xde
    jp nc,bad_end
    or a,4

    sbc (xwa),xde
    jp nc,bad_end
    or xbc,0x01

    ld a,0

    xorcf a,bc
    jp nc,bad_end
    or a,8

end_loop:
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