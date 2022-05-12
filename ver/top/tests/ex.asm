    ; ex
    main section code
    org 0
    ld a,0xbf    ; common header

    ld wa,0x1234
    ex w,a
    cp wa,0x3412
    jp ne,bad_end
    or ra3,1

    ld bc,wa
    ex b,c
    cp bc,0x1234
    jp ne,bad_end
    or ra3,2

    incf
    ld wa,0x1234
    ld bc,0xfea5
    ex wa,bc
    cp wa,0xfea5
    jp ne,bad_end
    cp bc,0x1234
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
    align 2
data:
    dw 0xcafe,0xbeef,0x1234,0x5678,0x9abc
    end