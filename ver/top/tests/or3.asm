    ; OR (mem),R  OR (mem),#
    maxmode on
    relaxed on
    org 0
    ld a,0xbf    ; common header

    ld xix,data

    ; OR (mem),#16
    ld wa,0
    or wa,0
    cp wa,0x1000
    jp eq,bad_end

    ; OR (mem),#16
    ld wa,0
    or wa,65535
    cp wa,0xffff
    jp ne,bad_end

    ; OR (mem),#16
    ld wa,0
    or wa,0
    cp wa,0x1100
    jp eq,bad_end

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