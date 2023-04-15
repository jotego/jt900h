    ; ld<w> (mem),(#16)
    maxmode on
    relaxed on
    org 0
ref   equ 0x800
data2 equ 0x700
    ld a,0xbf    ; common header

    ld xix,data2
    ld xiy,ref

    ; Sanity check
    cpw (xiy),0xff
    jp ne,bad_end
    cpw (xiy+2),0x01fe
    jp ne,bad_end
    or ra3,1

    ; 16-bit write, addr->idx
    ldw (xix),(ref)
    ld wa,(xix)
    cp wa,(xiy)
    jp ne,bad_end
    or ra3,2

    ; 8-bit write, addr->idx
    ldb (xix+2),(ref+2)
    ld c,(xix+2)
    cp c,(ref+2)
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
    dw 0xcafe,0xbeef,0x1234,0x5678,0x9abc
    end