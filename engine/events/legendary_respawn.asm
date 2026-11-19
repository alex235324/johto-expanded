if QOL_ROAMING_SUICUNE
DEF SUICUNE_ROAM_START_GROUP EQU GROUP_ROUTE_38 ; next to Ecruteak
DEF SUICUNE_ROAM_START_MAP   EQU MAP_ROUTE_38
endc

if QOL_RESPAWN_LEGENDARIES
RespawnLegendaries::
; Called after each Elite Four win (QOL_RESPAWN_LEGENDARIES).
; A scripted legendary the player hasn't caught (no Pokédex caught flag) comes
; back if it fainted or the player ran from it.

; Lugia and Ho-Oh: their map callbacks show them again once EVENT_FOUGHT_* is reset.
	ld de, LUGIA
	ld bc, EVENT_FOUGHT_LUGIA
	call .ResetFoughtEventIfNotCaught
	ld de, HO_OH
	ld bc, EVENT_FOUGHT_HO_OH
	call .ResetFoughtEventIfNotCaught

; Raikou and Entei: put them back to roaming if they're gone (fainted).
	ld de, EVENT_RELEASED_THE_BEASTS
	ld b, CHECK_FLAG
	call EventFlagAction
	ret z

	ld de, RAIKOU
	ld hl, wRoamMon1
	lb bc, GROUP_ROUTE_42, MAP_ROUTE_42
	call .RespawnRoamer
	ld de, ENTEI
	ld hl, wRoamMon2
	lb bc, GROUP_ROUTE_37, MAP_ROUTE_37
if QOL_ROAMING_SUICUNE
	call .RespawnRoamer
; Suicune: only once it has fled from Tin Tower
	ld de, EVENT_FOUGHT_SUICUNE
	ld b, CHECK_FLAG
	call EventFlagAction
	ret z
	ld de, SUICUNE
	ld hl, wRoamMon3
	lb bc, SUICUNE_ROAM_START_GROUP, SUICUNE_ROAM_START_MAP
endc
	; fallthrough

.RespawnRoamer:
; de = species index, hl = roam_struct, bc = starting map (group, number)
	ld a, [hl]
	and a
	ret nz ; still roaming
	push hl
	push bc
	push de
	call CheckCaughtMonIndex
	pop hl ; species index
	pop bc
	pop de ; roam_struct
	ret nz ; already caught one
	push bc
	call GetPokemonIDFromIndex
	pop bc
	ld [de], a ; species
	inc de
	ld a, 40
	ld [de], a ; level, as in InitRoamMons
	inc de
	ld a, b
	ld [de], a ; map group
	inc de
	ld a, c
	ld [de], a ; map number
	inc de
	xor a
	ld [de], a ; HP: 0 makes the battle generate new stats
	ret

.ResetFoughtEventIfNotCaught:
; de = species index, bc = event flag
	push bc
	call CheckCaughtMonIndex
	pop de
	ret nz
	ld b, RESET_FLAG
	jp EventFlagAction
endc

if QOL_ROAMING_SUICUNE
InitRoamSuicune::
; Called when Suicune flees from Tin Tower 1F: start it roaming in slot 3.
	ld hl, SUICUNE
	call GetPokemonIDFromIndex
	ld [wRoamMon3Species], a
	ld a, 40
	ld [wRoamMon3Level], a
	ld a, SUICUNE_ROAM_START_GROUP
	ld [wRoamMon3MapGroup], a
	ld a, SUICUNE_ROAM_START_MAP
	ld [wRoamMon3MapNumber], a
	xor a ; generate new stats
	ld [wRoamMon3HP], a
	ret
endc
