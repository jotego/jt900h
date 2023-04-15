    ; idx some pre/post variations to
    ; indexed addressing on word arguments
    maxmode on
    relaxed on
    org 0
    ld a,0xbf    ; common header
    jp test
    ; NB: the assembler seems to get the
    ; label addresses wrong sometimes
data:
    dw 0x1111,0x2222,0x3333
test:
    ld xix,data+2
    ld xiy,data

    ld wa,(-xix)    ; must be 1111
    cp xix,data
    jp ne,bad_end
    or ra3,1

    ld de,(xix)
    cp wa,(xix)
    jp ne,bad_end
    or ra3,2
    cp wa,0x1111
    jp ne,bad_end
    or ra3,4

    cp xix,data
    jp ne,bad_end
    or ra3,8

    ld wa,(xix+)
    ld wa,(xix+)    ; must be 0x2222
    cp wa,(-xix)
    jp ne,bad_end
    or ra3,0x10
    cp wa,0x2222
    jp ne,bad_end
    or ra3,0x20

end_loop:
    ld hl,0xbabe
    ld (0xffff),0xff
    jp end_loop
bad_end:
    ld hl,0xdead
    ld (0xffff),0xff
    jp bad_end
    end