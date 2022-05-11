    ; AND (mem),R  AND (mem),#
    main section code
    org 0
    ld a,0xbf    ; common header

    ld xix,data
    ; AND (mem),#8
    ld a,1
    and (xix),3
    ld w,(xix)
    cp w,2
    jp ne,bad_end
    or ra3,1

    ; AND (mem),#16
    ld a,0
    scf
    andw (xix+2),0x10f0
    ld wa,(xix+2)
    cp wa,0x10e0
    jp ne,bad_end
    or ra3,2

    ; AND (mem),r
    incf
    ld wa,0x5533
    and (xix+6),wa
    ld hl,(xix+6)
    cp hl,0x4422
    jp ne,bad_end
    or ra3,4

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