    ; call [cc],mem
    maxmode on
    relaxed on
    org 0
    ld a,0xbf    ; common header

    ld xsp,stack
    ld a,0x33
    sub a,a
    call ne,badsub
    call eq,mysub
    jp test_end

mysub:
    ld de,0xcafe
    ret
    jp bad_end

badsub:
    jp bad_end

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
    dw 0x0011,0x2233,0x4455,0x6677,0x8899,0x0000,0x0000,0x0000
    dw 0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000
copy:
    dw 0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000
stack:
    end