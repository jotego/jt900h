; SUB, check that operand order is correct
; in all SUB using instructions
    maxmode on
    relaxed on
    org 0

    ld xix,data
    ld d,(xix)
    inc 1,d

    ; reg,(mem)
    ld c,d
    sub c,(xix)
    jp mi,bad_end
    ld c,d
    ccf
    sbc c,(xix)
    jp mi,bad_end
    ld c,d
    cp c,(xix)
    jp mi,bad_end

    ; (mem),reg
    ld c,(xix)
    dec 1,c
    sub (xix),c
    jp mi,bad_end
    ld c,(xix)
    dec 1,c
    ccf
    sbc (xix),c
    jp mi,bad_end
    jp end_loop
    ld c,(xix)
    dec 1,c
    cp (xix),c
    jp mi,bad_end



    include finish.inc
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    end