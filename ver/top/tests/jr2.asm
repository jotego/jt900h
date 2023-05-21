    ; load to memory
    maxmode on
    relaxed on
    org 0
    ld a,0xbf    ; common header

    ld a,0xff
    add a,1
    jr c,good
    jp bad_end
backup:
    jrl jump_far
good:
    ld wa,0xface
    jr backup

    include finish.inc
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
jump_far:
    ld bc,0xb0ba
    jr end_loop
    end