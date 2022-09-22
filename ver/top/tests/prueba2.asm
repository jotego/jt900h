    main section code
    org 0
    ld a,0xbf    ; incw test

    incw 4,(xix)
    ld xwa,(xix)
    inc 7,a
    ld xbc,(xwa)
    incw 0,(xix)
    incw 1,(xix)
    incw 2,(xix)
    incw 3,(xix)
    ld xwa,(xix)

end_loop:
    ld hl,0xbabe
    ld (0xffff),0xff
    jp end_loop
bad_end:
    ld hl,0xdead
    ld (0xffff),0xff
    jp bad_end
end