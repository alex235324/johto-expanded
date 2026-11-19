RepelWoreOffScript::
	opentext
	writetext .RepelWoreOffText
if QOL_REPEL_PROMPT
	callasm .CheckSameRepelInBag
	iffalse .done
	promptbutton
	writetext .UseAnotherText
	yesorno
	iffalse .close
	callasm .UseAnotherRepel
	writetext .UsedAnotherText
	playsound SFX_FULL_HEAL
	waitsfx
.done
endc
	waitbutton
.close
	closetext
	end

.RepelWoreOffText:
	text_far _RepelWoreOffText
	text_end

if QOL_REPEL_PROMPT
.UseAnotherText:
	text "Use another"
	line "@"
	text_ram wStringBuffer1
	text "?"
	done

.UsedAnotherText:
	text "<PLAYER> used the"
	line "@"
	text_ram wStringBuffer1
	text "."
	done

.CheckSameRepelInBag:
; wScriptVar = TRUE if the bag holds another Repel of the kind that just wore off.
; Also puts its name in wStringBuffer1.
	xor a
	ld [wScriptVar], a
	ld a, [wRepelType]
	call .GetRepelSteps
	ret z
	ld a, [wRepelType]
	ld [wCurItem], a
	ld hl, wNumItems
	call CheckItem
	ret nc
	ld a, [wRepelType]
	ld [wNamedObjectIndex], a
	call GetItemName
	ld a, TRUE
	ld [wScriptVar], a
	ret

.UseAnotherRepel:
	ld a, [wRepelType]
	call .GetRepelSteps
	ld [wRepelEffect], a
	ld a, [wRepelType]
	ld [wCurItem], a
	ld a, 1
	ld [wItemQuantityChange], a
	ld hl, wNumItems
	jp TossItem

.GetRepelSteps:
; Return the step count for Repel item a in a (z if a isn't a Repel).
; Matches RepelEffect, SuperRepelEffect and MaxRepelEffect.
	ld b, 100
	cp REPEL
	jr z, .got_steps
	ld b, 200
	cp SUPER_REPEL
	jr z, .got_steps
	ld b, 250
	cp MAX_REPEL
	jr z, .got_steps
	xor a
	ret

.got_steps
	ld a, b
	and a
	ret
endc
