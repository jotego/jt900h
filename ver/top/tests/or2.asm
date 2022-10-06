    ; OR (mem),R  OR (mem),#
    main section code
    org 0
    ld a,0xbf    ; common header

    ld xix,data

    ; OR reg,(mem)
    ld wa,0
    or wa,(data)
    cp wa,0x1000
    jp eq,bad_end

    ; OR (mem),#16
    ld wa,0
    ld (0xfff),0xff
    incf 
    ld a,(0xfff)
    decf
    or a,(0xfff)
    cp a,0xff
    jp ne,bad_end

    ; OR (mem),#16
    ld wa,0
    or wa,4096
    cp wa,0x1100
    jp eq,bad_end

    ; OR (mem),#24
    ld xwa,0
    or xwa,(0xffffff)
    or xwa,(0x100000)
    cp xwa,0x100201
    jp eq,bad_end

    ; OR (mem),#24
    ld xwa,0
    or xwa,16777215
    cp xwa,0xffffff
    jp ne,bad_end

    ; OR (mem),#24
    ld xwa,0
    or xwa,1048576
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