    ; bit search backward and forward
    maxmode on
    relaxed on
    org 0
    ld a,0xbf    ; common header

    ld bc,0x2000 ; bit 13 are set
    bs1b a,bc
    sub a,13
    jp ne,bad_end
    bs1f a,bc
    sub a,13
    jp ne,bad_end

    ld bc,0x1000 ; bit 12 are set
    bs1b a,bc
    sub a,12
    jp ne,bad_end
    bs1f a,bc
    sub a,12
    jp ne,bad_end

    ld bc,0x0800 ; bit 11 are set
    bs1f a,bc
    sub a,11
    jp ne,bad_end
    bs1b a,bc
    sub a,11
    jp ne,bad_end

    ld bc,0x0400 ; bit 10 are set
    bs1b a,bc
    sub a,10
    jp ne,bad_end
    bs1f a,bc
    sub a,10
    jp ne,bad_end

    ld bc,0x0200 ; bit 9 are set
    bs1b a,bc
    sub a,9
    jp ne,bad_end
    bs1f a,bc
    sub a,9
    jp ne,bad_end

    include finish.inc
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    end