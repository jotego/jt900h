    ; PUSH<W> #
    maxmode on
    relaxed on
    org 0
    ld a,0xbf    ; common header

    ld xix,data
    ld xsp, stack
    pushw (xix)

    ld wa,(xsp)
    ld bc,(xix+)
    cp wa,bc
    jp ne,bad_end

    pushb (xix)
    ld d,(xsp)
    ld e,(xix)
    cp d,e
    jp ne,bad_end

    incf
    ld xde,stack
    sub xde,3
    cp xsp,xde
    jp ne,bad_end

    include finish.inc
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
stack:
    dw 0,0,0,0,0,0,0,0,0,0
    end