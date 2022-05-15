    ; PUSH<W> #
    main section code
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