    ; Perform a software interrupt instruction SWI
    ; and use RETI to return
    ; supmode on = so the assembler parses reti
    supmode on
    maxmode on
    relaxed on
    org 0
    ld a,0xbf    ; common header
    ld xsp,0x800

    ; prepare the interrupt vector
    ld xwa,level0
    ld (0xffff00+4*0),xwa   ; int level 0

    ld xwa,swi_test
    ld (0xffff00+4*4),xwa   ; int level 4



    ; Run the test
    ei 2
    swi 4
after_swi:
    ld xbc,0xbe0000ef

    push sr     ; checks that IFF is set to 2 again
    pop wa
    srl 12,wa
    and wa,7
    cp wa,2
    jp ne,bad_end

    ; contrary to hardware interrupts, level 0 is possible
    ; the level in IFF seems to affect hardware interrupts only
    swi 0       ; should be parsed
    jp end_loop

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
    ld xbc,(xsp+2)    ; checks the return address is at the right location
    cp xbc,after_swi
    jp ne,bad_end
    or ra3,4
    ldf 0
    reti

level0:
    or xbc,0x555500
    reti

    include finish.inc
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    end