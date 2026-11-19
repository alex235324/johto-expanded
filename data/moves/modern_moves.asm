; Gen 8 (Sword/Shield) power, accuracy and PP for moves that later
; generations changed (QOL_MODERN_MOVES). Effects and types are unchanged.
; Each line: modern_move MOVE, power, accuracy, pp
; Used by the `move` macro in data/moves/moves.asm, which looks up each
; entry by its move constant. Moves with variable or fixed damage (Low Kick,
; Return, Hidden Power, Magnitude, Beat Up, ...) are left alone.

MACRO modern_move
	DEF MODERN_MOVE_POWER_{d:\1} EQU \2
	DEF MODERN_MOVE_ACC_{d:\1}   EQU \3
	DEF MODERN_MOVE_PP_{d:\1}    EQU \4
ENDM

	modern_move RAZOR_WIND,     80, 100, 10
	modern_move FLY,            90,  95, 15
	modern_move BIND,           15,  85, 20
	modern_move VINE_WHIP,      45, 100, 25
	modern_move JUMP_KICK,     100,  95, 10
	modern_move TACKLE,         40, 100, 35
	modern_move WRAP,           15,  90, 20
	modern_move THRASH,        120, 100, 10
	modern_move PIN_MISSILE,    25,  95, 20
	modern_move DISABLE,         0, 100, 20
	modern_move FLAMETHROWER,   90, 100, 15
	modern_move HYDRO_PUMP,    110,  80,  5
	modern_move SURF,           90, 100, 15
	modern_move ICE_BEAM,       90, 100, 10
	modern_move BLIZZARD,      110,  70,  5
	modern_move SUBMISSION,     80,  80, 20
	modern_move ABSORB,         20, 100, 25
	modern_move MEGA_DRAIN,     40, 100, 15
	modern_move GROWTH,          0, 100, 20
	modern_move PETAL_DANCE,   120, 100, 10
	modern_move FIRE_SPIN,      35,  85, 15
	modern_move THUNDERBOLT,    90, 100, 15
	modern_move THUNDER_WAVE,    0,  90, 20
	modern_move THUNDER,       110,  70, 10
	modern_move DIG,            80, 100, 10
	modern_move TOXIC,           0,  90, 10
	modern_move RECOVER,         0, 100, 10
	modern_move MINIMIZE,        0, 100, 10
	modern_move BARRIER,         0, 100, 20
	modern_move LICK,           30, 100, 30
	modern_move SMOG,           30,  70, 20
	modern_move FIRE_BLAST,    110,  85,  5
	modern_move CLAMP,          35,  85, 15
	modern_move SKULL_BASH,    130, 100, 10
	modern_move HI_JUMP_KICK,  130,  90, 10
	modern_move GLARE,           0, 100, 30
	modern_move POISON_GAS,      0,  90, 40
	modern_move LEECH_LIFE,     80, 100, 10
	modern_move BUBBLE,         40, 100, 30
	modern_move FLASH,           0, 100, 20
	modern_move PSYWAVE,         1, 100, 15
	modern_move ACID_ARMOR,      0, 100, 20
	modern_move CRABHAMMER,    100,  90, 10
	modern_move THIEF,          60, 100, 25
	modern_move SNORE,          50, 100, 15
	modern_move COTTON_SPORE,    0, 100, 40
	modern_move SCARY_FACE,      0, 100, 10
	modern_move ZAP_CANNON,    120,  50,  5
	modern_move BONE_RUSH,      25,  90, 10
	modern_move OUTRAGE,       120, 100, 10
	modern_move GIGA_DRAIN,     75, 100, 10
	modern_move SWAGGER,         0,  85, 15
	modern_move FURY_CUTTER,    40,  95, 20
	modern_move RAPID_SPIN,     50, 100, 40
	modern_move FUTURE_SIGHT,  120, 100, 10
	modern_move ROCK_SMASH,     40, 100, 15
	modern_move WHIRLPOOL,      35,  85, 15
