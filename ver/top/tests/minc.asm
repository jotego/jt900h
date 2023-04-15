    ; Module decrement 1/2/4
    ; tested in loops
    maxmode on
    relaxed on
    org 0
    ld a,0xbf    ; common header

    ld wa,0x1000
    ld bc,8
loop1:
    minc1 8,wa
    djnz bc,loop1
    cp wa,0x1000
    jp ne,bad_end
    or ra3,1

    ld bc,4
    ld de,0x2000
loop2:
    minc2 8,de
    djnz bc,loop2
    cp de,0x2000
    jp ne,bad_end
    or ra3,2

    incf
    ld bc,8
    ld de,0x2020
loop3:
    minc4 8,de
    djnz bc,loop3
    cp de,0x2020
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