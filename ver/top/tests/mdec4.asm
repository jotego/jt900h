    ; Module decrement 1
    maxmode on
    relaxed on
    org 0
    ld a,0xbf    ; common header

    ld a,1
    ld (0xff0),xwa
    ld (0xfff0),xwa
    ld (0xffff0),xwa
    ld xbc,0
    call mdec1_loop
    ld c,0
    call mdec2_loop
    ld xde,0
    call mdec4_loop
    cp e,1
    jp eq,end_loop
    jp ne,bad_end

mdec1_loop:
    mdec1 8,wa
    ld c,(0xff0)
    cp c,1
    jp ne,mdec1_loop
    ret
mdec2_loop:
    incf
    mdec2 8,wa
    ld c,(0xfff0)
    cp c,1
    jp ne,mdec2_loop
    ret
mdec4_loop:
    decf
    mdec4 16,wa
    ld e,(0xffff0)
    cp e,1
    jp ne,mdec4_loop
    ret
    include finish.inc
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    end