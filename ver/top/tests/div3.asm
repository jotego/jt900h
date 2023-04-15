    ; div RR,r
    maxmode on
    relaxed on
    org 0
    ld a,0xbf    ; common header

    ; 32-bit number divided by 16-bit number
    ; xwa / bc
    ld xwa,354236
    ld bc,1050   ; 0x41a
    div xwa,bc
    jp ov,bad_end
    or ra3,1

    cp wa,337
    jp ne,bad_end
    or ra3,2

    cp qwa0,386
    jp ne,bad_end
    or ra3,4


end_loop:
    ldf 0
    ld hl,0xbabe
    ld (0xffff),0xff
    jp end_loop
bad_end:
    ld hl,0xdead
    ld (0xffff),0xff
    jp bad_end
data:
    dw 0xcafe,0xbeef,0x1234,0x5678,0x9abc
    end