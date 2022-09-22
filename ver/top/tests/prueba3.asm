    main section code
    org 0
    ld a,0xbf    ; incw test

    ld wa,0x01
    ld bc,0xffff

    minc1 16,wa
    minc1 16,wa
    minc1 16,wa
    minc1 16,wa
    minc1 16,wa
    minc1 16,wa
    minc1 16,wa
    minc1 16,wa
    minc1 16,wa
    minc1 16,wa
    minc1 16,wa
    minc1 16,wa
    minc1 16,wa
    minc1 16,wa

    minc1 8,bc
    minc1 8,bc
    minc1 8,bc
    minc1 8,bc
    minc1 8,bc
    minc1 8,bc
    minc1 8,bc
    minc1 8,bc
    minc1 8,bc
    minc1 8,bc
    minc1 8,bc
    minc1 8,bc
    minc1 8,bc
    minc1 8,bc

end_loop:
    ld hl,0xbabe
    ld (0xffff),0xff
    jp end_loop
bad_end:
    ld hl,0xdead
    ld (0xffff),0xff
    jp bad_end
end