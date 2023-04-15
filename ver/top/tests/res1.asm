    ; RES
    maxmode on
    relaxed on
    org 0
    ld a,0xbf    ; common header

    ;RES #4,r
    ld wa,0x0000
    res 2,wa
    cp wa,0
    jp ne,bad_end

    ;RES #3,(mem)
    ld (0xff),0x00
    res 3,(0xff)
    cp (0xff),0
    jp ne,bad_end

    incf
    ;SET #4,r
    ld wa,0x0000
    set 2,a
    cp a,0
    jp eq,bad_end

    ;SET #3,(mem)
    ld (0x00),0x00
    set 1,(0x00)
    cp (0x00),0x02
    jp ne,bad_end

    incf
    ;TSET #4,r
    ld a,0x01
    tset 0,a
    cp wa,1
    jp ne,bad_end

    ;TSET #3,(mem)
    ld (0x00),0x00
    tset 1,(0x00)
    cp (0x00),2
    jp ne,bad_end

    decf
    decf

end_loop:
    ldf 0
    ld hl,0xbabe
    ld (0xffff),0xff
    jp end_loop
bad_end:
    ldf 0
    ld hl,0xdead
    ld (0xffff),0xff
    jp bad_end
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    end