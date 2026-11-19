; Gen V experience formula (Black/White):
;   exp = floor(b * L / 5 * ((2L + 10) / (L + Lp + 10)) ^ 2.5) + 1
; b = the defeated Pokémon's base exp (already divided among participants),
; L = its level, Lp = the level of the Pokémon gaining exp.
; GiveExperiencePoints then applies the trainer battle, traded and Lucky Egg
; boosts (1.5x each), like Gen V.
;
; In: wCurPartyMon, wEnemyMonBaseExp, wEnemyMonLevel
; Out: hQuotient = exp (big endian, at most $ffff)

DEF GEN5_EXP_TABLE_SIZE EQU 896

CalcGen5Exp::
; X = b * L / 5
	xor a
	ldh [hMultiplicand + 0], a
	ldh [hMultiplicand + 1], a
	ld a, [wEnemyMonBaseExp]
	ldh [hMultiplicand + 2], a
	ld a, [wEnemyMonLevel]
	ldh [hMultiplier], a
	call Multiply
	ld a, 5
	ldh [hDivisor], a
	ld b, 4
	call Divide
	ldh a, [hQuotient + 2]
	ld [wGen5ExpScratch + 0], a
	ldh a, [hQuotient + 3]
	ld [wGen5ExpScratch + 1], a

; q = (2L + 10) * 1024 / (L + Lp + 10), in 6.10 fixed point
	ld a, MON_LEVEL
	call GetPartyParamLocation
	ld a, [wEnemyMonLevel]
	ld d, a
	add [hl]
	add 10
	ld c, a ; L + Lp + 10 (at most 210)
	ld a, d
	add a
	add 10
	ld h, a ; 2L + 10 (at most 210)
	ld l, 0
	ld e, 0
	add hl, hl
	rl e
	add hl, hl
	rl e ; e:h:l = (2L + 10) << 10
	call .Divide24By8 ; hl = q (e = 0)

; table index: q below 512, else q / 4 + 384
	ld a, h
	cp HIGH(512)
	jr c, .got_index
	srl h
	rr l
	srl h
	rr l
	ld de, 384
	add hl, de
	ld a, h
	cp HIGH(GEN5_EXP_TABLE_SIZE)
	jr c, .got_index
	jr nz, .clamp
	ld a, l
	cp LOW(GEN5_EXP_TABLE_SIZE)
	jr c, .got_index
.clamp
	ld hl, GEN5_EXP_TABLE_SIZE - 1
.got_index

; T = q ^ 2.5 (x4096) from the table
	add hl, hl
	ld de, Gen5ExpScaleTable
	add hl, de
	ld a, [hli]
	ld [wGen5ExpScratch + 2], a ; low byte
	ld a, [hl]
	ld [wGen5ExpScratch + 3], a ; high byte

; X * T = X * low + (X * high) << 8
	call .LoadX
	ld a, [wGen5ExpScratch + 2]
	ldh [hMultiplier], a
	call Multiply
	ldh a, [hProduct + 1]
	ld d, a
	ldh a, [hProduct + 2]
	ld e, a ; de = bits 8-23 (bits 0-7 are shifted out below)
	push de
	call .LoadX
	ld a, [wGen5ExpScratch + 3]
	ldh [hMultiplier], a
	call Multiply
	pop de
	ldh a, [hProduct + 3]
	add e
	ld e, a
	ldh a, [hProduct + 2]
	adc d
	ld d, a
	ldh a, [hProduct + 1]
	adc 0
	ld c, a ; c:d:e = (X * T) >> 8

; / 4096: 8 bits are already gone, shift out 4 more
	ld b, 4
.shift
	srl c
	rr d
	rr e
	dec b
	jr nz, .shift
	ld a, c
	and a
	jr z, .fits
	ld de, $ffff
.fits
; + 1 (unless that would overflow)
	inc de
	ld a, d
	or e
	jr nz, .store
	dec de
.store
	xor a
	ldh [hQuotient + 0], a
	ldh [hQuotient + 1], a
	ld a, d
	ldh [hQuotient + 2], a
	ld a, e
	ldh [hQuotient + 3], a
	ret

.LoadX:
	xor a
	ldh [hMultiplicand + 0], a
	ld a, [wGen5ExpScratch + 0]
	ldh [hMultiplicand + 1], a
	ld a, [wGen5ExpScratch + 1]
	ldh [hMultiplicand + 2], a
	ret

.Divide24By8:
; e:h:l = e:h:l / c (c != 0)
	xor a ; remainder
	ld b, 24
.div_loop
	add hl, hl
	rl e
	rla
	jr c, .subtract ; remainder went past 8 bits, so it's >= c
	cp c
	jr c, .next
.subtract
	sub c
	inc l
.next
	dec b
	jr nz, .div_loop
	ret

INCLUDE "data/battle/gen5_exp_scale.asm"
