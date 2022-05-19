    ; div RR,r
    main section code
    org 0
    ld a,0xbf    ; common header

    ; 32-bit number divided by 16-bit number
    ld xbc,100000
    ld wa,500
    div xbc,wa
    jp ov,bad_end
    cp bc,200
    jp ne,bad_end
    cp qbc0,0
    jp ne,bad_end
    or ra3,1

    ld xde,564200
    ld bc,757
    div xde,bc
    cp de,745
    jp ne,bad_end
    cp qde,235
    jp ne,bad_end
    or ra3,0x2

    ld xhl,564200
    ld bc,757
    div xhl,bc
    cp hl,745
    jp ne,bad_end
    cp qhl,235
    jp ne,bad_end
    or ra3,0x4


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