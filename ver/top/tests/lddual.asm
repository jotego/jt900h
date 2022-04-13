    ; LD data read from memory into memory
    main section code
    org 0
    ld a,0xbf    ; common header

    ld a,0

    ldw (data),0x1234
    ld xix,data
    ld de,(xix)
    cp de,0x1234
    jp ne,bad_end

    incf
    ld (data),0x55
    ld d,(xix)
    cp d,0x55
    jp ne,bad_end

end_loop:
    ld hl,0xbabe
    ld (0xffff),0xff
    jp end_loop
bad_end:
    ld hl,0xdead
    jp bad_end
    align 2
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    dw 0,0,0,0,0,0,0,0,0,0
    align 4
stack:
    end