    ; EXFF
    main section code
    org 0
    ld a,0xbf    ; common header

    rcf
    jp c,bad_end
    or b,1

    ex f,f'
    jp c,bad_end
    or b,2

    scf
    jp nc,bad_end
    or b,4

    ex f,f'
    jp c,bad_end
    or b,8

    add a,1
    jp z,bad_end
    or b,0x10

    ex f,f'
    sub a,a
    jp ne,bad_end
    or b,0x20

    ex f,f'
    jp z,bad_end
    or b,040

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
    dw 0x0011,0x2233,0x4455,0x6677,0x8899,0x0000,0x0000,0x0000
    dw 0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000
copy:
    dw 0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000
    end