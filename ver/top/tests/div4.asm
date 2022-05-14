    ; div RR,r
    main section code
    org 0
    ld a,0xbf    ; common header

    ; 32-bit number divided by 16-bit number
    ld xix,564200
    ld de,757
    div xix,de
    cp ix,745
    jp ne,bad_end
    cp qix,235
    jp ne,bad_end
    or ra3,0x1

    ld xiy,564200
    div xiy,de
    cp iy,745
    jp ne,bad_end
    cp qiy,235
    jp ne,bad_end
    or ra3,0x2

    ld xiz,564200
    div xiz,de
    cp iz,745
    jp ne,bad_end
    cp qiz,235
    jp ne,bad_end
    or ra3,0x4

    ld xsp,964200
    ld de,957
    div xsp,de
    cp sp,1007
    jp ne,bad_end
    cp qsp,501
    jp ne,bad_end
    or ra3,0x8


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