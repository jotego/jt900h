    ; Module decrement 1/2/4
    ; tested in loops
    maxmode on
    relaxed on
    org 0
    ld a,0xbf    ; common header

    ld wa,0x1037
    ld bc,8
dec1_loop:
    mdec1 8,wa
    djnz bc,dec1_loop
    cp wa,0x1037
    jp ne,bad_end
    or ra3,1

    incf
    ld wa,0x103e
    ld bc,16
dec2_loop:
    mdec2 16,wa
    djnz bc,dec2_loop
    cp wa,0x103e
    jp ne,bad_end
    or ra3,2

    incf
    ld wa,0x103e
    ld bc,8
dec3_loop:
    mdec4 16,wa
    djnz bc,dec3_loop
    cp wa,0x103e
    jp ne,bad_end
    or ra3,4
    ldf 0

end_loop:
    ld hl,0xbabe
    ld (0xffff),0xff
    jp end_loop
bad_end:
    ld hl,0xdead
    ld (0xffff),0xff
    jp bad_end
end