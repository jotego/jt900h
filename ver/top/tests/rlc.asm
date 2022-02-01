    ; RLC
    main section code
    org 0
    ld a,0xbf    ; common header

    ; 8-bit, 1 shift
    ld A,1
    ld d,0x81
    rlc A,d
    jp nc,bad_end
    cp d,3
    jp nz,bad_end

    ; 8-bit, 2 shift
    ld A,2
    ld d,0x81
    rlc A,d
    cp d,6
    jp nz,bad_end

    ; 8-bit, 3 shift
    ld A,3
    ld d,0x81
    rlc A,d
    cp d,0xc
    jp nz,bad_end

    ; 8-bit, 4 shift
    ld A,4
    ld d,0x81
    rlc A,d
    cp d,0x18
    jp nz,bad_end

    ; 8-bit, 5 shift
    ld A,5
    ld d,0x81
    rlc A,d
    cp d,0x30
    jp nz,bad_end

test_end:
    ; ld (0xffff),0xff
end_loop:
    ldf 0
    ld hl,0xbabe
    jp end_loop
bad_end:
    ld hl,0xdead
    jp bad_end
data:
    db 0x3,0x6,0xc,0x81,0x30,0x60,0xc0,0x81
    db 0x3,0x6,0xc,0x81,0x30,0x60,0xc0,0x81
    db 0x3,0x6,0xc,0x81,0x30,0x60,0xc0,0x81
    db 0x3,0x6,0xc,0x81,0x30,0x60,0xc0,0x81
    end