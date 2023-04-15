    ; calr
    maxmode on
    relaxed on
    org 0
    ld a,0xbf    ; common header

    ld xsp, stack
    calr check1
check2:
    jp bad_end
check1:
    cp xsp,stack-4
    jp ne,bad_end

    ld xwa,(xsp)
    cp xwa,check2
    jp ne, bad_end

end_loop:
    ld hl,0xbabe
    ld (0xffff),0xff
    jp end_loop
bad_end:
    ld hl,0xdead
    jp bad_end
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
stack:
    dw 0,0,0,0,0,0,0,0,0,0
    end