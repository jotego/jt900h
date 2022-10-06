    ; CPI - register increment
    main section code
    org 0
    ld a,0xbf    ; common header

    ld (xiy),0
    ld a,2
    ld bc,3
    call inc_loop

inc_loop:
    cpi a,(xiy+)
    ld xde,(xiy)
    cp bc,0
    jp ne,inc_loop
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
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    end