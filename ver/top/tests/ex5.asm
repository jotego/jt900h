    ; ex
    maxmode on
    relaxed on
    org 0
    ld a,0xbf    ; common header

    ld xhl,65535
    incf 
    ld xhl,0
    ld xhl,4294967295
    cp xhl,0xffff1f2
    jp eq,bad_end
    ld xhl,0
    cp xhl,0
    jp ne,bad_end
    decf
    cp xhl,0xffff
    jp ne,bad_end
    ld xhl,0xffffff
    cp xhl,65535
    jp eq,bad_end
    ld xhl,0xf
    cp xhl,15
    jp ne,end_loop
    ex hl,wa
    ex hl,bc
    
end_loop:
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