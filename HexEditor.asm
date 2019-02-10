*= $4000
start:
    ;JSR init_lcd

	LDA #$FF
	STA old_PA
	STZ base_display_hex_ptr
	STZ base_display_hex_ptr+1
	
	LDA #$1
	STA cursor_x
	LDA #60
	STA cursor_y
	LDA #$00
	STA cursor_position

mainloop:
	STZ $34 ;DRRL
	LDA #$80
	STA $35 ;DRRH            ; DRR = 0x8000
	
	JSR FillScreen
	
	JSR DrawHexView
	
	JSR DrawSeparator
	
	JSR DrawAddressSelection
	
	JSR DrawWriteByte
	
	JSR DrawCursor
	
	JSR Update

	JSR HandleControls
	
	JMP mainloop

white: !word $FFFF
	
	
bytes_to_increment:
	!word base_display_hex_ptr+1 ;position 0 or 1
	!word base_display_hex_ptr ;position 2 or 3
	!word write_byte ;position 4 or 5
	
GetInterfaceBytePtr:
	LDA #<bytes_to_increment
	STA pointer
	LDA #>bytes_to_increment
	STA pointer+1
	
	LDA cursor_position
	AND #$FE
	
	CLC
	ADC pointer
	STA pointer
	LDA #$00
	ADC pointer+1
	STA pointer+1 ;pointer points to part of pointer array
	
	LDA (pointer) ;get low pointer
	TAX
	
	CLC
	LDA #$01
	ADC pointer
	STA pointer
	LDA #$00
	ADC pointer+1
	STA pointer+1
	
	LDA (pointer) ;get high pointer
	
	STA pointer+1
	TXA
	STA pointer
	RTS

HandleControls:
	PHA
	PHX
	PHY
	
	LDA $00 ;PA
	AND #$01 ;UP
	BNE handle_up_end ;only continue if pressed
	LDA old_PA
	EOR $00 ;PA
	AND #$01 ;UP
	BEQ handle_up_end ;only continue if not previously pressed
    
	;handle UP
		JSR GetInterfaceBytePtr
		LDA cursor_position
		AND #$01
		BNE control_inc_byte
		
		CLC
		LDA #$10
		ADC (pointer)
		STA (pointer)
		JMP handle_up_end
		
		control_inc_byte:
		CLC
		LDA #$01
		ADC (pointer)
		STA (pointer)
		
		handle_up_end:
		
	LDA $00 ;PA
	AND #$02 ;DOWN
	BNE handle_down_end ;only continue if pressed
	LDA old_PA
	EOR $00 ;PA
	AND #$02 ;DOWN
	BEQ handle_down_end ;only continue if not previously pressed

	;handle DOWN
		JSR GetInterfaceBytePtr
		LDA cursor_position
		AND #$01
		BNE control_dec_byte
		
		SEC
		LDA (pointer)
		TAX
		LDA #$10
		STA (pointer)
		TXA
		SBC (pointer)
		STA (pointer)
		JMP handle_down_end
		
		control_dec_byte:
		SEC
		LDA (pointer)
		TAX
		LDA #$01
		STA (pointer)
		TXA
		SBC (pointer)
		STA (pointer)
		JMP handle_down_end
		
		handle_down_end:
		
	LDA $00 ;PA
	AND #$04 ;LEFT
	BNE handle_left_end ;only continue if pressed
	LDA old_PA
	EOR $00 ;PA
	AND #$04 ;LEFT
	BEQ handle_left_end ;only continue if not previously pressed

	;handle LEFT
		LDA cursor_position
		DEC
		CMP #$FF
		BNE okleft
		LDA #$00
		okleft:
		STA cursor_position
		handle_left_end:
		
	LDA $00 ;PA
	AND #$08 ;RIGHT
	BNE handle_right_end ;only continue if pressed
	LDA old_PA
	EOR $00 ;PA
	AND #$08 ;RIGHT
	BEQ handle_right_end ;only continue if not previously pressed

	;handle RIGHT
		LDA cursor_position
		INC
		CMP #6 ;max cursor pos
		BNE okright
		LDA #5
		okright:
		STA cursor_position
		handle_right_end:
		
	LDA $01 ;PB
	AND #$10 ;ACTION
	BNE handle_action_end ;only continue if pressed
	LDA old_PA
	EOR $01 ;PB
	AND #$10 ;ACTION
	BEQ handle_action_end ;only continue if not previously pressed

	;handle ACTION
		LDA base_display_hex_ptr
		STA pointer
		LDA base_display_hex_ptr+1
		STA pointer+1
		LDA write_byte
		STA (pointer)
		handle_action_end:
		

	
	
	
	handle_controls_end:
	LDA $00 ;PA
	STA old_PA
	PLY
	PLX
	PLA
	
DrawWriteByte:
	PHA
	PHX
	PHY
	
	LDA write_byte
	LDY #53 ;Y of write byte
	LDX #90 ;X of write byte
	JSR DrawByte
	
	PLY
	PLX
	PLA
	RTS
	
DrawSeparator:
	PHA
	PHX
	PHY
	
	LDA #$48
	STA pointer
	LDA #$E6 ;pointer to 50th line of screen buffer
	STA pointer+1
	
	LDX #196 ;2 lines
	DrawSeparator_loop:
		LDA #$F8
		STA (pointer)
		CLC
		LDA #$1
		ADC pointer
		STA pointer
		LDA #$0
		ADC pointer+1
		STA pointer+1
		
		LDA #$F2
		STA (pointer)
		CLC
		LDA #$1
		ADC pointer
		STA pointer
		LDA #$0
		ADC pointer+1
		STA pointer+1
		
		DEX
		BNE DrawSeparator_loop
	
	PLY
	PLX
	PLA
	RTS
	
DrawAddressSelection:
	PHA
	PHX
	PHY
	
	
	LDA base_display_hex_ptr+1 ;Draw address
	LDX #$1 ;x of first byte
	LDY #53 ;y of first byte
	JSR DrawByte
	LDA base_display_hex_ptr
	LDX #$9 ;x of second byte
	LDY #53 ;y of second byte
	JSR DrawByte
	
	PLY
	PLX
	PLA
	RTS
	
DrawCursor:
	PHA
	PHX
	PHY
	
	LDY cursor_position
	LDA #<cursor_x_positions
	STA pointer
	LDA #>cursor_x_positions
	STA pointer+1
	LDA (pointer),Y
	STA cursor_x
	
	LDA #$10 ;cursor sprite
	LDX cursor_x
	LDY cursor_y
	JSR DisplayDigit
	
	PLY
	PLX
	PLA
	RTS
	
cursor_x_positions:
	!byte 1 ;address HH
	!byte 5 ;address H
	!byte 9 ;address L
	!byte 13;address LL
	!byte 90;write_byte H
	!byte 94;write_byte L
	
DrawHexView:
	PHA
	PHX
	PHY
	LDA base_display_hex_ptr
	STA display_hex_ptr
	LDA base_display_hex_ptr+1
	STA display_hex_ptr+1
	
	
	LDA #$1
	STA hex_view_y
	
	LDX #7 ;number of rows to draw
	hex_row_loop:
		PHX
		LDA #$1
		STA hex_view_x
		LDA display_hex_ptr+1 ;Draw address
		LDX hex_view_x
		LDY hex_view_y
		JSR DrawByte
		CLC ;add to x offset
		LDA hex_view_x
		ADC #8
		STA hex_view_x
		LDA display_hex_ptr
		LDX hex_view_x
		LDY hex_view_y
		JSR DrawByte
		CLC ;add to x offset
		LDA hex_view_x
		ADC #11
		STA hex_view_x
		
		
		LDX #8 ;number of cols to draw
		hex_col_loop:
			PHX
			LDA display_hex_ptr
			STA pointer
			LDA display_hex_ptr+1
			STA pointer+1
			LDA (pointer)
			LDX hex_view_x
			LDY hex_view_y
			JSR DrawByte
			
			CLC ;increment hex ptr
			LDA display_hex_ptr
			ADC #$1
			STA display_hex_ptr
			LDA display_hex_ptr+1
			ADC #$0
			STA display_hex_ptr+1
			
			CLC ;add to x offset
			LDA hex_view_x
			ADC #10
			STA hex_view_x
			PLX
			DEX
			BNE hex_col_loop
		
		CLC
		LDA hex_view_y
		ADC #$7
		STA hex_view_y
		PLX
		DEX
		BNE hex_row_loop
	PLY
	PLX
	PLA
	RTS
	
DrawByte:
	;X = x coord
	;Y = y coord
	;A = byte
	PHA
	LSR
	LSR
	LSR
	LSR

	JSR DisplayDigit
	
	INX
	INX
	INX
	INX
	
	PLA
	AND #$0F
	
	
	JSR DisplayDigit
	RTS
	
DisplayDigit:
	;X = x coord
	;Y = y coord
	;A = digit
	PHX
	PHY
	PHA
	
	LDA #<digit_ptrs
	STA temp
	LDA #>digit_ptrs
	STA temp+1
	
	CLC
	
	PLA
	ROL
	TAY
	PHA
	
	LDA temp
	STA pointer
	LDA temp+1
	STA pointer+1
	LDA (pointer),Y
	STA digit_ptr
	INY
	LDA (pointer),Y
	STA digit_ptr+1
	
	PLA
	PLY
	PLX
	
	PHA
	PHY
	PHX
	
	LDA #$C0 ;ptr = 0xC000
	STA ptr+1
	LDA #$00
	STA ptr
	
	;position = Y*97 + X
	STX temp
	
	CLC
	LDA ptr
	ADC temp ;X
	STA ptr
	LDA ptr+1
	ADC #$00
	STA ptr+1
	
	CLC ;each pixel is 2 bytes
	LDA ptr
	ADC temp ;X
	STA ptr
	LDA ptr+1
	ADC #$00
	STA ptr+1
	
	ymulloop:
		TYA ;A = remaining y
		BNE doymul
		BRA endymul
		doymul:
		CLC
		LDA ptr
		ADC #196 ;add 98*2 for every yloop
		STA ptr
		LDA ptr+1
		ADC #$00
		STA ptr+1
		DEY
		BRA ymulloop
		endymul:

	
	LDY #6
	yloop:
		LDX #3
		xloop:
			LDA digit_ptr
			STA pointer
			LDA digit_ptr+1
			STA pointer+1
			LDA (pointer) ;check if pixel is 0
			BNE notzero
			
			CLC
			LDA digit_ptr ;increment digit ptr by 2
			ADC #$02
			STA digit_ptr
			LDA digit_ptr+1
			ADC #$00
			STA digit_ptr+1
			
			CLC
			LDA ptr ;increment screen ptr by 2
			ADC #$02
			STA ptr
			LDA ptr+1
			ADC #$00
			STA ptr+1
			JMP endxloop
			
			
			notzero:
			LDA digit_ptr
			STA pointer
			LDA digit_ptr+1
			STA pointer+1
			LDA (pointer) ;store pixel in ptr
			PHA
			LDA ptr
			STA pointer
			LDA ptr+1
			STA pointer+1
			PLA
			STA (pointer)
			
			CLC
			LDA digit_ptr ;increment digit ptr
			ADC #$01
			STA digit_ptr
			LDA digit_ptr+1
			ADC #$00
			STA digit_ptr+1
			
			CLC
			LDA ptr ;increment screen ptr
			ADC #$01
			STA ptr
			LDA ptr+1
			ADC #$00
			STA ptr+1
			
			LDA digit_ptr
			STA pointer
			LDA digit_ptr+1
			STA pointer+1
			LDA (pointer) ;store pixel in ptr
			PHA
			LDA ptr
			STA pointer
			LDA ptr+1
			STA pointer+1
			PLA
			STA (pointer)
			
			CLC
			LDA digit_ptr ;increment digit ptr
			ADC #$01
			STA digit_ptr
			LDA digit_ptr+1
			ADC #$00
			STA digit_ptr+1
			
			CLC
			LDA ptr ;increment screen ptr
			ADC #$01
			STA ptr
			LDA ptr+1
			ADC #$00
			STA ptr+1
			
			JMP endxloop
			
			gotoxloop:
			JMP xloop
			endxloop:

			DEX
			BNE gotoxloop
			
		;1 row is done
		LDA ptr
		ADC #190 ;add (98-3)*2 to screen pointer
		STA ptr
		LDA ptr+1
		ADC #$00
		STA ptr+1
		DEY
		BRA endyloop
		restartyloop:
		JMP yloop
		
		endyloop:
		BNE restartyloop
	;y is done
	PLX
	PLY
	PLA
	RTS

digit_ptrs:
!word zero
!word one
!word two
!word three
!word four
!word five
!word six
!word seven
!word eight
!word nine
!word letter_A
!word letter_B
!word letter_C
!word letter_D
!word letter_E
!word letter_F
!word cursor_sprite
	
zero:
!word $FFFF, $FFFF, $FFFF

!word $FFFF, $0000, $FFFF

!word $FFFF, $0000, $FFFF

!word $FFFF, $0000, $FFFF

!word $FFFF, $0000, $FFFF

!word $FFFF, $FFFF, $FFFF
	
one:
!word $0000, $FFFF, $0000

!word $FFFF, $FFFF, $0000

!word $0000, $FFFF, $0000

!word $0000, $FFFF, $0000

!word $0000, $FFFF, $0000

!word $FFFF, $FFFF, $FFFF

two:
!word $0000, $FFFF, $0000

!word $FFFF, $0000, $FFFF

!word $0000, $0000, $FFFF

!word $0000, $FFFF, $FFFF

!word $FFFF, $0000, $0000

!word $FFFF, $FFFF, $FFFF

three:
!word $FFFF, $FFFF, $0000

!word $0000, $0000, $FFFF

!word $0000, $FFFF, $0000

!word $0000, $0000, $FFFF

!word $0000, $0000, $FFFF

!word $FFFF, $FFFF, $0000

four:
!word $0000, $0000, $FFFF

!word $0000, $FFFF, $FFFF

!word $FFFF, $0000, $FFFF

!word $FFFF, $FFFF, $FFFF

!word $0000, $0000, $FFFF

!word $0000, $0000, $FFFF

five:
!word $FFFF, $FFFF, $FFFF

!word $FFFF, $0000, $0000

!word $FFFF, $FFFF, $0000

!word $0000, $0000, $FFFF

!word $0000, $0000, $FFFF

!word $FFFF, $FFFF, $0000

six:
!word $0000, $FFFF, $FFFF

!word $FFFF, $0000, $0000

!word $FFFF, $FFFF, $0000

!word $FFFF, $0000, $FFFF

!word $FFFF, $0000, $FFFF

!word $0000, $FFFF, $0000

seven:
!word $FFFF, $FFFF, $FFFF

!word $0000, $0000, $FFFF

!word $0000, $0000, $FFFF

!word $0000, $0000, $FFFF

!word $0000, $0000, $FFFF

!word $0000, $0000, $FFFF

eight:
!word $0000, $FFFF, $0000

!word $FFFF, $0000, $FFFF

!word $0000, $FFFF, $0000

!word $FFFF, $0000, $FFFF

!word $FFFF, $0000, $FFFF

!word $0000, $FFFF, $0000

nine:
!word $0000, $FFFF, $0000

!word $FFFF, $0000, $FFFF

!word $FFFF, $0000, $FFFF

!word $0000, $FFFF, $FFFF

!word $0000, $0000, $FFFF

!word $0000, $0000, $FFFF

letter_A:
!word $0000, $FFFF, $0000

!word $FFFF, $0000, $FFFF

!word $FFFF, $0000, $FFFF

!word $FFFF, $FFFF, $FFFF

!word $FFFF, $0000, $FFFF

!word $FFFF, $0000, $FFFF

letter_B:
!word $FFFF, $FFFF, $0000

!word $FFFF, $0000, $FFFF

!word $FFFF, $FFFF, $0000

!word $FFFF, $0000, $FFFF

!word $FFFF, $0000, $FFFF

!word $FFFF, $FFFF, $0000

letter_C:
!word $0000, $FFFF, $0000

!word $FFFF, $0000, $FFFF

!word $FFFF, $0000, $0000

!word $FFFF, $0000, $0000

!word $FFFF, $0000, $FFFF

!word $0000, $FFFF, $0000

letter_D:
!word $FFFF, $FFFF, $0000

!word $FFFF, $0000, $FFFF

!word $FFFF, $0000, $FFFF

!word $FFFF, $0000, $FFFF

!word $FFFF, $0000, $FFFF

!word $FFFF, $FFFF, $0000

letter_E:
!word $FFFF, $FFFF, $FFFF

!word $FFFF, $0000, $0000

!word $FFFF, $FFFF, $FFFF

!word $FFFF, $0000, $0000

!word $FFFF, $0000, $0000

!word $FFFF, $FFFF, $FFFF

letter_F:
!word $FFFF, $FFFF, $FFFF

!word $FFFF, $0000, $0000

!word $FFFF, $FFFF, $FFFF

!word $FFFF, $0000, $0000

!word $FFFF, $0000, $0000

!word $FFFF, $0000, $0000

cursor_sprite:
!word $0000, $FFFF, $0000

!word $FFFF, $FFFF, $FFFF

!word $0000, $FFFF, $0000

!word $0000, $FFFF, $0000

!word $0000, $FFFF, $0000

!word $0000, $FFFF, $0000

FillScreen:
LDA #$2
STA $5F

STZ $5E ;DSEL source

LDA #<white
STA $58 ;DPTR = white
LDA #>white+$8000
STA $59

LDA #$00
STA $5A ;DBKR = 0x100
LDA #$1
STA $5B

LDA #$1
STA $5E ;DSEL dest

LDA #$00
STA $58 ;DPTR = 0xC000
LDA #$C0
STA $59

LDA #$00
STA $5A ;DBKR = 0x8000
LDA #$80
STA $5B

LDA #$FF
STA $5C ;DCNT = 0x4000
LDA #$3F
STA $5D

RTS  
	
Update:
LDA     #0
STA     $5E
LDA     #0
STA     $58
LDA     #$C0
STA     $59
LDA     #0
STA     $5A
LDA     #$80
STA     $5B
LDA     #$C0
STA     $34 ;DRRL
!byte $64 ;STZ
!byte $35 ;DRRH            ; DRR = 0x00C0
LDX     #$75 ; 'u'
STX     $8000
LDX     #0
STX     $8001
LDX     #$42 ; 'B'
STX     $8001
LDX     #$15
STX     $8000
LDX     #0
STX     $8001
LDX     #$61 ; 'a'
STX     $8001
LDA     #$30 ; '0'
STA     $8000
LDA     #$5C ; '\'      ; Memory write (RAMWR)
STA     $8000
LDA     #1
STA     $5E
LDA     #1
STA     $58
LDA     #$80
STA     $59
LDA     #$C0
STA     $5A

STZ $5B

LDA     #8
STA     $5F ;dmod
LDA     #$4B
STA     $5C ;dcntl
LDA     #$33
STA     $5D ;dcnth

STZ     $34 ;DRRL
LDA     #$80
STA     $35;DRRH            ; DRR = 0x8000
RTS  

	
	
	
    
TestRight:
    LDA #$8 ;0000 1000
    BIT $0
    BEQ RightClear ;clear
    CLC ;Carry Clear for False
    RTS
RightClear:
    SEC ;Carry Set for True
    RTS
    
TestLeft:
    LDA #$4 ;0000 0100
    BIT $0
    BEQ LeftClear ;clear
    CLC ;Carry Clear for False
    RTS
LeftClear:
    SEC ;Carry Set for True
    RTS
    
TestDown:
    LDA #$2 ;0000 0010
    BIT $0
    BEQ DownClear ;clear
    CLC ;Carry Clear for False
    RTS
DownClear:
    SEC ;Carry Set for True
    RTS
    
TestUp:
    LDA #$1 ;0000 0001
    BIT $0
    BEQ UpClear ;clear
    CLC ;Carry Clear for False
    RTS
UpClear:
    SEC ;Carry Set for True
    RTS
    
TestMenu:
    LDA #32 ;0010 0000
    BIT $0
    BEQ UpClear ;clear
    CLC ;Carry Clear for False
    RTS
MenuClear:
    SEC ;Carry Set for True
    RTS
 
init_lcd:
    LDA #$C0
	STA $34 ;DRRL
	STZ $35
	LDX #$75            ; Page address set (PASET)
	STX $8000
	LDX #0              ; From Page address 0
	STX $8001           ; PASET 0-66
	LDX #$42           ; To page address 66
	STX $8001
	LDX #$15            ; Column Address Set (CASET)
	STX $8000
	LDX #0              ; from column address 0
	STX $8001           ; CASET 0-97
	LDX #$61            ; To column address 97
	STX $8001
	LDA #$30            ; Ext = 0
	STA $8000
	LDA #$5C            ; Memory write (RAMWR)
	STA $8000
	
	PHA
	LDA ptr
	STA pointer
	LDA ptr+1
	STA pointer+1
	PLA
	STA (pointer)
heightloop:
	LDA #$00
	STA ptr+1
widthloop:
	LDA #$FF
	STA $8001
	LDA #$FF
	STA $8001
	INC ptr+1
	LDA ptr+1
	CMP #$62            ; width max
	BCC widthloop
	
	INC ptr
	LDA ptr
	CMP #$44            ; height max
	BCC heightloop
	
	STZ $34            ; DRR = 0x8000
	LDA #$80
	STA $35 ;DRRH
	RTS
   
    
!pseudopc $80 {
pointer: !word $0000


}
!pseudopc $1000 {
ptr: !word $0000
digit_ptr: !word $0000
base_display_hex_ptr: !word $0000
display_hex_ptr: !word $0000
temp: !word $0000

hex_view_x: !byte $00
hex_view_y: !byte $00
old_PA: !byte $00
screen_color: !word $0000
cursor_x: !byte $00
cursor_y: !byte $00
cursor_position: !byte $00
write_byte: !byte 00
}