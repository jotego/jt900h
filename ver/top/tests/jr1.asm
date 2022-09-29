    ; load to memory
    main section code
    org 0
    ld a,0xbf    ; common header

    ld a,1

    ld (0xffff),0xff
    ld a,2
    ld (0xff),0xff
    ld a,3
    ld (0xffffff),0xff
    ld a,4
    jp end_loop

bad_end:
    ld hl,0xdead
    ld (0xffff),0xff
    jp bad_end
end_loop:
    ld hl,0xbabe
    ld (0xffff),0xff
    jp end_loop
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
end