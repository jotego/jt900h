    ; bit search backward and forward
    main section code
    org 0
    ld a,0xbf    ; common header

    ld bc,0x00 ; default (only zero)
    bs1b a,bc
    sub a,0
    jp ne,bad_end
    bs1f a,bc
    sub a,0
    jp ne,bad_end

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