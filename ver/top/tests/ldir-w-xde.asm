    ; ldir over more than 256 bytes
    maxmode on
    relaxed on
    org 0

    ld xde,0x1000
    ld xhl,0x2000
    ld bc,0x200

    ld wa,0
    ld bc,0
loop:
    ld (xde+),wa
    ld (xhl+),bc
    inc 1,bc
    djnz bc,loop

    ld xde,0x1000
    ld xhl,0x2000
    ld bc,0x200
    ldirw (xde+),(xhl+)

    ld qb,1
    jp ov,bad_end

    ld qb,2
    cp bc,0
    jp ne,bad_end

    ld qb,3
    cp xde,0x1400
    jp ne,bad_end

    ld qb,4
    cp xhl,0x2400
    jp ne,bad_end

    ; check the contents
    ld xde,0x1000
    ld xhl,0x2000
    ld bc,0x400
loop2:
    ld a,(xde+)
    cp a,(xhl+)
    jp ne,bad_end
    djnz bc,loop2

    ld qb,0
    include finish.inc
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    end