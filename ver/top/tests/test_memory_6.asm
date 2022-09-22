    main section code
    org 0
    ld wa,0xbf    ; common header

    ld xbc,0xffff
    ld xde,0x5687
    ld xhl,0xecba
    
    ldf 1

    ld xwa,xbc

    ldf 2
    
    ld xbc,xde

    ldf 3
    
    ld xde,xhl

    decf
    decf
    decf

    ei 0
    ei 1
    ei 2
    ei 3
    ei 4
    ei 5
    ei 6
    ei 7

    ld wa,0xff

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