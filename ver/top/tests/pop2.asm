    ; POP r
    main section code
    org 0
    ld a,0xbf    ; common header

    ld xsp, stack
    ld xwa,0x00
    pop a   ; POP F
    pop wa  ; POP R
    pop xwa

    jp c,bad_end
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
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    dw 0,0,0,0,0,0,0,0,0,0
stack:
    end