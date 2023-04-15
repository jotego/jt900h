    main section code
    org 0
    ld wa,0xbf    ; common header

    ld xix,0x00000000
    ld xiy,0x00000000
    ld xiz,0x00000000
    
    ld xix,0xffffffff
    ld xiy,xix
    cp xiy,xiz
    jp z,bad_end ; si son diferentes

    ld xiz,xiy
    cp xiz,xix
    jp nz,bad_end

    ld xix,0x00000000
    cp xix,xiz
    jp z,bad_end

    ld xiz,0x00000000
    cp xiz,xiy
    jp z,bad_end

    ld xiy,xix
    cp xiy,xiz
    jp nz,bad_end


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