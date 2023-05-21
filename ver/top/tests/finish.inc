end_loop:
    ld hl,0xbabe
    ldw (0xfffe),0xff01
    jp end_loop
bad_end:
    ld hl,0xdead
    ldw (0xfffe),0xff00
    jp bad_end