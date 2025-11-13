
; shift a right r2 times
shiftr8b:
	clr	c
	rrc	a
	djnz	r2, shiftr8b
	ret

; shift r4,5 right r2 times
shiftr16b:
	clr	c
	xch	a, r4
	rrc	a
	xch	a, r4
	xch	a, r5
	rrc	a
	xch	a, r5
	djnz	r2, shiftr16b
	ret

; shift r4,5 left r2 times
shiftl16b:
	clr	c
	xch	a, r5
	rlc	a
	xch	a, r5
	xch	a, r4
	rlc	a
	xch	a, r4
	djnz	r2, shiftl16b
	ret

; maps a in range r6 to r7 to 0-255
; val in r5
map8:
	mov	b, a
	; check if a is in between r6 and r7
	clr	c
	subb	a, r6
	jnc	notsmaller
	mov	a, r6
	sjmp	ok
notsmaller:
	clr	c
	mov	a, b
	subb	a, r7
	jc	smaller
	mov	a, r7
	sjmp	ok
smaller:
	mov	a, b
ok:
	; in - in_min aka a - r6
	clr	c
	subb	a, r6
	mov	r0, a
	mov	r1, #0
	; in_max - in_min aka r7 - r6
	clr	c
	mov	a, r7
	subb	a, r6
	mov	r2, #0
	mov	r3, a
	; divide (in-in_min) by (in_max-in_min)
	acall	div1616
	; quotient can be 0x100, make that case also return 0xff
	mov	a, r4
	jz	map8ex
	mov	r4, #0
	mov	r5, #0xff
map8ex:
	ret


; maps r2,3 in range r4,5 to r6,7 to 0-65535
; ((in - in_min) << 16) / (in_max - in_min)
map16:

	; in_max-in_min
	clr	c
	mov	a, r7
	subb	a, r5
	mov	r7, a
	mov	a, r6
	subb	a, r4
	mov	r6, a

	; in-in_min
	clr	c
	mov	a, r3
	subb	a, r5
	mov	r3, a
	mov	a, r2
	subb	a, r4
	mov	r2, a

	; divide3232
	;acall	div1616

	ret


; r4:r5 * r6:r7 = r0:r1:r2:r3
mul1616:
        ; mul r5 r7
        mov     a, r5
        mov     b, r7
        mul     ab
        mov     r2, b
        mov     r3, a
        ; mul   r5 r6
        mov     a, r5
        mov     b, r6
        mul     ab
        add     a, r2
        mov     r2, a
        mov     a, b
        addc    a, #0
        mov     r1, a
        mov     a, #0
        addc    a, #0
        mov     r0, a
        ; mul r4 r7
        mov     a, r4
        mov     b, r7
        mul     ab
        add     a, r2
        mov     r2, a
        mov     a, b
        addc    a, r1
        mov     r1, a
        mov     a, #0
        addc    a, r0
        mov     r0, a
        ; mul r4 r6
        mov     a, r4
        mov     b, r6
        mul     ab
        add     a, r1
        mov     r1, a
        mov     a, b
        addc    a, r0
        mov     r0, a

        ret

; args r0:r1 dividend, r2:r3 divisor
; returns r4:r5 quotient, r0:r1 remainder
; clobbers a b c r4 r5 r6 r7
div1616:
        clr     c
        mov     r4, #0
        mov     r5, #0
        mov     b, #0   ; shift counter
div1616_1:
        inc     b
        mov     a, r3   ; shift left low divisor
        rlc     a
        mov     r3, a
        mov     a, r2   ; shift left high divisor
        rlc     a
        mov     r2, a
        jnc     div1616_1
div1616_2:
        mov     a, r2   ; shift right high divisor
        rrc     a
        mov     r2, a
        mov     a, r3   ; shift right low divisor
        rrc     a
        mov     r3, a
        clr     c

        mov     a, r0   ; save dividend high
        mov     r6, a
        mov     a, r1   ; save dividend low
        mov     r7, a

        mov     a, r1   ; 16 sub dividend - divisor
        subb    a, r3
        mov     r1, a
        mov     a, r0
        subb    a, r2
        mov     r0, a
        jnc     div1616_3

        mov     a, r6   ; save copy of divisor to undo subtraction
        mov     r0, a
        mov     a, r7
        mov     r1, a
div1616_3:
        cpl     c
        mov     a, r5   ; shift carry into result
        rlc     a
        mov     r5, a
        mov     a, r4
        rlc     a
        mov     r4, a

        djnz    b, div1616_2    ; repeat until b is zero

        ret

; divide 32b by 16b
; args
; r3,2,1,0	dividend
; r5,4		divisor
; return
; r3,2,1,0	quotient
; r7,6,5,4	remainder
; clobber
; a, b,

div3216:
	push	0x08
	push	0x09
	push	0x0a
	push	0x0b
	push	0x0c
	push	0x0d
	push	0x0e
	push	0x0f
	push	psw
	push	dpl
	push	dph
	push	b
	setb	RS0	; reg bank 1
	; rb1r7-4 remainder work
	mov	r7, #0
	mov	r6, #0
	mov	r5, #0
	mov	r4, #0
	mov	b, #32
div3216_loop:
	clr	RS0	; reg bank 0

	; 64b shift left remainder:dividend << 1
	; shift dividend left once
	clr	c
	mov	a, r0
	rlc	a
	mov	r0, a
	mov	a, r1
	rlc	a
	mov	r1, a
	mov	a, r2
	rlc	a
	mov	r2, a
	mov	a, r3
	rlc	a
	mov	r3, a

	setb	RS0	; reg bank 1
	; shift remainder left once
	mov	a, r4
	rlc	a
	mov	r4, a
	mov	a, r5
	rlc	a
	mov	r5, a
	mov	a, r6
	rlc	a
	mov	r6, a
	mov	a, r7
	rlc	a
	mov	r7, a

	; subtract divisor from remainder
	mov	a, r4
	clr	c
	subb	a, 0x04
	mov	dpl, a
	mov	a, r5
	subb	a, 0x05
	mov	dph, a
	mov	a, r6
	subb	a, #0
	mov	0x06, a
	mov	a, r7
	subb	a, #0
	mov	0x07, a
	cpl	c

	jnc	div3216_nc

	; save subtracted value back to remainder
	mov	r7, 0x07
	mov	r6, 0x06
	mov	r5, dph
	mov	r4, dpl

div3216_nc:
	; shift left quotient with result bit
	mov 	a, r0
	rlc 	a
	mov 	r0, a
	mov 	a, r1
	rlc 	a
	mov 	r1, a
	mov 	a, r2
	rlc 	a
	mov 	r2, a
	mov 	a, r3
	rlc 	a
	mov 	r3, a

	djnz	b, div3216_loop

	; move remainder
	mov	0x07, r7
	mov	0x06, r6
	mov	0x05, r5
	mov	0x04, r4
	; move quotient
	mov	0x03, r3
	mov	0x02, r2
	mov	0x01, r1
	mov	0x00, r0

	clr	RS0
	pop	b
	pop	dph
	pop	dpl
	pop	psw
	pop	0x0f
	pop	0x0e
	pop	0x0d
	pop	0x0c
	pop	0x0b
	pop	0x0a
	pop	0x09
	pop	0x08
	ret
