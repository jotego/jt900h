    ; LDD
    main section code
    org 0
    ld a,0xbf    ; common header

    ld xhl,data+3*2
    ld xde,copy+3*2
    ld bc,4

    lddw (xde-),(xhl-)
    lddw (xde-),(xhl-)
    lddw (xde-),(xhl-)
    lddw (xde-),(xhl-)

    cp bc,0
    jp ne,bad_end

    ; check the copy
    ld bc,4
    ld xhl,data+3*2
    ld xde,copy+3*2
loop:
    ld wa,(xhl)
    sub xhl,2
    cpd wa,(xde-)
    jp ne,bad_end
    cp bc,0
    jp ne,loop

test_end:
    ; ld (0xffff),0xff
end_loop:
    ldf 0
    ld hl,0xbabe
    jp end_loop
bad_end:
    ld hl,0xdead
    jp bad_end
    db 0
data:
    dw 0x0011,0x2233,0x4455,0x6677,0x8899,0x0000,0x0000,0x0000
    dw 0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000
copy:
    dw 0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000
    end