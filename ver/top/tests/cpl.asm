    ; CPL
    main section code
    org 0
    ld a,0xbf    ; common header

    ld de,0x5555
    cpl de
    ld wa,0xaaaa
    sub wa,de
    jp ne,bad_end

    incf
    ld de,0x55be
    cpl d
    nop
    nop
    ld a,0xaa
    sub a,d
    decf
    jp ne,bad_end

end_loop:
    ld hl,0xbabe
    ld (0xffff),0xff
    jp end_loop
bad_end:
    ld hl,0xdead
    jp bad_end
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    end