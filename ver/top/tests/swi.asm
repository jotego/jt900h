    ; Perform a software interrupt instruction SWI
    ; but does not use RETI to return

    maxmode on
    supmode on
    relaxed on
    org 0
    ld a,0xbf    ; common header
    ld xsp,0x800

    ; prepare the interrupt vector
    ld xwa,swi_test
    ld (0xffff00+4*4),xwa

    ; Run the test
    ei 0
    swi 4
after_swi:
    jp bad_end

    ; not aligning the interrupt start creates problems reading
    ; the OP data of the first instruction. Not sure whether this is
    ; worth fixing. This may as well be a requirement in the original too
    align 2
swi_test:
    or ra3,1
    incf
    push sr     ; checks that IFF is set to 7 (NMI level)
    pop wa
    srl 12,wa
    and wa,7
    cp wa,7
    jp ne,bad_end
    or ra3,2
    ld xbc,(xsp+2)    ; checks the return address is at the right location
    cp xbc,after_swi
    jp ne,bad_end
    or ra3,4

    ldf 0
    include finish.inc
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    end