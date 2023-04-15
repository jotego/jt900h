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
stack:
    dw 0,0,0,0,0,0,0,0,0,0
    end