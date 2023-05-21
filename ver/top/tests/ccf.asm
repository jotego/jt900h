    ; ccf
    maxmode on
    relaxed on
    org 0
    ld a,0xbf    ; common header

    ld a,0
    add a,a     ; carry=0
    jp ult,bad_end  ; jumps if carry set
    ccf
    jp uge,bad_end  ; jumps if carry not set
    ccf
    jp uge,end_loop ; jumps if carry not set
    jp bad_end

    include finish.inc
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    end