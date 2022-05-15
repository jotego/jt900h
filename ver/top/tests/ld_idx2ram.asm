    ; Some indexed addressing storing to RAM
    main section code
    org 0
data equ 0x200
    ld xwa,0x87654321
    ld xix,data

    ld (xix),wa
    ld de,(data)
    cp wa,de
    jp ne,bad_end
    or ra3,1

    ld (xix+4),xwa
    ld xbc,(data+4)
    cp xbc,xwa
    jp ne, bad_end
    or ra3,2
    nop
    nop
    nop
    nop
    nop
    nop
end_loop:
    ldf 0
    ld hl,0xbabe
    ld (0xffff),0xff
    jp end_loop
bad_end:
    ld hl,0xdead
    ld (0xffff),0xff
    jp bad_end