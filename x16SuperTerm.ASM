;; Compiles Under xa65 
;; basic open 2,2,0, chr$(10)  SYS 2130
.word $0801, $0830, $000a,  $208f, $2a2a, $2a2a,   $4220,   $5445
.word $2041, $4554, $4d52,  $4e49, $4c41, $5020,   $4f52,   $5247
.word $4d41, $4f20, $4550,  $534e, $4120, $2054,   $3432,   $3030
.word $4300, $1408, $9f00,  $3220, $322c, $302c,   $202c,   $28c7
.word $3031, $0029, $084e,  $001e, $209e,  $3132,   $3033,   $0000
.word $0000 

*=$0851

; alpha x16superterm routines preliminary input output routines supplied by  
; Matthew Pearce - 
; 

; KERNAL function pointers
GETIN = $FFE4
CHKIN = $FFC6
CHKOUT = $FFC9
SETLFS = $FFBA
OPEN = $FFC0
SETNAM = $FFBD
CHROUT = $FFD2
CLRCHN = $FFCC
ROMBNK = $9F60
	
; rs232 buffer pointers
RS232_INBUF_PTR = $f7
RS232_OUTBUF_PTR = $f9

CHAR_CLS = 147                          ; clear screen control character

    ; set rs232 output buffer pointer to our .output_buffer
	;; ldx #<output_buffer
	;; sta RS232_OUTBUF_PTR
	;; ldx #>output_buffer
	;; sta RS232_OUTBUF_PTR+1
    
    ; set rs232 input buffer pointer to our .input_buffer
	;; ldx #<input_buffer
	;; sta RS232_INBUF_PTR
	;; ldx #>input_buffer
	;; sta RS232_INBUF_PTR+1
	;; Switch In Kernal ROM
        nop
	lda #$00
	sta ROMBNK
	;; End Kernal Bank Switch
    ; setup a logical file descriptor, pointing to device 2 (user port)
    ; this is equivalent to the OPEN
	;; lda #3			;logical file #
	;; ldx #2                      ; 2 = rs-232 device
	;; ldy #0                      ; no extra command
	;; jsr SETLFS

    ; setup the file name pointer for the file descriptor above
	;; lda #0                      ; null file name (this is not a file on disk)
	;; jsr SETNAM

    ; setup the rs232 connection configuration
	;; lda #%00000110              ; select 300 baud, 8 bits per character
	;; sta $0293                   ; store in rs232 control register

    ; open the logical file
	;; jsr OPEN

    jsr screen_init
    jmp main_loop

screen_init
    lda #CHAR_CLS
    jsr CHROUT                  ; print 'Clear Screen' control character to screen
    lda #0
    sta $cc                     ; enable blinking cursor
    rts
    
main_loop
    jsr rs232_try_read_byte
    cmp #0
    beq do_keyboard_read        ; if char is null, check keyboard input...
    jsr CHROUT                  ; ... otherwise, output to screen
    
do_keyboard_read
    jsr GETIN
    cmp #0
	beq main_loop          		; if char is null, go back to main loop...
	;; jsr CHROUT ; commented out tcpser provides echo until connect
    jsr rs232_write_byte        ; ... otherwise, output to rs232 channel

    jmp main_loop

; ----------------------------------------------------------------------
; Reads a single byte from open file #3
; Returns: A
; If no data available, will return immediately with \0
; ----------------------------------------------------------------------
rs232_try_read_byte
    ldx #2
    jsr CHKIN       ; select file 3 as IO input stream
    jsr GETIN       ; read byte from IO input stream
    tay             ; CLRCHN uses A, so copy A -> Y
    jsr CLRCHN      ; reset IO back to default keyboard/screen
    tya             ; copy Y -> A
    rts

; ----------------------------------------------------------------------
; Writes a single byte to open file #3
; Inputs A (byte to write)
; ----------------------------------------------------------------------
rs232_write_byte
    ldx #2
    tay             ; CHKOUT uses A, so copy A -> Y
    jsr CHKOUT      ; select file 3 as IO output stream
    tya             ; copy Y -> A
    jsr CHROUT      ; write byte to IO output
    jsr CLRCHN      ; reset IO back to default keyboard/screen
    rts

; ----------------------------------------------------------------------
; Prints a null-terminated string to the screen
; Inputs $fb, $fc: pointer to string
; ----------------------------------------------------------------------


