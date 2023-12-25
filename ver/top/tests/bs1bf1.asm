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

    ld bc,0x4000 ; bit 14 set
    bs1b a,bc
    sub a,14
    jp ne,bad_end
    bs1f a,bc
    sub a,14
    jp ne,bad_end

    ld bc,0x8000 ; bit 15 set
    bs1f a,bc
    sub a,15
    jp ne,bad_end
    bs1b a,bc
    sub a,15
    jp ne,bad_end

    ld de,0x1008
    bs1f a,de
    jp ov,bad_end
    cp a,3
    jp ne,bad_end

    bs1b a,de
    jp ov,bad_end
    cp a,12
    jp ne,bad_end

    include finish.inc
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    end