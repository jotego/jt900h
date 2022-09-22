    ; call[cc],mem
    main section code
    org 0
    ld wa,0xbf    ; common header

    incf 
    incf
    incf

    ld xsp,stack
    ld xwa,data
    push wa
    ld xwa,data+2
    push wa
    
    ld xsp,example_jp
    call loop
    ld xwa,data+4
    cp xsp,example_jp
    jp eq,bad_end
    decf
    decf
    decf
    jp end_loop

    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop

loop:
    ld bc,(xsp+4)
    ld de,(xsp+6)
    retd 4
    jp bad_end
example_jp:
    dw 0x5341,0x4d55
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
stack:
    end