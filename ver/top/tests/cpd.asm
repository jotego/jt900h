    ; CPD - byte access
    main section code
    org 0
    ld a,0xbf    ; common header

    ld a,0xca
    ld xix,data+2
    ld bc,3

    cpd a,(xix-)
    jp eq,bad_end
    cp bc,2
    jp ne,bad_end

    cpd a,(xix-)
    jp ne,bad_end
    cp bc,1
    jp ne,bad_end

    cpd a,(xix-)
    jp ov,bad_end  ; V is 0 when BC==0 after CPD
    cp bc,0
    jp ne,bad_end

    cp xix,data-1
    jp ne,bad_end

test_end:
    ; ld (0xffff),0xff
end_loop:
    ldf 0
    ld hl,0xbabe
    jp end_loop
bad_end:
    ld hl,0xdead
    jp bad_end
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    end