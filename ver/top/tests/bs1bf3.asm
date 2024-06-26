    ; bit search backward and forward
    maxmode on
    relaxed on
    org 0
    ld a,0xbf    ; common header

    ld bc,0x0100 ; bit 8 are set
    bs1b a,bc
    sub a,8
    jp ne,bad_end
    bs1f a,bc
    sub a,8
    jp ne,bad_end

    ld bc,0x80 ; bit 7 are set
    bs1f a,bc
    sub a,7
    jp ne,bad_end
    bs1b a,bc
    sub a,7
    jp ne,bad_end

    ld bc,0x40 ; bit 6 are set
    bs1f a,bc
    sub a,6
    jp ne,bad_end
    bs1b a,bc
    sub a,6
    jp ne,bad_end

    ld bc,0x20 ; bit 5 are set
    bs1f a,bc
    sub a,5
    jp ne,bad_end
    bs1b a,bc
    sub a,5
    jp ne,bad_end

    include finish.inc
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    end