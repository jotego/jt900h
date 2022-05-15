    ; CPL
    main section code
    org 0
    ld a,0xbf    ; common header

    ld a,0xf0
    ld b,0x0f
    xor a,b
    cp a,0xff
    jp ne,bad_end

    or c,1
    ld wa,(data)
    xor wa,0x3501
    cp wa,0xffff
    jp ne,bad_end

    or c,2
    ld xhl,0xff0000
    xor xhl,0x800000
    cp xhl,0x7f0000
    jp ne,bad_end

    or c,4

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