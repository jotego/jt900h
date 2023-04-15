    ; PUSH F
    maxmode on
    relaxed on
    org 0
    ld a,0xbf    ; common header

    ld xsp, stack
    ld a,0xff
    push a
    pop f

    jp nc,bad_end
    jp nov,bad_end
    jp ne,bad_end

    ld a,0
    push a
    pop f

    jp c,bad_end
    jp ov,bad_end
    jp eq,bad_end

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
    dw 0,0,0,0,0,0,0,0,0,0
stack:
    end