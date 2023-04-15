    ; Loop over after loading imm. to memory
    maxmode on
    relaxed on
    org 0
    ld a,0xbf    ; common header

    ld a,0
    ld bc,10

end_loop:
    ld hl,0xdead
    sub bc,1
    jp ne,go_on
    ld hl,0xbabe
    ld (0xffff),0xff    ; finish
go_on:
    ld (data),0xff
    jp end_loop
bad_end:
    ld hl,0xdead
    ld (0xffff),0xff
    jp bad_end
    align 2
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    dw 0,0,0,0,0,0,0,0,0,0
    align 4
stack:
    end