    ; CPD - byte access
    main section code
    org 0
    ld a,0xbf    ; common header

    ld (xhl),0
    ld a,2
    ld bc,2
    call dec_loop

dec_loop:
    cpd a,(xhl-)
    cp bc,0
    jp ne,dec_loop
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