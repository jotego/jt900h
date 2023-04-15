    ; SCC
    maxmode on
    relaxed on
    org 0
    ld a,0xbf    ; common header

    ld a,0xff
    scf
    scc nc,a
    cp a,0
    jp ne,bad_end

    scf
    scc c,b
    cp b,1
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