    ; POPSR
    maxmode on
    relaxed on
    org 0
    ld a,0xbf    ; common header

    ld xsp, stack
    ld xwa, test_sr
    push xwa
    ld wa,0x3ff
    push wa
    reti
    jp bad_end

test_sr:
    jp nc, bad_end
    jp nz, bad_end
    include finish.inc
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    dw 0,0,0,0,0,0,0,0,0,0
    align 4
stack:
    end