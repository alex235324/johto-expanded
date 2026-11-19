LegendaryLocatorScript::
; Pokémon Center 2F NPC who says where the roaming legendaries are.
	faceplayer
	opentext
	writetext .IntroText
	promptbutton
	special LegendaryLocator
	closetext
	end

.IntroText:
	text "I track the"
	line "legendary #mon"
	cont "that roam Johto."
	done

LegendaryLocator:
; Print where each roaming legendary currently is, or that none are roaming.
	xor a
	ld [wScriptVar], a ; number reported
	ld hl, wRoamMon1
	call .Report
	ld hl, wRoamMon2
	call .Report
	ld hl, wRoamMon3
	call .Report
	ld a, [wScriptVar]
	and a
	ret nz
	ld hl, .NoneText
	jp PrintText

.Report:
; hl = roam_struct
	ld a, [hli] ; species
	and a
	ret z
	ld [wNamedObjectIndex], a
	inc hl ; level
	ld a, [hli] ; map group
	cp GROUP_N_A
	ret z
	ld b, a
	ld c, [hl] ; map number
	push bc
	call GetPokemonName
	ld hl, wStringBuffer1
	ld de, wStringBuffer3
	ld bc, MON_NAME_LENGTH
	call CopyBytes
	pop bc
	call GetWorldMapLocation
	ld e, a
	farcall GetLandmarkName
	ld hl, wScriptVar
	inc [hl]
	ld hl, .SightingText
	jp PrintText

.SightingText:
	text_ram wStringBuffer3
	text " was"
	line "last seen around"
	cont "@"
	text_ram wStringBuffer1
	text "."
	prompt

.NoneText:
	text "Nothing is roaming"
	line "right now. I'll"
	cont "keep watching!"
	prompt
