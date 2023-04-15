    ; div RR,r
    maxmode on
    relaxed on
    org 0
    ld a,0xbf    ; common header

    ; 16-bit number divided by 8-bit number
    ; bc / a
    ld bc,1230
    ld a,23
    div bc,a
    jp ov,bad_end
    or ra3,1

    cp c,53
    jp ne,bad_end
    or ra3,2

    cp b,11
    jp ne,bad_end
    or ra3,4

    ; de / a
    ld de,1230
    ld a,23
    div de,a
    jp ov,bad_end
    or ra3,8

    cp e,53
    jp ne,bad_end
    or ra3,0x10

    cp d,11
    jp ne,bad_end
    or ra3,0x20

    ; hl / a
    ld hl,1230
    ld a,23
    div hl,a
    jp ov,bad_end
    or ra3,0x40

    cp l,53
    jp ne,bad_end
    or ra3,0x80

    cp h,11
    jp ne,bad_end
    or rw3,1


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