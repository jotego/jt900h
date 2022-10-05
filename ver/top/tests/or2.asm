    ; OR (mem),R  OR (mem),#
    main section code
    org 0
    ld a,0xbf    ; common header

    ld xix,data

    ; OR (mem),#16
    ld wa,0
    or wa,4096
    ex f,f'
    cp wa,0x1000
    jp ne,bad_end

    ; OR (mem),#16
    ld wa,0
    or wa,65535
    ex f,f'
    cp wa,0xffff
    ex f,f'
    jp ne,bad_end

    ; OR (mem),#16
    ld wa,0
    or wa,4096
    ex f,f'
    cp wa,0x1100
    ex f,f'
    jp eq,bad_end

    ; OR (mem),#24
    ld xwa,0
    or xwa,1048576
    ex f,f'
    cp xwa,0x100201
    ex f,f'
    jp eq,bad_end

    ; OR (mem),#24
    ld xwa,0
    or xwa,16777215
    ex f,f'
    cp xwa,0xffffff
    ex f,f'
    jp ne,bad_end

    ; OR (mem),#24
    ld xwa,0
    or xwa,1048576
    ex f,f'
    cp xwa,0x100000
    jp ne,bad_end

end_loop:
    ld hl,0xbabe
    ld (0xffff),0xff
    jp end_loop
bad_end:
    ld hl,0xdead
    ld (0xffff),0xff
    jp bad_end
data:
    dw 0xcafe,0x2304,0xffff,0x1234,0xcccc
    end