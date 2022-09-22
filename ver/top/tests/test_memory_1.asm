    main section code
    org 0
    ld wa,0xbf    ; common header

    ld xwa,0x00000000
    ld xbc,0x00000000
    ld xde,0x00000000
    ld xhl,0x00000000

    cp xwa,xsp ; xsp = 0100 
    jp z,bad_end
    cp xwa,xhl
    jp nz,bad_end

    ld xwa,0xffffffff
    ld xbc,0xffffffff
    ld xde,0xffffffff
    ld xhl,0xffffffff
    
    cp xbc,xde
    jp nz,bad_end
    cp xbc,0xfffffff1
    jp z,bad_end

    ld xwa,0x00000000
    ld xbc,0x00000000
    ld xde,0x00000000
    ld xhl,0x00000000

    cp xhl,xwa
    jp nz,bad_end
    cp xbc,data+1
    jp z,bad_end

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