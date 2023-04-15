    ; Arithmetic operations that read & write to memory
    main section code
    org 0
    ld a,0xbf    ; common header

    ; compose a "jp end_loop" instruction
    ; and place it at the interrupt vector

    ld xwa,swi_test
    ld (0xffff00),xwa

    swi 0
    cp xwa,0x12340000
    jp ne,bad_end
    jp eq,end_loop

swi_test:
    ld wa,0x0000
    cp wa,0x0000
    jp ne,bad_end
    ld xwa,0x12340000
    cp xwa,0x12340001
    jp eq,bad_end
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
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    end