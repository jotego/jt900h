    ; CPI - byte access
    main section code
    org 0
    ld a,0xbf    ; common header

    ld a,0xfe
    ld xix,data
    ld bc,3

    cpi a,(xix+)
    jp eq,bad_end
    cp bc,2
    jp ne,bad_end

    cpi a,(xix+)
    jp ne,bad_end
    cp bc,1
    jp ne,bad_end

    cpi a,(xix+)
    jp ov,bad_end  ; V is set when BC==0 after CPD
    cp bc,0
    jp ne,bad_end

    cp xix,data+3
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
    db 0xca,0xfe,0xbe,0xef,0,1,2,3
    end