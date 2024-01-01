    maxmode on
    relaxed on
    org 0

    ld xsp, stack

    ; copy in reverse order using a negative offset
    ld xix,data+16
    ld xiy,data2+16
    ld a,-16
    ld bc,16
loop8:
    ld w,(xix+a)
    ld (-xiy),w
    inc 1,a
    djnz bc,loop8
    cp xiy,data2
    jp ne,bad_end
    cp a,0
    jp ne,bad_end

    ; verify the copy but using a 16-bit register
    ld xix,data+16
    ld xiy,data2+16
    ld wa,-16
    ld bc,16
loop16:
    ld e,(xix+wa)
    cp (-xiy),e
    jp ne,bad_end
    inc 1,wa
    djnz bc,loop16

    include finish.inc
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee
    dw 0x1234,0x5678,0x9abc,0xdef0
data2:
    dw 0,0,0,0,0,0,0,0,0,0
    dw 0,0,0,0,0,0,0,0,0,0
    dw 0,0,0,0,0,0,0,0,0,0
    dw 0,0,0,0,0,0,0,0,0,0
    align 4
stack:
    end