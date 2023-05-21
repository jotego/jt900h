    ; bit search backward and forward
    maxmode on
    relaxed on
    org 0
    ld a,0xbf    ; common header

    ld bc,0x408 ; bits 10 and 3 are set
    bs1b a,bc
    sub a,10
    jp ne,bad_end

    bs1f a,bc
    sub a,3
    jp ne,bad_end


    include finish.inc
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    end