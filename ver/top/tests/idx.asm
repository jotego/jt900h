    ; idx some pre/post variations to
    ; indexed addressing on word arguments
    main section code
    org 0
    ld a,0xbf    ; common header

    ; NB: the assembler seems to get the
    ; label addresses wrong sometimes
    ld xix,data+2
    ld xiy,data

    ld wa,(-xix)    ; must be 1111
    cp xix,data
    jp ne,bad_end
    or bc,1
    ld de,(xix)
    cp wa,(xix)
    jp ne,bad_end
    or bc,2
    cp wa,0x1111
    jp ne,bad_end
    or bc,4

    cp xix,data
    jp ne,bad_end
    or bc,8

    ld wa,(xix+)
    ld wa,(xix+)    ; must be 0x2222
    cp wa,(-xix)
    jp ne,bad_end
    or bc,0x10
    cp wa,0x2222
    jp ne,bad_end
    or bc,0x20

end_loop:
    ld hl,0xbabe
    ld (0xffff),0xff
    jp end_loop
bad_end:
    ld hl,0xdead
    jp bad_end
data:
    dw 0x1111,0x2222,0x3333
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    end