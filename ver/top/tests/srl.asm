    main section code
    org 0
    ld a,0xbf    ; common header

    ; SRL

    ld xwa,0x1234

    srl 4,xwa ; xwa = 123

    ld a,0x01
    ld xbc,0xfff1

    srl a,xbc ; xbc = 7ff8
    srl a,xbc ; xbc = 3ffc
    srl a,xbc ; xbc = 1ffe

    ld a,0x03

    srl a,xbc ; xbc = 3ff
    srl a,xbc ; xbc = 7f
    srl a,xbc ; xbc = f

    ld a,0x04
    ld xde,0xffff

    srl a,xde;
    srl a,xde;
    srl a,xde;
    srl a,xde;

end_loop:
    ld hl,0xbabe
    ld (0xffff),0xff
    jp end_loop
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    end