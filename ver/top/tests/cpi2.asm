    ; CPI - byte access
    maxmode on
    relaxed on
    org 0
    ld a,0xbf    ; common header

    ld wa,0xcafe
    ld xiy,data
    ld bc,3

    ld de,(xiy)
    cpi wa,(xiy+)
    jp ne,bad_end
    cp bc,2
    jp ne,bad_end

    ld de,(xiy)
    cpi wa,(xiy+)
    jp eq,bad_end
    cp bc,1
    jp ne,bad_end

    ld de,(xiy)
    cpi wa,(xiy+)
    jp ov,bad_end  ; V is set when BC==0 after CPD
    cp bc,0
    jp ne,bad_end

    cp xiy,data+6
    jp ne,bad_end

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