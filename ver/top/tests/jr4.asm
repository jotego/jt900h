    ; load to memory
    maxmode on
    relaxed on
    org 0
    ld a,0xbf    ; common header

    ; checks that the instruction after a missed jump
    ; is executed correctly
    ld a,0xff
    jr z,bad_end
    add a,1
    jr nz,bad_end
    add a,1
    jr z,bad_end
    add a,1
    jr z,bad_end
    add a,1
    jr z,bad_end
    add a,1

end_loop:
    ld hl,0xbabe
    ld (0xffff),0xff
    jp end_loop
bad_end:
    ld hl,0xdead
    ld (0xffff),0xff
    jp bad_end
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
jump_far:
    ld bc,0xb0ba
    jr end_loop
    end