    ; load immediate value to memory
    maxmode on
    relaxed on
    org 0
    ld a,0xbf    ; common header

    ld a,0
    ld xix,data
    ldb (xix),1
    ldw (xix+2),0x1122

    ld bc,1

    ld d,(xix)
    cp d,1
    jp ne,bad_end
    or bc,2

    incf
    ld wa,(xix+2)
    cp wa,0x1122
    jp ne,bad_end
    decf
    or bc,4

    include finish.inc
    align 2
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    dw 0,0,0,0,0,0,0,0,0,0
    align 4
stack:
    end