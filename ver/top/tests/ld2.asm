    maxmode on
    relaxed on
    org 0

    ld xsp, stack
    ld xix,data
    ld xiy,data2
    ld bc,16
loop8:
    ld a,(xix+)
    ld (xiy+),a
    djnz bc,loop8
    cp xix,data+16
    jp ne,bad_end
    cp xiy,data2+16
    jp ne,bad_end

    ld xix,data
    ld xiy,data2
    ld bc,8
loop16:
    ld wa,(xix+)
    cp (xiy+),wa
    jp ne,bad_end
    djnz bc,loop16
    cp xix,data+16
    jp ne,bad_end
    cp xiy,data2+16
    jp ne,bad_end

    ld xix,data
    ld xiy,data
    ld bc,8
    ld hl,0
    ld wa,0
clr16:
    ld (xix+wa),hl
    cp (xiy+),hl
    jp ne,bad_end
    inc 2,wa
    djnz bc,clr16
    cp xiy,data+16
    jp ne,bad_end

    ld xix,data+16
    ld bc,4
ck32:
    ld xwa,(-xix)
    add xwa,xwa
    jp ne,bad_end
    djnz bc,ck32
    cp xix,data
    jp ne,bad_end

    ld xix,data2
    ld xiy,data
    ld bc,4
loop32:
    ld xwa,(xix+)
    ld (xiy+),xwa
    djnz bc,loop32
    cp xix,data2+16
    jp ne,bad_end
    cp xiy,data+16
    jp ne,bad_end

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