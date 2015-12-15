SLOTS_NOMATCH EQU -1
SLOTS_SEVEN EQU $00
SLOTS_POKEBALL EQU $04
SLOTS_CHERRY EQU $08
SLOTS_PIKACHU EQU $0c
SLOTS_SQUIRTLE EQU $10
SLOTS_STARYU EQU $14
REEL_SIZE EQU 15

_SlotMachine:
	ld hl, Options
	set 4, [hl]
	call .InitGFX
	call DelayFrame
.loop
	call SlotsLoop
	jr nc, .loop
	call WaitSFX
	ld de, SFX_QUIT_SLOTS
	call PlaySFX
	call WaitSFX
	call ClearBGPalettes
	callba MobileFn_105fd0
	ld hl, Options
	res 4, [hl]
	ld hl, rLCDC ; $ff40
	res 2, [hl]
	ret

.InitGFX: ; 926f7 (24:66f7)
	call ClearBGPalettes
	call ClearTileMap
	call ClearSprites
	ld de, MUSIC_NONE
	call PlayMusic
	call DelayFrame
	call DisableLCD
	hlbgcoord 0, 0
	lb bc, 4, 0
	ld a, " "
	call ByteFill
	ld b, SCGB_05
	call GetSGBLayout
	callab ClearSpriteAnims
	ld hl, wSlots
	ld bc, wSlotsDataEnd - wSlots
	xor a
	call ByteFill

	ld hl, Slots2LZ
	ld de, VTiles0 tile $00
	call Decompress

	ld hl, Slots3LZ
	ld de, VTiles0 tile $40
	call Decompress

	ld hl, Slots1LZ
	ld de, VTiles2 tile $00
	call Decompress

	ld hl, Slots2LZ
	ld de, VTiles2 tile $25
	call Decompress

	ld hl, SlotsTilemap
	decoord 0, 0
	ld bc, SCREEN_WIDTH * 12
	call CopyBytes

	ld hl, rLCDC ; $ff40
	set 2, [hl]
	call EnableLCD
	ld hl, wSlots ; Alias: wTrademons
	ld bc, wSlotsEnd - wSlots ; Alias: wTrademonsEnd
	xor a
	call ByteFill
	call InitReelTiles
	call Slots_GetPals
	ld a, $7
	ld hl, wSpriteAnimDict
	ld [hli], a
	ld [hl], $40
	xor a
	ld [wJumptableIndex], a
	ld a, SLOTS_NOMATCH
	ld [wSlotBias], a
	ld de, MUSIC_GAME_CORNER
	call PlayMusic
	xor a
	ld [wd002], a
	call Random
	and %00101010
	ret nz
	ld a, $1
	ld [wd002], a
	ret

Slots_GetPals: ; 9279b (24:679b)
	ld a, $e4
	call DmgToCgbBGPals
	lb de, $e4, $e4
	ld a, [hCGB]
	and a
	jr nz, .cgb
	lb de, $c0, $e4
.cgb
	call DmgToCgbObjPals
	ret

SlotsLoop: ; 927af (24:67af)
	ld a, [wJumptableIndex]
	bit 7, a
	jr nz, .stop
	call SlotsJumptable
	call Slots_SpinReels
	xor a
	ld [wCurrSpriteOAMAddr], a
	callab DoNextFrameForFirst16Sprites
	call .PrintCoinsAndPayout
	call .DummyFunc
	call DelayFrame
	and a
	ret

.stop
	scf
	ret

.DummyFunc: ; 927d3 (24:67d3)
; dummied out
	ret
	ld a, [wReel1ReelAction]
	and a
	ret nz
	ld a, [wReel2ReelAction]
	and a
	ret nz
	ld a, [wFirstTwoReelsMatchingSevens]
	and a
	jr nz, .matching_sevens
	ld a, $e4
	call DmgToCgbBGPals
	ret

.matching_sevens
	ld a, [TextDelayFrames]
	and $7
	ret nz
	ld a, [rBGP]
	xor %1100
	call DmgToCgbBGPals
	ret

; 927f8

.PrintCoinsAndPayout: ; 927f8 (24:67f8)
	hlcoord 5, 1
	ld de, Coins
	lb bc, PRINTNUM_LEADINGZEROS | 2, 4
	call PrintNum
	hlcoord 11, 1
	ld de, wPayout
	lb bc, PRINTNUM_LEADINGZEROS | 2, 4
	call PrintNum
	ret

; 92811 (24:6811)

Function92811: ; 92811
; unreferenced - debug function?
	ld a, [wSlotBias]
	add 0
	daa
	ld e, a
	and $f
	add "0"
	hlcoord 1, 0
	ld [hl], a
	ld a, e
	swap a
	and $f
	add "0"
	hlcoord 0, 0
	ld [hl], a
	ret

; 9282c

Function9282c: ; 9282c
; unreferenced
; animate OAM tiles?
	ld hl, wcf66
	ld a, [hl]
	inc [hl]
	and $7
	ret nz
	ld hl, Sprites + 16 * 4 + 2
	ld c, 40 - 16
.loop
	ld a, [hl]
	xor $20
	ld [hli], a
rept 3
	inc hl
endr
	dec c
	jr nz, .loop
	ret

; 92844

SlotsJumptable: ; 92844 (24:6844)
	ld a, [wJumptableIndex]
	ld e, a
	ld d, 0
	ld hl, .Jumptable
rept 2
	add hl, de
endr
	ld a, [hli]
	ld h, [hl]
	ld l, a
	jp [hl]

; 92853 (24:6853)


.Jumptable: ; 92853 (24:6853)
	jumptable_start
	jumptable Slots_Init        ; 00
	jumptable Slots_BetAndStart ; 01
	jumptable Slots_WaitStart     ; 02
	jumptable Slots_WaitReel1   ; 03
	jumptable Slots_WaitStopReel1     ; 04
	jumptable Slots_WaitReel2   ; 05
	jumptable Slots_WaitStopReel2     ; 06
	jumptable Slots_WaitReel3   ; 07
	jumptable Slots_WaitStopReel3     ; 08
	jumptable Slots_Next          ; 09
	jumptable Slots_Next          ; 0a
	jumptable Slots_Next          ; 0b
	jumptable Slots_FlashIfWin     ; 0c
	jumptable Slots_FlashScreen     ; 0d
	jumptable Slots_GiveEarnedCoins     ; 0e
	jumptable Slots_PayoutTextAndAnim     ; 0f
	jumptable Slots_PayoutAnim     ; 10
	jumptable Slots_RestartOrQuit     ; 11
	jumptable Slots_Quit        ; 12

Slots_Next: ; 92879 (24:6879)
	ld hl, wJumptableIndex
	inc [hl]
	ret

Slots_Init: ; 9287e (24:687e)
	call Slots_Next
	xor a
	ld [wFirstTwoReelsMatching], a
	ld [wFirstTwoReelsMatchingSevens], a
	ld a, -1
	ld [wSlotMatched], a
	ret

Slots_BetAndStart: ; 9288e (24:688e)
	call Slots_AskBet
	jr nc, .proceed
	ld a, Slots_QuitTableIndex
	ld [wJumptableIndex], a
	ret

.proceed
	call Slots_Next
	call Slots_IlluminateBetLights
	call Slots_InitBias
	ld a, 32
	ld [wcf64], a
	ld a, 4 ; ReelAction_NormalRateTableIndex
	ld [wReel1ReelAction], a
	ld [wReel2ReelAction], a
	ld [wReel3ReelAction], a
	ld a, $4
	ld [wReel1 + 9], a
	ld [wReel2 + 9], a
	ld [wReel3 + 9], a
	call WaitSFX
	ld a, SFX_SLOT_MACHINE_START
	call Slots_PlaySFX
	ret

Slots_WaitStart: ; 928c6 (24:68c6)
	ld hl, wcf64
	ld a, [hl]
	and a
	jr z, .proceed
	dec [hl]
	ret

.proceed
	call Slots_Next
	xor a
	ld [hJoypadSum], a
	ret

Slots_WaitReel1: ; 928d6 (24:68d6)
	ld hl, hJoypadSum ; $ffa5
	ld a, [hl]
	and A_BUTTON
	ret z
	call Slots_Next
	call Slots_StopReel1
	ld [wReel1ReelAction], a
Slots_WaitStopReel1: ; 928e6 (24:68e6)
	ld a, [wReel1ReelAction]
	cp $0
	ret nz
	ld a, SFX_STOP_SLOT
	call Slots_PlaySFX
	ld bc, wReel1
	ld de, wReel1Stopped
	call Slots_LoadReelState
	call Slots_Next
	xor a
	ld [hJoypadSum], a
Slots_WaitReel2: ; 92900 (24:6900)
	ld hl, hJoypadSum ; $ffa5
	ld a, [hl]
	and A_BUTTON
	ret z
	call Slots_Next
	call Slots_StopReel2
	ld [wReel2ReelAction], a
Slots_WaitStopReel2: ; 92910 (24:6910)
	ld a, [wReel2ReelAction]
	cp $0
	ret nz
	ld a, SFX_STOP_SLOT
	call Slots_PlaySFX
	ld bc, wReel2
	ld de, wReel2Stopped
	call Slots_LoadReelState
	call Slots_Next
	xor a
	ld [hJoypadSum], a
Slots_WaitReel3: ; 9292a (24:692a)
	ld hl, hJoypadSum ; $ffa5
	ld a, [hl]
	and A_BUTTON
	ret z
	call Slots_Next
	call Slots_StopReel3
	ld [wReel3ReelAction], a
Slots_WaitStopReel3: ; 9293a (24:693a)
	ld a, [wReel3ReelAction]
	cp $0
	ret nz
	ld a, SFX_STOP_SLOT
	call Slots_PlaySFX
	ld bc, wReel3
	ld de, wReel3Stopped
	call Slots_LoadReelState
	call Slots_Next
	xor a
	ld [hJoypadSum], a
	ret

Slots_FlashIfWin: ; 92955 (24:6955)
	ld a, [wSlotMatched]
	cp -1
	jr nz, .GotIt
	call Slots_Next
	call Slots_Next
	ret

.GotIt
	call Slots_Next
	ld a, 16
	ld [wcf64], a
Slots_FlashScreen: ; 9296b (24:696b)
	ld hl, wcf64
	ld a, [hl]
	and a
	jr z, .done
	dec [hl]
	srl a
	ret z

	ld a, [rOBP0]
	xor $ff
	ld e, a
	ld d, a
	call DmgToCgbObjPals
	ret

.done
	call Slots_GetPals
	call Slots_Next
	ret

Slots_GiveEarnedCoins: ; 92987 (24:6987)
	xor a
	ld [wFirstTwoReelsMatching], a
	ld [wFirstTwoReelsMatchingSevens], a
	ld a, $e4
	call DmgToCgbBGPals
	call SlotGetPayout
	xor a
	ld [wcf64], a
	call Slots_Next
	ret

Slots_PayoutTextAndAnim: ; 9299e (24:699e)
	call SlotPayoutText
	call Slots_Next
Slots_PayoutAnim: ; 929a4 (24:69a4)
	ld hl, wcf64
	ld a, [hl]
	inc [hl]
	and $1
	ret z
	ld hl, wPayout
	ld a, [hli]
	ld d, a
	or [hl]
	jr z, .done
	ld e, [hl]
	dec de
	ld [hl], e
	dec hl
	ld [hl], d
	ld hl, Coins
	ld d, [hl]
	inc hl
	ld e, [hl]
	call Slot_CheckCoinCaseFull
	jr c, .okay
	inc de
.okay
	ld [hl], e
	dec hl
	ld [hl], d
	ld a, [wcf64]
	and $7
	ret z ; ret nz would be more appropriate
	ld de, SFX_GET_COIN_FROM_SLOTS
	call PlaySFX
	ret

.done
	call Slots_Next
	ret

Slots_RestartOrQuit: ; 929d9 (24:69d9)
	call Slots_DeilluminateBetLights
	call WaitPressAorB_BlinkCursor
	call Slots_AskPlayAgain
	jr c, .exit_slots
	ld a, Slots_InitTableIndex
	ld [wJumptableIndex], a
	ret

.exit_slots
	ld a, Slots_QuitTableIndex
	ld [wJumptableIndex], a
	ret

Slots_Quit: ; 929f0 (24:69f0)
	ld hl, wJumptableIndex
	set 7, [hl]
	ret

Slots_LoadReelState: ; 929f6 (24:69f6)
	push de
	call Slots_GetCurrentReelState
	pop de
	ld a, [hli]
	ld [de], a
	inc de
	ld a, [hli]
	ld [de], a
	inc de
	ld a, [hli]
	ld [de], a
	ret

Slot_CheckCoinCaseFull: ; 92a04 (24:6a04)
	ld a, d
	cp 9999 / $100
	jr c, .not_full
	ld a, e
	cp 9999 % $100
	jr c, .not_full
	scf
	ret

.not_full
	and a
	ret

Slots_GetCurrentReelState: ; 92a12 (24:6a12)
	ld hl, wReel1Position - wReel1
	add hl, bc
	ld a, [hl]
	and a
	jr nz, .okay
	ld a, $f
.okay
	dec a
	and $f
	ld e, a
	ld d, $0
	ld hl, wReel1TilemapAddr - wReel1
	add hl, bc
	ld a, [hli]
	ld h, [hl]
	ld l, a
	add hl, de
	ret

Slots_StopReel1: ; 92a2b (24:6a2b)
	ld a, $7
	ret

Slots_StopReel2: ; 92a2e (24:6a2e)
	ld a, [wSlotBet]
	cp $2
	jr c, .eight
	ld a, [wSlotBias]
	and a
	jr z, .skip
	cp SLOTS_NOMATCH
	jr nz, .eight
.skip
	call .CheckReel1ForASeven
	jr nz, .eight
	call Random
	cp $50 ; 32%
	jr nc, .eight
	ld a, $a
	ret

.eight
	ld a, $8
	ret

.CheckReel1ForASeven: ; 92a51 (24:6a51)
	ld a, [wReel1Stopped]
	and a
	ret z
	ld a, [wReel1Stopped + 1]
	and a
	ret z
	ld a, [wReel1Stopped + 2]
	and a
	ret

Slots_StopReel3: ; 92a60 (24:6a60)
	ld a, [wFirstTwoReelsMatching]
	and a
	jr z, .not_matching_sevens
	ld a, [wFirstTwoReelsMatchingSevens]
	and a
	jr z, .not_matching_sevens
	ld a, [wSlotBias]
	and a
	jr nz, .biased
	call Random
	cp 180
	jr nc, .not_matching_sevens
	cp 120
	jr nc, .sixteen
	cp 60
	jr nc, .eighteen
	ld a, $15
	ret

.biased
	call Random
	cp 160
	jr nc, .not_matching_sevens
	cp 80
	jr nc, .sixteen
.eighteen
	ld a, $12
	ret

.sixteen
	ld a, $10
	ret

.not_matching_sevens
	ld a, $9
	ret

InitReelTiles: ; 92a98 (24:6a98)
	ld bc, wReel1
	ld hl, wReel1OAMAddr - wReel1
	add hl, bc
	ld de, Sprites + 16 * 4
	ld [hl], e
	inc hl
	ld [hl], d
	ld hl, wReel1TilemapAddr - wReel1
	add hl, bc
	ld de, Reel1Tilemap
	ld [hl], e
	inc hl
	ld [hl], d
	ld hl, wReel1XCoord - wReel1
	add hl, bc
	ld [hl], 6 * 8
	call .OAM

	ld bc, wReel2
	ld hl, wReel1OAMAddr - wReel1
	add hl, bc
	ld de, Sprites + 24 * 4
	ld [hl], e
	inc hl
	ld [hl], d
	ld hl, wReel1TilemapAddr - wReel1
	add hl, bc
	ld de, Reel2Tilemap
	ld [hl], e
	inc hl
	ld [hl], d
	ld hl, wReel1XCoord - wReel1
	add hl, bc
	ld [hl], 10 * 8
	call .OAM

	ld bc, wReel3
	ld hl, wReel1OAMAddr - wReel1
	add hl, bc
	ld de, Sprites + 32 * 4
	ld [hl], e
	inc hl
	ld [hl], d
	ld hl, wReel1TilemapAddr - wReel1
	add hl, bc
	ld de, Reel3Tilemap
	ld [hl], e
	inc hl
	ld [hl], d
	ld hl, wReel1XCoord - wReel1
	add hl, bc
	ld [hl], 14 * 8
	call .OAM
	ret

.OAM: ; 92af9 (24:6af9)
	ld hl, wReel1ReelAction - wReel1
	add hl, bc
	ld [hl], $0
	ld hl, wReel1Position - wReel1
	add hl, bc
	ld [hl], REEL_SIZE - 1
	ld hl, wReel1SpinDistance - wReel1
	add hl, bc
	ld [hl], $0
	call UpdateReelPositionAndOAM
	ret

Slots_SpinReels: ; 92b0f (24:6b0f)
	ld bc, wReel1
	call .SpinReel
	ld bc, wReel2
	call .SpinReel
	ld bc, wReel3
	call .SpinReel
	ret

.SpinReel: ; 92b22 (24:6b22)
	ld hl, wReel1SpinDistance - wReel1
	add hl, bc
	ld a, [hl]
	and $f
	jr nz, .skip
	call Function92bd4
.skip
	ld hl, wReel1SpinRate - wReel1
	add hl, bc
	ld a, [hl]
	and a
	ret z
	ld d, a
	ld hl, wReel1SpinDistance - wReel1
	add hl, bc
	add [hl]
	ld [hl], a
	and $f
	jr z, UpdateReelPositionAndOAM
	ld hl, wReel1OAMAddr - wReel1
	add hl, bc
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ld e, $8
.loop
	ld a, [hl]
	add d
	ld [hli], a
rept 3
	inc hl
endr
	dec e
	jr nz, .loop
	ret

UpdateReelPositionAndOAM: ; 92b53 (24:6b53)
	ld hl, wReel1XCoord - wReel1
	add hl, bc
	ld a, [hl]
	ld [wCurrReelXCoord], a
	ld a, 10 * 8
	ld [wCurrReelYCoord], a
	ld hl, wReel1Position - wReel1
	add hl, bc
	ld e, [hl]
	ld d, 0
	ld hl, wReel1TilemapAddr - wReel1
	add hl, bc
	ld a, [hli]
	ld h, [hl]
	ld l, a
	add hl, de
	ld e, l
	ld d, h
	call .LoadOAM
	ld hl, wReel1Position - wReel1
	add hl, bc
	ld a, [hl]
	inc a
	and $f
	cp REEL_SIZE
	jr nz, .load
	xor a
.load
	ld [hl], a
	ret

.LoadOAM: ; 92b83 (24:6b83)
	ld hl, wReel1OAMAddr - wReel1
	add hl, bc
	ld a, [hli]
	ld h, [hl]
	ld l, a
.loop
	ld a, [wCurrReelYCoord]
	ld [hli], a
	ld a, [wCurrReelXCoord]
	ld [hli], a
	ld a, [de]
	ld [hli], a
	srl a
	srl a
	set 7, a
	ld [hli], a

	ld a, [wCurrReelYCoord]
	ld [hli], a
	ld a, [wCurrReelXCoord]
	add 1 * 8
	ld [hli], a
	ld a, [de]
	inc a
	inc a
	ld [hli], a
	srl a
	srl a
	set 7, a
	ld [hli], a
	inc de
	ld a, [wCurrReelYCoord]
	sub 2 * 8
	ld [wCurrReelYCoord], a
	cp 2 * 8
	jr nz, .loop
	ret

; 92bbe (24:6bbe)

Function92bbe: ; 92bbe
	push hl
	srl a
	srl a
	add Unknown_92bce % $100
	ld l, a
	ld a, 0
	adc Unknown_92bce / $100
	ld h, a
	ld a, [hl]
	pop hl
	ret

; 92bce

Unknown_92bce: ; 92bce
	db 0, 1, 2, 3, 4, 5
; 92bd4

Function92bd4: ; 92bd4 (24:6bd4)
	ld hl, wReel1ReelAction - wReel1
	add hl, bc
	ld e, [hl]
	ld d, 0
	ld hl, .jumptable
rept 2
	add hl, de
endr
	ld a, [hli]
	ld h, [hl]
	ld l, a
	jp [hl]

; 92be4 (24:6be4)

.jumptable: ; 92be4
	jumptable_start
	jumptable ReelAction_DoNothing          ; 00
	jumptable Slots_StopReelIgnoreJoypad    ; 01

	jumptable ReelAction_QuadrupleRate      ; 02
	jumptable ReelAction_DoubleRate         ; 03
	jumptable ReelAction_NormalRate         ; 04
	jumptable ReelAction_HalfRate           ; 05
	jumptable ReelAction_QuarterRate        ; 06

	jumptable ReelAction_StopReel1          ; 07
	jumptable ReelAction_StopReel2          ; 08
	jumptable ReelAction_StopReel3          ; 09

	jumptable Function92cd2                 ; 0a
	jumptable Function92cf8                 ; 0b
	jumptable Function92d13                 ; 0c
	jumptable Function92df7                 ; 0d
	jumptable Function92e10                 ; 0e
	jumptable Function92e31                 ; 0f

	jumptable Function92e47                 ; 10
	jumptable Function92e64                 ; 11

	jumptable Function92d20                 ; 12
	jumptable Function92d4f                 ; 13
	jumptable Function92d6e                 ; 14

	jumptable Slots_InitChansey                 ; 15
	jumptable Function92da4                 ; 16
	jumptable Function92db3                 ; 17
	jumptable Function92dca                 ; 18
; 92c16

ReelAction_DoNothing: ; 92c16
	ret

; 92c17

ReelAction_QuadrupleRate: ; 92c17
	ld hl, wReel1SpinRate - wReel1
	add hl, bc
	ld [hl], $10
	ret

; 92c1e

ReelAction_DoubleRate: ; 92c1e
	ld hl, wReel1SpinRate - wReel1
	add hl, bc
	ld [hl], $8
	ret

; 92c25

ReelAction_NormalRate: ; 92c25
	ld hl, wReel1SpinRate - wReel1
	add hl, bc
	ld [hl], $4
	ret

; 92c2c

ReelAction_HalfRate: ; 92c2c
	ld hl, wReel1SpinRate - wReel1
	add hl, bc
	ld [hl], $2
	ret

; 92c33

ReelAction_QuarterRate: ; 92c33
	ld hl, wReel1SpinRate - wReel1
	add hl, bc
	ld [hl], $1
	ret

; 92c3a

Slots_StopReel: ; 92c3a
	ld hl, wReel1SpinRate - wReel1
	add hl, bc
	ld [hl], $0
	ld hl, wReel1ReelAction - wReel1
	add hl, bc
	ld [hl], $1
	ld hl, wReel1Slot0f - wReel1
	add hl, bc
	ld [hl], $3
Slots_StopReelIgnoreJoypad: ; 92c4c
	ld hl, wReel1Slot0f - wReel1
	add hl, bc
	ld a, [hl]
	and a
	jr z, .EndReel
	dec [hl]
	ret

.EndReel
	ld hl, wReel1ReelAction - wReel1
	add hl, bc
	ld a, $0
	ld [hl], a
	ret

; 92c5e

ReelAction_StopReel1: ; 92c5e
	ld a, [wSlotBias]
	cp SLOTS_NOMATCH
	jr z, .NoBias
	ld hl, wReel1Slot09 - wReel1
	add hl, bc
	ld a, [hl]
	and a
	jr z, .NoBias
	dec [hl]
	call .CheckForBias
	ret nz
.NoBias
	call Slots_StopReel
	ret

; 92c76

.CheckForBias: ; 92c76
	call Slots_GetCurrentReelState
	ld a, [wSlotBias]
	ld e, a
	ld a, [hli]
	cp e
	ret z
	ld a, [hli]
	cp e
	ret z
	ld a, [hl]
	cp e
	ret

; 92c86

ReelAction_StopReel2: ; 92c86
	call Slots_CheckMatchedFirstTwoReels
	jr nc, .nope
	ld a, [wSlotBuildingMatch]
	ld hl, wSlotBias
	cp [hl]
	jr z, .biased_match
.nope
	ld a, [wSlotBias]
	cp $ff
	jr z, .biased_match
	ld hl, wReel1Slot09 - wReel1
	add hl, bc
	ld a, [hl]
	and a
	jr z, .biased_match
	dec [hl]
	ret

.biased_match
	call Slots_StopReel
	ret

; 92ca9

ReelAction_StopReel3: ; 92ca9
	call Slots_CheckMatchedAllThreeReels
	jr nc, .NoMatch
	ld hl, wSlotBias
	cp [hl]
	jr z, .bias
	ld hl, wReel1Slot09 - wReel1
	add hl, bc
	ld a, [hl]
	and a
	ret z
	dec [hl]
	ret

.NoMatch
	ld a, [wSlotBias]
	cp SLOTS_NOMATCH
	jr z, .bias
	ld hl, wReel1Slot09 - wReel1
	add hl, bc
	ld a, [hl]
	and a
	jr z, .bias
	dec [hl]
	ret

.bias
	call Slots_StopReel
	ret

; 92cd2

Function92cd2: ; 92cd2
	call Slots_CheckMatchedFirstTwoReels
	jr nc, .no_match
	ld a, [wFirstTwoReelsMatchingSevens]
	and a
	jr z, .no_match
	call Slots_StopReel
	ret

.no_match
	ld a, SFX_STOP_SLOT
	call Slots_PlaySFX
	ld hl, wReel1ReelAction - wReel1
	add hl, bc
	inc [hl]
	ld hl, wReel1Slot0a - wReel1
	add hl, bc
	ld [hl], $20
	ld hl, wReel1SpinRate - wReel1
	add hl, bc
	ld [hl], $0
	ret

; 92cf8

Function92cf8: ; 92cf8
	ld hl, wReel1Slot0a - wReel1
	add hl, bc
	ld a, [hl]
	and a
	jr z, .asm_92d02
	dec [hl]
	ret

.asm_92d02
	ld a, SFX_THROW_BALL
	call Slots_PlaySFX
	ld hl, wReel1ReelAction - wReel1
	add hl, bc
	inc [hl]
	ld hl, wReel1SpinRate - wReel1
	add hl, bc
	ld [hl], $8
	ret

; 92d13

Function92d13: ; 92d13
	call Slots_CheckMatchedFirstTwoReels
	ret nc
	ld a, [wFirstTwoReelsMatchingSevens]
	and a
	ret z
	call Slots_StopReel
	ret

; 92d20

Function92d20: ; 92d20
	call Slots_CheckMatchedAllThreeReels
	ret c
	ld a, SFX_STOP_SLOT
	call Slots_PlaySFX
	call Slots_WaitSFX
	ld hl, wReel1ReelAction - wReel1
	add hl, bc
	inc [hl]
	ld hl, wReel1SpinRate - wReel1
	add hl, bc
	ld [hl], $0
	call Function92fc0
	push bc
	push af
	depixel 12, 13
	ld a, SPRITE_ANIM_INDEX_SLOT_GOLEM
	call _InitSpriteAnimStruct
	ld hl, SPRITEANIMSTRUCT_0E
	add hl, bc
	pop af
	ld [hl], a
	pop bc
	xor a
	ld [wcf64], a

Function92d4f: ; 92d4f
	ld a, [wcf64]
	cp $2
	jr z, .asm_92d5b
	cp $1
	jr z, .asm_92d62
	ret

.asm_92d5b
	call Slots_CheckMatchedAllThreeReels
	call Slots_StopReel
	ret

.asm_92d62
	ld hl, wReel1ReelAction - wReel1
	add hl, bc
	inc [hl]
	ld hl, wReel1SpinRate - wReel1
	add hl, bc
	ld [hl], $8
	ret

; 92d6e

Function92d6e: ; 92d6e
	xor a
	ld [wcf64], a
	ld hl, wReel1ReelAction - wReel1
	add hl, bc
	dec [hl]
	ld hl, wReel1SpinRate - wReel1
	add hl, bc
	ld [hl], $0
	ret

; 92d7e

Slots_InitChansey: ; 92d7e
	call Slots_CheckMatchedAllThreeReels
	ret c
	ld a, SFX_STOP_SLOT
	call Slots_PlaySFX
	call Slots_WaitSFX
	ld hl, wReel1ReelAction - wReel1
	add hl, bc
	inc [hl]
	ld hl, wReel1SpinRate - wReel1
	add hl, bc
	ld [hl], $0
	push bc
	depixel 12, 0
	ld a, SPRITE_ANIM_INDEX_SLOTS_CHANSEY
	call _InitSpriteAnimStruct
	pop bc
	xor a
	ld [wcf64], a
	ret

; 92da4

Function92da4: ; 92da4
	ld a, [wcf64]
	and a
	ret z
	ld hl, wReel1ReelAction - wReel1
	add hl, bc
	inc [hl]
	ld a, $2
	ld [wcf64], a

Function92db3: ; 92db3
	ld a, [wcf64]
	cp $4
	ret c
	ld hl, wReel1ReelAction - wReel1
	add hl, bc
	inc [hl]
	ld hl, wReel1SpinRate - wReel1
	add hl, bc
	ld [hl], $10
	ld hl, wReel1Slot0a - wReel1
	add hl, bc
	ld [hl], $11

Function92dca: ; 92dca
	ld hl, wReel1Slot0a - wReel1
	add hl, bc
	ld a, [hl]
	and a
	jr z, .asm_92dd4
	dec [hl]
	ret

.asm_92dd4
	call Slots_CheckMatchedAllThreeReels
	jr nc, .asm_92de5
	and a
	jr nz, .asm_92de5
	ld a, $5
	ld [wcf64], a
	call Slots_StopReel
	ret

.asm_92de5
	ld hl, wReel1SpinRate - wReel1
	add hl, bc
	ld [hl], $0
	ld hl, wReel1ReelAction - wReel1
	add hl, bc
rept 2
	dec [hl]
endr
	ld a, $1
	ld [wcf64], a
	ret

; 92df7

Function92df7: ; 92df7
	call Slots_CheckMatchedAllThreeReels
	ret c
	ld a, SFX_STOP_SLOT
	call Slots_PlaySFX
	call Slots_WaitSFX
	ld hl, wReel1ReelAction - wReel1
	add hl, bc
	inc [hl]
	call Function92fc0
	ld hl, wReel1Slot0a - wReel1
	add hl, bc
	ld [hl], a
Function92e10: ; 92e10
	ld hl, wReel1Slot0a - wReel1
	add hl, bc
	ld a, [hl]
	and a
	jr nz, .spin
	call Slots_CheckMatchedAllThreeReels
	call Slots_StopReel
	ret

.spin
	dec [hl]
	ld hl, wReel1ReelAction - wReel1
	add hl, bc
	inc [hl]
	ld hl, wReel1Slot0b - wReel1
	add hl, bc
	ld [hl], $20
	ld hl, wReel1SpinRate - wReel1
	add hl, bc
	ld [hl], $0
Function92e31: ; 92e31
	ld hl, wReel1Slot0b - wReel1
	add hl, bc
	ld a, [hl]
	and a
	jr z, .asm_92e3b
	dec [hl]
	ret

.asm_92e3b
	ld hl, wReel1ReelAction - wReel1
	add hl, bc
	dec [hl]
	ld hl, wReel1SpinRate - wReel1
	add hl, bc
	ld [hl], $8 ; 2x
	ret

; 92e47

Function92e47: ; 92e47
	call Slots_CheckMatchedAllThreeReels
	ret c
	ld a, SFX_STOP_SLOT
	call Slots_PlaySFX
	call Slots_WaitSFX
	ld hl, wReel1SpinRate - wReel1
	add hl, bc
	ld [hl], $1
	ld hl, wReel1ReelAction - wReel1
	add hl, bc
	inc [hl]
	ld hl, wReel1Slot0a - wReel1
	add hl, bc
	ld [hl], $10

Function92e64: ; 92e64
	ld hl, wReel1Slot0a - wReel1
	add hl, bc
	ld a, [hl]
	and a
	jr z, .asm_92e73
	dec [hl]
.asm_92e6d
	ld a, SFX_GOT_SAFARI_BALLS
	call Slots_PlaySFX
	ret

.asm_92e73
	ld a, [wSlotBias]
	and a
	jr nz, .asm_92e88
	call Slots_CheckMatchedAllThreeReels
	jr nc, .asm_92e6d
	and a
	jr nz, .asm_92e6d
	call Slots_StopReel
	call WaitSFX
	ret

.asm_92e88
	call Slots_CheckMatchedAllThreeReels
	jr c, .asm_92e6d
	call Slots_StopReel
	call WaitSFX
	ret

; 92e94

Slots_CheckMatchedFirstTwoReels: ; 92e94
	xor a
	ld [wFirstTwoReelsMatching], a
	ld [wFirstTwoReelsMatchingSevens], a
	call Slots_GetCurrentReelState
	call Slots_CopyReelState
	ld a, [wSlotBet]
	and 3
	ld e, a
	ld d, 0
	ld hl, .Jumptable
rept 2
	add hl, de
endr
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ld de, .return
	push de
	jp [hl]

.return
	ld a, [wFirstTwoReelsMatching]
	and a
	ret z
	scf
	ret

; 92ebd

.Jumptable: ; 92ebd
	jumptable_start
	jumptable .zero
	jumptable .one
	jumptable .two
	jumptable .three
; 92ec5

.three: ; 92ec5
	call .CheckUpwardsDiag
	call .CheckDownwardsDiag

.two: ; 92ecb
	call .CheckBottomRow
	call .CheckTopRow

.one: ; 92ed1
	call .CheckMiddleRow

.zero: ; 92ed4
	ret

; 92ed5

.CheckBottomRow: ; 92ed5
	ld hl, wCurrReelStopped
	ld a, [wReel1Stopped]
	cp [hl]
	call z, .StoreResult
	ret

; 92ee0

.CheckUpwardsDiag: ; 92ee0
	ld hl, wCurrReelStopped + 1
	ld a, [wReel1Stopped]
	cp [hl]
	call z, .StoreResult
	ret

; 92eeb

.CheckMiddleRow: ; 92eeb
	ld hl, wCurrReelStopped + 1
	ld a, [wReel1Stopped + 1]
	cp [hl]
	call z, .StoreResult
	ret

; 92ef6

.CheckDownwardsDiag: ; 92ef6
	ld hl, wCurrReelStopped + 1
	ld a, [wReel1Stopped + 2]
	cp [hl]
	call z, .StoreResult
	ret

; 92f01

.CheckTopRow: ; 92f01
	ld hl, wCurrReelStopped + 2
	ld a, [wReel1Stopped + 2]
	cp [hl]
	call z, .StoreResult
	ret

; 92f0c

.StoreResult: ; 92f0c
	ld [wSlotBuildingMatch], a
	and a
	jr nz, .matching_sevens
	ld a, $1
	ld [wFirstTwoReelsMatchingSevens], a

.matching_sevens
	ld a, $1
	ld [wFirstTwoReelsMatching], a
	ret

; 92f1d

Slots_CheckMatchedAllThreeReels: ; 92f1d
	ld a, $ff
	ld [wSlotMatched], a
	call Slots_GetCurrentReelState
	call Slots_CopyReelState
	ld a, [wSlotBet]
	and 3
	ld e, a
	ld d, 0
	ld hl, .Jumptable
rept 2
	add hl, de
endr
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ld de, .return
	push de
	jp [hl]

.return
	ld a, [wSlotMatched]
	cp $ff
	jr nz, .matched_nontrivial
	and a
	ret

.matched_nontrivial
	scf
	ret

; 92f48

.Jumptable: ; 92f48
	jumptable_start
	jumptable .zero
	jumptable .one
	jumptable .two
	jumptable .three
; 92f50

.three: ; 92f50
	call .CheckUpwardsDiag
	call .CheckDownwardsDiag

.two: ; 92f56
	call .CheckBottomRow
	call .CheckTopRow

.one: ; 92f5c
	call .CheckMiddleRow

.zero: ; 92f5f
	ret

; 92f60

.CheckBottomRow: ; 92f60
	ld hl, wCurrReelStopped
	ld a, [wReel1Stopped]
	cp [hl]
	ret nz
	ld hl, wReel2Stopped
	cp [hl]
	call z, .StoreResult
	ret

; 92f70

.CheckUpwardsDiag: ; 92f70
	ld hl, wCurrReelStopped + 2
	ld a, [wReel1Stopped]
	cp [hl]
	ret nz
	ld hl, wReel2Stopped + 1
	cp [hl]
	call z, .StoreResult
	ret

; 92f80

.CheckMiddleRow: ; 92f80
	ld hl, wCurrReelStopped + 1
	ld a, [wReel1Stopped + 1]
	cp [hl]
	ret nz
	ld hl, wReel2Stopped + 1
	cp [hl]
	call z, .StoreResult
	ret

; 92f90

.CheckDownwardsDiag: ; 92f90
	ld hl, wCurrReelStopped
	ld a, [wReel1Stopped + 2]
	cp [hl]
	ret nz
	ld hl, wReel2Stopped + 1
	cp [hl]
	call z, .StoreResult
	ret

; 92fa0

.CheckTopRow: ; 92fa0
	ld hl, wCurrReelStopped + 2
	ld a, [wReel1Stopped + 2]
	cp [hl]
	ret nz
	ld hl, wReel2Stopped + 2
	cp [hl]
	call z, .StoreResult
	ret

; 92fb0

.StoreResult: ; 92fb0
	ld [wSlotMatched], a
	ret

; 92fb4

Slots_CopyReelState: ; 92fb4
	ld de, wCurrReelStopped
	ld a, [hli]
	ld [de], a
	inc de
	ld a, [hli]
	ld [de], a
	inc de
	ld a, [hl]
	ld [de], a
	ret

; 92fc0

Function92fc0: ; 92fc0
	ld hl, wReel1Position - wReel1
	add hl, bc
	ld a, [hl]
	push af
	push hl
	call Function92fcf
	pop hl
	pop af
	ld [hl], a
	ld a, e
	ret

; 92fcf

Function92fcf: ; 92fcf
	ld a, [wSlotBias]
	and a
	jr nz, .not_biased_to_seven
	ld e, $0
.loop1
	ld hl, wReel1Position - wReel1
	add hl, bc
	inc [hl]
	inc e
	push de
	call Slots_CheckMatchedAllThreeReels
	pop de
	jr nc, .loop1
	and a
	jr nz, .loop1
	ret

.not_biased_to_seven
	call Random
	and $7
	cp $4
	jr c, .not_biased_to_seven
	ld e, a
.loop2
	ld a, e
	inc e
	ld hl, wReel1Position - wReel1
	add hl, bc
	add [hl]
	ld [hl], a
	push de
	call Slots_CheckMatchedAllThreeReels
	pop de
	jr c, .loop2
	ret

; 93002

Slots_InitBias: ; 93002 (24:7002)
	ld a, [wSlotBias]
	and a
	ret z
	ld hl, .Normal
	ld a, [ScriptVar]
	and a
	jr z, .okay
	ld hl, .Lucky
.okay
	call Random
	ld c, a
.loop
	ld a, [hli]
	cp c
	jr nc, .done
	inc hl
	jr .loop

.done
	ld a, [hl]
	ld [wSlotBias], a
	ret

; 93023 (24:7023)

.Normal: ; 93023
	db $01, SLOTS_SEVEN    ; 1/256
	db $03, SLOTS_POKEBALL ; 1/128
	db $0a, SLOTS_STARYU   ; 7/256
	db $14, SLOTS_SQUIRTLE ; 5/128
	db $28, SLOTS_PIKACHU  ; 5/64
	db $30, SLOTS_CHERRY   ; 1/32
	db $ff, SLOTS_NOMATCH  ; everything else
; 93031

.Lucky: ; 93031
	db $02, SLOTS_SEVEN    ;  1/128
	db $03, SLOTS_POKEBALL ;  1/256
	db $08, SLOTS_STARYU   ;  5/256
	db $10, SLOTS_SQUIRTLE ;  1/32
	db $1e, SLOTS_PIKACHU  ;  7/128
	db $50, SLOTS_CHERRY   ; 25/128
	db $ff, SLOTS_NOMATCH  ; everything else
; 9303f

Slots_IlluminateBetLights: ; 9303f (24:703f)
	ld b, $14 ; turned on
	ld a, [wSlotBet]
	dec a
	jr z, Slots_Lights1OnOff
	dec a
	jr z, Slots_Lights2OnOff
	jr Slots_Lights3OnOff

Slots_DeilluminateBetLights: ; 9304c (24:704c)
	ld b, $23 ; turned off
Slots_Lights3OnOff: ; 9304e (24:704e)
	hlcoord 3, 2
	call Slots_TurnLightsOnOrOff
	hlcoord 3, 10
	call Slots_TurnLightsOnOrOff
Slots_Lights2OnOff: ; 9305a (24:705a)
	hlcoord 3, 4
	call Slots_TurnLightsOnOrOff
	hlcoord 3, 8
	call Slots_TurnLightsOnOrOff
Slots_Lights1OnOff: ; 93066 (24:7066)
	hlcoord 3, 6

Slots_TurnLightsOnOrOff: ; 93069 (24:7069)
	ld a, b
	ld [hl], a
	ld de, SCREEN_WIDTH / 2 + 3
	add hl, de
	ld [hl], a
	ld de, SCREEN_WIDTH / 2 - 3
	add hl, de
	inc a
	ld [hl], a
	ld de, SCREEN_WIDTH / 2 + 3
	add hl, de
	ld [hl], a
	ret

Slots_AskBet: ; 9307c (24:707c)
.loop
	ld hl, .Text_BetHowManyCoins
	call PrintText
	ld hl, .MenuDataHeader
	call LoadMenuDataHeader
	call VerticalMenu
	call WriteBackup
	ret c
	ld a, [wMenuCursorY]
	ld b, a
	ld a, 4
	sub b
	ld [wSlotBet], a
	ld hl, Coins
	ld c, a
	ld a, [hli]
	and a
	jr nz, .Start
	ld a, [hl]
	cp c
	jr nc, .Start
	ld hl, .Text_NotEnoughCoins
	call PrintText
	jr .loop

.Start
	ld hl, Coins + 1
	ld a, [hl]
	sub c
	ld [hld], a
	jr nc, .ok
	dec [hl]
.ok
	call WaitSFX
	ld de, SFX_PAY_DAY
	call PlaySFX
	ld hl, .Text_Start
	call PrintText
	and a
	ret

; 930c7 (24:70c7)

.Text_BetHowManyCoins: ; 0x930c7
	; Bet how many coins?
	text_jump UnknownText_0x1c5049
	db "@"
; 0x930cc

.Text_Start: ; 0x930cc
	; Start!
	text_jump UnknownText_0x1c505e
	db "@"
; 0x930d1

.Text_NotEnoughCoins: ; 0x930d1
	; Not enough coins.
	text_jump UnknownText_0x1c5066
	db "@"
; 0x930d6

.MenuDataHeader: ; 0x930d6
	db $40 ; flags
	db 10, 14 ; start coords
	db 17, 19 ; end coords
	dw .MenuData2
	db 1 ; default option
; 0x930de

.MenuData2: ; 0x930de
	db $80 ; flags
	db 3 ; items
	db " 3@"
	db " 2@"
	db " 1@"
; 0x930e9

Slots_AskPlayAgain: ; 930e9 (24:70e9)
	ld hl, Coins
	ld a, [hli]
	or [hl]
	jr nz, .you_have_coins
	ld hl, .Text_OutOfCoins
	call PrintText
	ld c, 60
	call DelayFrames
	jr .exit_slots

.you_have_coins
	ld hl, .Text_PlayAgain
	call PrintText
	call LoadMenuTextBox
	lb bc, 14, 12
	call PlaceYesNoBox
	ld a, [wMenuCursorY]
	dec a
	call WriteBackup
	and a
	jr nz, .exit_slots
	and a
	ret

.exit_slots
	scf
	ret

; 9311a (24:711a)

.Text_OutOfCoins: ; 9311a
	text_jump UnknownText_0x1c5079
	db "@"

.Text_PlayAgain: ; 9311f
	text_jump UnknownText_0x1c5092
	db "@"

SlotGetPayout: ; 93124 (24:7124)
	ld a, [wSlotMatched]
	cp -1
	jr z, .no_win
	srl a
	ld e, a
	ld d, 0
	ld hl, .PayoutTable
	add hl, de
	ld a, [hli]
	ld [wPayout + 1], a
	ld e, a
	ld a, [hl]
	ld [wPayout], a
	ld d, a
	callba MobileFn_105fe3
	ret

.PayoutTable
	dw 300
	dw  50
	dw   6
	dw   8
	dw  10
	dw  15

.no_win
	ld hl, wPayout
	xor a
	ld [hli], a
	ld [hl], a
	ret

SlotPayoutText: ; 93158 (24:7158)
	ld a, [wSlotMatched]
	cp -1
	jr nz, .MatchedSomething
	ld hl, .Text_Darn
	call PrintText
	callba MobileFn_105fd0
	ret

.MatchedSomething
	srl a
	ld e, a
	ld d, 0
	ld hl, .PayoutStrings
rept 3
	add hl, de
endr
	ld de, StringBuffer2
	ld bc, 4
	call CopyBytes
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ld de, .return
	push de
	jp [hl]

.return
	ld hl, .Text_PrintPayout
	call PrintText
	callba MobileFn_105f9f
	ret

; 93195 (24:7195)

.PayoutStrings: ; 93195
	dbw "300@", .LinedUpSevens
	dbw "50@@", .LinedUpPokeballs
	dbw "6@@@", .LinedUpMonOrCherry
	dbw "8@@@", .LinedUpMonOrCherry
	dbw "10@@", .LinedUpMonOrCherry
	dbw "15@@", .LinedUpMonOrCherry
; 931b9

.Text_PrintPayout: ; 0x931b9
	start_asm
	ld a, [wSlotMatched]
	add $25
	ldcoord_a 2, 13
	inc a
	ldcoord_a 2, 14
	inc a
	ldcoord_a 3, 13
	inc a
	ldcoord_a 3, 14
	hlcoord 18, 17
	ld [hl], "▼"
	ld hl, .Text_LinedUpWonCoins
rept 4
	inc bc
endr
	ret

; 931db

.Text_LinedUpWonCoins: ; 0x931db
	; lined up! Won @  coins!
	text_jump UnknownText_0x1c509f
	db "@"
; 0x931e0

.Text_Darn: ; 0x931e0
	; Darn!
	text_jump UnknownText_0x1c50bb
	db "@"
; 0x931e5

.LinedUpSevens: ; 931e5
	ld a, SFX_2ND_PLACE
	call Slots_PlaySFX
	call WaitSFX
	ld a, [wd002]
	and a
	jr nz, .asm_931ff
	call Random
	and $14
	ret z
	ld a, $ff
	ld [wSlotBias], a
	ret

.asm_931ff
	call Random
	and $1c
	ret z
	ld a, $ff
	ld [wSlotBias], a
	ret

; 9320b

.LinedUpPokeballs: ; 9320b
	ld a, SFX_3RD_PLACE
	call Slots_PlaySFX
	call WaitSFX
	ret

; 93214

.LinedUpMonOrCherry: ; 93214
	ld a, SFX_PRESENT
	call Slots_PlaySFX
	call WaitSFX
	ret

; 9321d

SlotMachine_AnimateGolem: ; 9321d (24:721d)
	ld hl, SPRITEANIMSTRUCT_0B
	add hl, bc
	ld e, [hl]
	ld d, 0
	ld hl, .Jumptable
rept 2
	add hl, de
endr
	ld a, [hli]
	ld h, [hl]
	ld l, a
	jp [hl]

.Jumptable: ; 9322d (24:722d)
	jumptable_start
	jumptable .init
	jumptable .fall
	jumptable .roll


.init: ; 93233 (24:7233)
	ld hl, SPRITEANIMSTRUCT_0E
	add hl, bc
	ld a, [hl]
	and a
	jr nz, .retain
	ld a, $2
	ld [wcf64], a
	ld hl, SPRITEANIMSTRUCT_INDEX
	add hl, bc
	ld [hl], $0
	ret

.retain
	dec [hl]
	ld hl, SPRITEANIMSTRUCT_0B
	add hl, bc
	inc [hl]
	ld hl, SPRITEANIMSTRUCT_0C
	add hl, bc
	ld [hl], $30
	ld hl, SPRITEANIMSTRUCT_XOFFSET
	add hl, bc
	ld [hl], $0

.fall: ; 93259 (24:7259)
	ld hl, SPRITEANIMSTRUCT_0C
	add hl, bc
	ld a, [hl]
	cp $20
	jr c, .play_sound
	dec [hl]
	ld e, a
	ld d, 14 * 8
	callba BattleAnim_Sine_e
	ld a, e
	ld hl, SPRITEANIMSTRUCT_YOFFSET
	add hl, bc
	ld [hl], a
	ret

.play_sound
	ld hl, SPRITEANIMSTRUCT_0B
	add hl, bc
	inc [hl]
	ld hl, SPRITEANIMSTRUCT_0D
	add hl, bc
	ld [hl], $2
	ld a, $1
	ld [wcf64], a
	ld a, SFX_PLACE_PUZZLE_PIECE_DOWN
	call Slots_PlaySFX
	ret

.roll: ; 93289 (24:7289)
	ld hl, SPRITEANIMSTRUCT_XOFFSET
	add hl, bc
	ld a, [hl]
rept 2
	inc [hl]
endr
	cp 9 * 8
	jr nc, .restart
	and $3
	ret nz
	ld hl, SPRITEANIMSTRUCT_0D
	add hl, bc
	ld a, [hl]
	xor $ff
	inc a
	ld [hl], a
	ld [hSCY], a
	ret

.restart
	ld hl, SPRITEANIMSTRUCT_0B
	add hl, bc
	xor a
	ld [hl], a
	ld [hSCY], a
	ret

Slots_AnimateChansey: ; 932ac (24:72ac)
	ld hl, SPRITEANIMSTRUCT_0B
	add hl, bc
	ld e, [hl]
	ld d, 0
	ld hl, .Jumptable
rept 2
	add hl, de
endr
	ld a, [hli]
	ld h, [hl]
	ld l, a
	jp [hl]

.Jumptable: ; 932bc (24:72bc)
	jumptable_start
	jumptable .walk
	jumptable .one
	jumptable .two


.walk: ; 932c2 (24:72c2)
	ld hl, SPRITEANIMSTRUCT_XCOORD
	add hl, bc
	ld a, [hl]
	inc [hl]
	cp 13 * 8
	jr z, .limit
	and $f
	ret nz
	ld de, SFX_JUMP_OVER_LEDGE
	call PlaySFX
	ret

.limit
	ld hl, SPRITEANIMSTRUCT_0B
	add hl, bc
	inc [hl]
	ld a, $1
	ld [wcf64], a

.one: ; 932e0 (24:72e0)
	ld a, [wcf64]
	cp $2
	jr z, .retain
	cp $5
	ret nz
	ld hl, SPRITEANIMSTRUCT_INDEX
	add hl, bc
	ld [hl], $0
	ret

.retain
	ld hl, SPRITEANIMSTRUCT_0B
	add hl, bc
	inc [hl]
	ld hl, SPRITEANIMSTRUCT_0C
	add hl, bc
	ld [hl], $8
.two: ; 932fc (24:72fc)
	ld hl, SPRITEANIMSTRUCT_0C
	add hl, bc
	ld a, [hl]
	and a
	jr z, .spawn_egg
	dec [hl]
	ret

.spawn_egg
	ld hl, SPRITEANIMSTRUCT_0B
	add hl, bc
	dec [hl]
	push bc
	depixel 12, 13, 0, 4
	ld a, SPRITE_ANIM_INDEX_SLOTS_EGG
	call _InitSpriteAnimStruct
	pop bc
	ret

; 93316 (24:7316)

Slots_WaitSFX: ; 93316
	push bc
	ld c, 16
	call DelayFrames
	pop bc
	ret

; 9331e

Slots_PlaySFX: ; 9331e (24:731e)
	push de
	ld e, a
	ld d, 0
	call PlaySFX
	pop de
	ret

; 93327 (24:7327)

; The first three positions are repeated to
; avoid needing to check indices when copying.
Reel1Tilemap: ; 93327
	db SLOTS_SEVEN    ;  0
	db SLOTS_CHERRY   ;  1
	db SLOTS_STARYU   ;  2
	db SLOTS_PIKACHU  ;  3
	db SLOTS_SQUIRTLE ;  4
	db SLOTS_SEVEN    ;  5
	db SLOTS_CHERRY   ;  6
	db SLOTS_STARYU   ;  7
	db SLOTS_PIKACHU  ;  8
	db SLOTS_SQUIRTLE ;  9
	db SLOTS_POKEBALL ; 10
	db SLOTS_CHERRY   ; 11
	db SLOTS_STARYU   ; 12
	db SLOTS_PIKACHU  ; 13
	db SLOTS_SQUIRTLE ; 14
	db SLOTS_SEVEN    ;  0
	db SLOTS_CHERRY   ;  1
	db SLOTS_STARYU   ;  2

Reel2Tilemap: ; 93339
	db SLOTS_SEVEN    ;  0
	db SLOTS_PIKACHU  ;  1
	db SLOTS_CHERRY   ;  2
	db SLOTS_SQUIRTLE ;  3
	db SLOTS_STARYU   ;  4
	db SLOTS_POKEBALL ;  5
	db SLOTS_PIKACHU  ;  6
	db SLOTS_CHERRY   ;  7
	db SLOTS_SQUIRTLE ;  8
	db SLOTS_STARYU   ;  9
	db SLOTS_POKEBALL ; 10
	db SLOTS_PIKACHU  ; 11
	db SLOTS_CHERRY   ; 12
	db SLOTS_SQUIRTLE ; 13
	db SLOTS_STARYU   ; 14
	db SLOTS_SEVEN    ;  0
	db SLOTS_PIKACHU  ;  1
	db SLOTS_CHERRY   ;  2

Reel3Tilemap: ; 9334b
	db SLOTS_SEVEN    ;  0
	db SLOTS_PIKACHU  ;  1
	db SLOTS_CHERRY   ;  2
	db SLOTS_SQUIRTLE ;  3
	db SLOTS_STARYU   ;  4
	db SLOTS_PIKACHU  ;  5
	db SLOTS_CHERRY   ;  6
	db SLOTS_SQUIRTLE ;  7
	db SLOTS_STARYU   ;  8
	db SLOTS_PIKACHU  ;  9
	db SLOTS_POKEBALL ; 10
	db SLOTS_CHERRY   ; 11
	db SLOTS_SQUIRTLE ; 12
	db SLOTS_STARYU   ; 13
	db SLOTS_PIKACHU  ; 14
	db SLOTS_SEVEN    ;  0
	db SLOTS_PIKACHU  ;  1
	db SLOTS_CHERRY   ;  2
; 9335d

SlotsTilemap: ; 9335d
INCBIN "gfx/slots.tilemap"
; 9344d

Slots1LZ: ; 9344d
INCBIN "gfx/slots_1.2bpp.lz"
; 935cd

Slots2LZ: ; 935cd
INCBIN "gfx/slots_2.2bpp.lz"
; 9382d

Slots3LZ: ; 9382d
INCBIN "gfx/slots_3.2bpp.lz"
; 93a3d
