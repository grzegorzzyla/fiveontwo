//------------------------------------------------------------------------
//	Five effects with 2 sprites by SuN 2020 grzegorzsun@gmail.com
//------------------------------------------------------------------------

;Option                          Decimal   Bit
;  Enable missle DMA                     4   2
;  Enable player DMA                     8   3
;  Enable player and missile DMA        12   2,3
;  One line player resolution           16   4
;  default two line resolution
SDMCTL  equ $022f; $D400

; Priority options in order                Decimal Bit
;  Player 0-3, plfld 0-3, bckg                 1    0
;  Player 0-1, plfld 0-3, player 2-3, bckg     2    1
;  Plfld 0-3, player 0-3, bckg                 4    2
;  Plfld 0-1, player 0-3, plfld 2-3, bckg      8    3
;  Four missiles = fifth player               16    4
;  Overlaps of players have 3rd color         32    5
GPRIOR   equ $026f ; $D018

CONSOL equ $d01f;
; Size of player 0 (0 = normal, 1 = double, 3 = quadruple) 
SPLAYER0 equ $D008 ; size player0
SPLAYER1 equ $D009 ; size player1
SPLAYER2 equ $D00a ; size player2
SPLAYER3 equ $D00b ; size player3

; Graphics shape for player 0 written directly to the player graphics register. 
; In using these registers, you bypass ANTIC. 
; You only use the GRAFP# registers when you are not using Direct Memory Access 
; (DMA: see GRACTL at 53277). If DMA is enabled, then the graphics registers 
; will be loaded automatically from the area specified by PMBASE (54279; $D407). 
GPLAYER0 equ $D00D ; rejestr grafiki gracza 0    
GPLAYER1 equ $D00E ; rejestr grafiki gracza 0    
GPLAYER2 equ $D00F ; rejestr grafiki gracza 0    
GPLAYER3 equ $D010 ; rejestr grafiki gracza 0    

; Graphics for all missiles, not used with DMA. 
; GRAFM works the same as GRAFP0 above. 
; Each pair of bits represents one missile, 
; with the same allocation as in 53260 ($D00C) above.
;         Bit  7 6  5 4  3 2  1 0
;     Missile  -3-  -2-  -1-  -0-
  
GRAFM    equ $D011 ;  	
PPLAYER0 equ $D000 ; pozycja gracza 0
PPLAYER1 equ $D001 ; pozycja gracza 1
PPLAYER2 equ $D002 ; pozycja gracza 2
PPLAYER3 equ $D003 ; pozycja gracza 3

; Horizontal position of missile 0. 
; Missiles move horizontally like players. 
; See the note in 53248 ($D000) concerning the use of horizontal registers. 
; Also player 0 to playfield collision status. 
HPOSM0   equ $D004 ;
HPOSM1   equ $D005 ;
HPOSM2   equ $D006 ;
HPOSM3   equ $D007 ;


CPLAYER0 equ $D012 ; kolor gracza 0
CPLAYER1 equ $D013 ; kolor gracza 1
CPLAYER2 equ $D014 ; kolor gracza 2
CPLAYER3 equ $D015 ; kolor gracza 3

Colpf0   equ $D016;
Colpf1   equ $D017;
Colpf2   equ $D018;
Colpf3   equ $D019; 
COLBAK   equ $D01A; colbak

* ---------------------------------------------------------------------------------------------
* ---	POKEY
* ---------------------------------------------------------------------------------------------

irqens	=	$0010	; rejestr-cie? IRQEN
irqstat	=	$0011	; rejestr-cie? IRQST

audf1	=	$d200	; cz?stotliwo?? pracy generatora 1 (Z)
audc1	=	$d201	; rejestr kontroli d?wi?ku generatora 1 (Z)
audf2	=	$d202	; cz?stotliwo?? pracy generatora 2 (Z)
audc2	=	$d203	; rejestr kontroli d?wi?ku generatora 2 (Z)
audf3	=	$d204	; cz?stotliwo?? pracy generatora 3 (Z)
audc3	=	$d205	; rejestr kontroli d?wi?ku generatora 3 (Z)
audf4	=	$d206	; cz?stotliwo?? pracy generatora 4 (Z)
audc4	=	$d207	; rejestr kontroli d?wi?ku generatora 4 (Z)

audctl	=	$D208	; rejestr kontroli generator?w d?wi?ku (Z)
stimer	=	$D209	; rejestr zerowania licznik?w (Z)
kbcode	=	$D209	; kod ostatnio naci?ni?tego klawisza (O)
skstres	=	$D20A	; rejestr statusu z??cza szeregowego (Z)
serout	=	$D20D	; szeregowy rejestr wyj?ciowy (Z)
serin	=	$D20D	; szeregowy rejestr wej?ciowy (O)
irqen	=	$D20E	; zezwolenie przerwa? IRQ (Z)
irqst	=	$D20E	; status przerwa? IRQ (O)
skctl	=	$D20F	; rejestr kontroli z??cza szeregowego (Z)
skstat	=	$D20F	; rejestr statusu z??cza szeregowego (O)

sinwav equ $0800

VVBLKD  equ $0224
XITVBV  equ $e462
WSYNC   equ $D40A
VCOUNT  equ $D40B
RANDOM  equ $D20A

RTCLOCK  equ $0012;
charset equ $E000+128+64; -$E3FF

tab equ $0600
tad equ tab+256

charpos equ $80;
; zero page, pierwsza wolna komorka
sinus   equ $82; 2 byte
   org	$84
go equ *
; dma - screen off
    lda #24; one line + dma for players
	sta SDMCTL;    lda #16; one line

// initialization star tab
    ldy #255
// init PMG    
    sty GPLAYER0; rejestr grafiki gracza 0    

in  lda RANDOM
    sta tab,y
    lda RANDOM
    and #3
    adc #1
	sta tad,y
	dey
	bne in
 
; generate fake sine wave array using parabolas
	ldy #$3f
	ldx #$00

make_sine
value_lo equ *+1
    lda #0
delta   equ *+1
	adc #0
	sta value_lo
value_hi equ *+1
	lda #0
	adc #0

	sta value_hi
    sta sinwav+$40,y
	sta sinwav+$80,x
	eor #$3f
    sta sinwav+$00,x
    sta sinwav+$c0,y
 
	lda delta
	adc #4
	sta delta

	inx
	dey
    bpl make_sine
; end sine

//------------------------------------------------------------------------
//	Main parts
//------------------------------------------------------------------------
// init PMG    
;    ldy #$ff; #$ff
;    sty GPLAYER0; rejestr grafiki gracza 0    
// Part 1 - bars on 1 Player done by sizep0
p3_loop equ *	
    lda VCOUNT;
	sta WSYNC;
	adc rtclock+2;
	sta CPLAYER0; 2;
    sta SPLAYER0; 2;

;    lda rtclock+2
	bne p3_loop

// reinit PMG
SWITCH equ *+1; reuse for switchich in next part
    ldy #1;
    sty GPLAYER0; rejestr grafiki gracza 0    
    sty GRAFM;

	sty	SPLAYER0; $d008; size player0
	sty SPLAYER1; size player1

	inc SWITCH

; bez tego jest 0 i od razu wychodzi z efektu!
    inc rtclock+2;


// part 2&3
p1_loop equ *
; sync with scanline start
    lda VCOUNT; vcount
    bne p1_loop
	
    ldy #247
p1_rp  equ *
	lda tab,y
    sta WSYNC;
player_or_missile equ *+1
; przelacza z hposm0 na hposp0
    sta HPOSM0; pozycja pocisku 0
; rejestr koloru ten sam dla pocisku i gracza
    sta CPLAYER0; kolor player0/missile0 - nie mrygaj
; gwiazdy do boju
    adc tad,y
    sta tab,y
    
    sta CONSOL;
    
; Size of player 0 (0 = normal, 1 = double, 3 = quadruple, other=widescreen :) ) 
	sty SPLAYER0;
    dey
    bne	p1_rp
    lda rtclock+2
    bne dont_change
; switch player or missile
    sty player_or_missile; mlodszy bajt - pozycja ducha/pocisku
    sty HPOSM0;
    dec SWITCH
	beq endloop
dont_change equ *
    jmp	p1_loop

endloop equ *

// part 4&5
loop equ *
    lda vcount; vcount
    bne loop
	
// full screen 255 lines
    ldy #255
    mva #$0 charpos
rp  equ *
    sta wsync; wsync
    adc rtclock+2; more color :)
	sta CPLAYER0; Player0 color
	sty CPLAYER1; Player1 color
    sta CONSOL;

// simple charscreen
    lda charpos
    adc sinwav,x
    tax
	lda charset,x
;	eor #$ff; negative char bits
    sta GPLAYER0; Player0 graphics reg
	sta GPLAYER1; Player1 graphics reg

// decrementing random value to sine pos
	lda random
krzaki equ *+1
	and #$ff
	adc sinwav,y

// odsun od lewej
    tax
posleft equ *+1
; 	adc #88; join	
    adc #40;
    sta PPLAYER0; Player0 hpos
	tax
// odsun od prawej
posright equ *+1
    adc #15 
	eor #$ff
	sta PPLAYER1; Player1 hpos

;    sta CONSOL;
    
    inc charpos; next line from chargen
    dey
	bne	rp

// rol sinetab

    lda sinwav+$fe    
	tax
    ldy #$fe
lp  lda sinwav-1,y
    sta sinwav,y 	
    dey
	bne lp
	txa
;	iny
	sta sinwav; ,y

//krzaki
    lda krzaki
	beq goloop
    dec krzaki
goloop equ *
    jmp	loop

;	run	go
