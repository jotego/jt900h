    ; PUSH F
    maxmode on
    relaxed on
    org 0
    ld a,0xbf    ; common header

    ld xsp, stack
    scf
    push f
    ld a,(xsp)
    and a,1
    jp eq,bad_end

    rcf
    push f
    ld b,(xsp)
    and b,1
    jp ne,bad_end


    include finish.inc
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
stack:
    dw 0,0,0,0,0,0,0,0,0,0
    end