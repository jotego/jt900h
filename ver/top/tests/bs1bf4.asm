    ; bit search backward and forward
    maxmode on
    relaxed on
    org 0
    ld a,0xbf    ; common header

    ld bc,0x10 ; bit 4 are set
    bs1b a,bc
    sub a,4
    jp ne,bad_end
    bs1f a,bc
    sub a,4
    jp ne,bad_end

    ld bc,0x8 ; bit 3 are set
    bs1f a,bc
    sub a,3
    jp ne,bad_end
    bs1b a,bc
    sub a,3
    jp ne,bad_end

    ld bc,0x4 ; bit 2 are set
    bs1f a,bc
    sub a,2
    jp ne,bad_end
    bs1b a,bc
    sub a,2
    jp ne,bad_end

    ld bc,0x2 ; bit 1 are set
    bs1f a,bc
    sub a,1
    jp ne,bad_end
    bs1b a,bc
    sub a,1
    jp ne,bad_end

    ld bc,0x1 ; bit 0 are set
    bs1f a,bc
    sub a,0
    jp ne,bad_end
    bs1b a,bc
    sub a,0
    jp ne,bad_end

end_loop:
    ld hl,0xbabe
    ld (0xffff),0xff
    jp end_loop
bad_end:
    ld hl,0xdead
    ld (0xffff),0xff
    jp bad_end
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    end