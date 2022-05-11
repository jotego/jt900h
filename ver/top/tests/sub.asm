    ; SUB (mem),#
    main section code
    org 0
    ld a,0xbf    ; common header

    ld xix,data
    ; SUB (mem),#8
    ld a,1
    sub (xix),1
    ld w,(xix)
    cp w,0xfd
    jp ne,bad_end
    or ra3,1

    ; SBC (mem),#16
    ld a,0
    scf
    sbcw (xix+2),0x1000
    ld wa,(xix+2)
    cp wa,0xbeef-0x1001
    jp ne,bad_end
    or ra3,2

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