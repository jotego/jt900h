    ; OR (mem),R  OR (mem),#
    maxmode on
    relaxed on
    org 0
    ld a,0xbf    ; common header

    ld wa,15
    ldw (0xfff),0x00 ; ldw (#16),(mem)
    or wa,(0xfff)
    ld xhl,(0xfff)
    cp wa,0x0f
    jp ne,bad_end

    ldw (0xfffff),0xf0 ; ldw (#24),(mem)
    or wa,(0xfffff)
    cp wa,0xff
    jp ne,bad_end
    jp eq,end_loop

    include finish.inc
data:
    dw 0xcafe,0x2304,0xffff,0x1234,0xcccc
    end