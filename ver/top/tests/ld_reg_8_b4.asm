    main section code
    org 0
    ld wa,0xbf    ; common header

    ld de,0xb7

    ld xhl,0x00000000
    ld xhl,0xffffffff
    ld xhl,0x00000000

    ld xsp,0x00000000
    ld xsp,0xffffffff
    ld xsp,0x00000000

    ld xde,0x00000000
    ld xde,0xffffffff
    ld xde,0x00000000

    
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