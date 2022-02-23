    ; ret cc
    main section code
    org 0
    ld a,0xbf    ; common header

    ld xsp,stack
    call mytest
    cp w,2
    jp ne,bad_end
    jp test_end

mytest:
    ld a,1
    add a,1
    ret eq
    ld w,2
    rcf
    ret nc
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