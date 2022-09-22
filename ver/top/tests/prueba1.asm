    ; Module decrement 1/2/4
    ; tested in loops
    main section code
    org 0
    ld a,0xbf    ; common header

    ld xde,(0x0000)
    ld xde,(0xffff)
    ld xwa,(0x0000)
    ld xwa,(0xffff)
    ld xbc,(0x0000)
    ld xbc,(0xffff)
    ld xhl,(0x0000)
    ld xhl,(0xffff)

    ld xix,(0x0000)
    ld xix,(0xffff)
    ld xiy,(0x0000)
    ld xiy,(0xffff)
    ld xiz,(0x0000)
    ld xiz,(0xffff)
    ld xsp,(0x0000)
    ld xsp,(0xffff)

    mula xwa

end_loop:
    ld hl,0xbabe
    ld (0xffff),0xff
    jp end_loop
bad_end:
    ld hl,0xdead
    ld (0xffff),0xff
    jp bad_end
end