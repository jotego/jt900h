    ; ldar
    maxmode on
    relaxed on
    org 0
ref   equ 0x800
data2 equ 0x700
START:
    ld a,0xbf    ; common header

    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
LDAR_PC:
    ldar xix, $+0x100
    cp xix,LDAR_PC+0x100
    jp ne,bad_end
    or ra3,1

    ldar xiy,LDAR_PC
    cp xiy,LDAR_PC
    jp ne,bad_end
    or ra3,2

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
    dw 0xcafe,0xbeef,0x1234,0x5678,0x9abc
    end