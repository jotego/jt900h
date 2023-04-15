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
    end