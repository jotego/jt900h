    ; DAA
    maxmode on
    relaxed on
    org 0

    ; tests all codes from 00 to 99
    ld hl,0
    ld b,99
    ld xwa,0
loop:
    inc 1,hl
    add a,1
    daa a
    ; convert BCD to decimal
    ld e,a
    and de,0xf0
    srl 4,e
    ld d,10
    mul de,d
    ld qe,a
    extz qde
    and qde,0xf
    add de,qde
    cp hl,de
    jp ne,bad_end
    djnz b,loop

    ; next in steps of 4
    ld hl,0
    ld xwa,0
loop4:
    inc 4,hl
    add a,4
    daa a
    ; convert BCD to decimal
    ld e,a
    and de,0xf0
    srl 4,e
    ld d,10
    mul de,d
    ld qe,a
    extz qde
    and qde,0xf
    add de,qde
    cp hl,de
    jp ne,bad_end
    cp hl,96
    jp m,loop4

    ; next in steps of 7
    ld hl,0
    ld xwa,0
loop7:
    inc 7,hl
    add a,7
    daa a
    ; convert BCD to decimal
    ld e,a
    and de,0xf0
    srl 4,e
    ld d,10
    mul de,d
    ld qe,a
    extz qde
    and qde,0xf
    add de,qde
    cp hl,de
    jp ne,bad_end
    cp hl,93
    jp m,loop7

    include finish.inc
    align 2
data:
    dw 0xcafe,0xbeef,0x1234,0x5678,0x9abc
    end