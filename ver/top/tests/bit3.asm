    ; jump tests
    maxmode on
    relaxed on
    org 0

    ld xsp,0x1000

    ; test on bytes
    ld a,0xff
    ld w,8
loop1b:
    call test1b
    inc 1,qh
    inc 1,(test1b+2)     ; change the OP code so bit 0,a becomes bit 1,a etc.
    djnz w,loop1b

    ld a,0
    ld w,8
loop0b:
    inc 1,qh
    call test0b
    inc 1,(test0b+2)     ; change the OP code so bit 0,a becomes bit 1,a etc.
    djnz w,loop0b

    ; test on words
    ld wa,0xff
    ld qw,8
loop1w:
    call test1w
    inc 1,qh
    inc 1,(test1w+2)     ; change the OP code so bit 0,a becomes bit 1,a etc.
    djnz qw,loop1w

    ld wa,0
    ld qw,8
loop0w:
    inc 1,qh
    call test0w
    inc 1,(test0w+2)     ; change the OP code so bit 0,a becomes bit 1,a etc.
    djnz qw,loop0w

    jp end_loop

test0b:
    bit 0,a
    jp nz,bad_end
    ret

test1b:
    bit 0,a
    jp z,bad_end
    ret

test0w:
    bit 0,wa
    jp nz,bad_end
    ret

test1w:
    bit 0,wa
    jp z,bad_end
    ret

    include finish.inc
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    end