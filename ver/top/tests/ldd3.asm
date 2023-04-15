    ; LDD
    maxmode on
    relaxed on
    org 0
    ld a,0xbf    ; common header

    ld xiy,10
    ld xde,(0x1234)
    ld xbc,0x5678
    ld xde,(xsp+sp)
    ld xde,(xwa+wa)
    ld xde,(xwa)

    ld xde,0x0
    ld xhl,0xff
    ld bc,10
    call for_loop

for_loop:    
    ldd (xde-),(xhl-)
    ld wa,hl
    cp bc,0
    jp ne,for_loop
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