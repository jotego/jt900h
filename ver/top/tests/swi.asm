    ; Arithmetic operations that read & write to memory
    maxmode on
    relaxed on
    org 0
    ld a,0xbf    ; common header

    ; compose a "jp end_loop" instruction
    ; and place it at the interrupt vector
    ld xwa,swi_test
    ld (0xffff10),xwa

    ; Run the test
    ei 0
    swi 4
after_swi:
    jp bad_end

swi_test:
    or ra3,1
    incf
    push sr     ; checks that IFF is set to 5
    pop wa
    srl 12,wa
    and wa,7
    cp wa,5
    jp ne,bad_end
    or ra3,2
    ld xbc,(xsp)    ; checks the return address
    cp xbc,after_swi
    jp ne,bad_end
    or ra3,4

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