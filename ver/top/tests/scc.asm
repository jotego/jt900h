    ; SCC
    main section code
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