    ; bit search backward and forward
    maxmode on
    relaxed on
    org 0
    ld a,0xbf    ; common header

    ld bc,0x00 ; default (only zero)
    bs1b a,bc
    jp nov,bad_end
    inc 1,a     ; clear overflow bit
    bs1f a,bc
    jp nov,bad_end

    ld bc,0x4000 ; bit 14 are set
    bs1b a,bc
    sub a,14
    jp ne,bad_end
    bs1f a,bc
    sub a,14
    jp ne,bad_end

    ld bc,0x8000 ; bit 15 are set
    bs1f a,bc
    sub a,15
    jp ne,bad_end
    bs1b a,bc
    sub a,15
    jp ne,bad_end

    include finish.inc
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    end