    ; LDD
    main section code
    org 0
    ld a,0xbf    ; common header

    ld xix,0
    ld xiy,5
    ld xde,0
    ld xhl,5
    ld bc,10
    call inc_loop

inc_loop:    
    ldi (xix+),(xiy+)
    ldi(xde+),(xhl+)
    ld xwa,xde
    incf
    ld xwa,xix
    decf
    cp bc,0
    jp ne,inc_loop
end_loop:
    ldf 0
    ld hl,0xbabe
    ld (0xffff),0xff
    jp end_loop
bad_end:
    ld hl,0xdead
    ld (0xffff),0xff
    jp bad_end
data:
    dw 0x0011,0x2233,0x4455,0x6677,0x8899,0x0000,0x0000,0x0000
    dw 0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000
copy:
    dw 0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000
    end