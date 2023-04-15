    main section code
    org 0
    ld wa,0xbf    ; common header

    ld de,0xb7

    incf

    ld ix,0x1111
    cp ix,0x1111
    jp nz,bad_end
    ld de,ix

    ld iy,0x1112
    cp iy,0x1112
    jp nz,bad_end
    ld de,iy

    ld iz,0x1113
    cp iz,0x1113
    jp nz,bad_end
    ld de,iz

    ld sp,0x1114
    cp sp,0x1114
    jp nz,bad_end
    ld de,sp 

    ld qix,0x1115
    cp qix,0x1115
    jp nz,bad_end
    ld de,qix

    ld qiy,0x1116
    cp qiy,0x1116
    jp nz,bad_end
    ld de,qiy

    ld qiz,0x1117
    cp qiz,0x1117
    jp nz,bad_end
    ld de,qiz

    ld qsp,0x1118
    cp qsp,0x1118
    jp nz,bad_end
    ld de,qsp 

    decf
    
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