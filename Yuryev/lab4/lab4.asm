CODE 	SEGMENT
		ASSUME CS:CODE, DS:DATA, SS:AStack
; Процедуры
;-----------------------------------------------------
ROUT PROC FAR	
; обработчик прерываний
		jmp startrout
	routdata:
		counter		DB	'000 interruptions'
		signature	DW	2910h
		
		keep_ss		dw	?
		keep_sp		dw	?
		keep_ax		dw	?
		
		KEEP_IP 	DW 	0 
		KEEP_CS 	DW 	0 
		KEEP_PSP	DW	0
		
		rout_stack	dw	16	dup(?)
		end_stack	dw	?

startrout:
		mov	keep_ss, ss
		mov	keep_sp, sp
		mov	keep_ax, ax
		mov	ax, seg	rout_stack
		mov	ss, ax
		mov	sp, offset end_stack
		
		PUSH AX ; сохранение изменяемых регистров
		push bx
		push cx
		push dx
		push si
		push es
		push ds
		
		mov	ax, seg counter
		mov	ds, ax
		
		mov     AH, 03h
		mov     BH, 0h
		int     10h ; получение позиции курсора
; выход: DH,DL = текущие строка, колонка курсора
; CH,CL = текущая начальная, конечная строки курсора
		push dx
		
		mov	ah, 02h
		mov	bh, 0h
		mov	dx, 1820h
		int	10h		; установка курсора
		
		mov	ax, seg counter
		push ds
		mov	ds, ax
		mov	si, offset counter
		add	si, 2
		mov	cx, 3
cycle:
		mov	ah, [si]
		inc	ah
		mov	[si], ah
		cmp	ah, ':'
		jne	endc
		mov	ah, '0'
		mov	[si], ah
		dec	si
		loop cycle
endc:
		pop	ds
		
; print
		push es
		push bp
		mov	ax, seg counter
		mov	es, ax
		mov	bp, offset counter
		mov	ah, 13h
		mov	al, 1h
		mov	bl, 2h
		mov	bh, 0
		mov	cx, 17
		int 10h		;вывод
		
		pop	bp
		pop	es
		
		pop	dx		; восстановление курсора
		mov	ah, 02h
		mov	bh, 0h
		int	10h
		
		pop	ds
		pop es
		pop si
		pop	dx
		pop	cx
		pop	bx
		POP AX 		; восстановление регистров
		 
		mov	ax, keep_ax
		mov	ss, keep_ss
		mov	sp, keep_sp
		 
		MOV AL, 20H
		OUT 20H,AL
		IRET
ROUT ENDP
;-------------------------------
last_byte:
;-------------------------------
CHECK	proc
		push ax
		push bx
		push si
		
		MOV AH, 35H ; функция получения вектора
		MOV AL, 1CH ; номер вектора
		INT 21H
		mov	si, offset signature
		sub	si, offset rout
		mov	ax, es:[bx+si]
		cmp	ax, signature
		jne	endcheck
		mov	loaded, 1

endcheck:
		pop si
		pop	bx
		pop	ax
		ret
CHECK	endp
;-------------------------------
LOADP	proc
		push ax
		push bx
		push cx
		push dx
		push es
		push ds
		
		MOV AH, 35H ; функция получения вектора
		MOV AL, 1CH ; номер вектора
		INT 21H
		MOV KEEP_IP, BX ; запоминание смещения
		MOV KEEP_CS, ES ; и сегмента
		MOV DX, OFFSET ROUT ; смещение для процедуры в DX
		MOV AX, SEG ROUT 	; сегмент процедуры
		MOV DS, AX 			; помещаем в DS
		MOV AH, 25H 		; функция установки вектора
		MOV AL, 1CH 		; номер вектора
		INT 21H 			; меняем прерывание
		POP DS
		mov DX,offset LAST_BYTE ; размер в байтах от начала
		mov CL,4 				; перевод в параграфы
		shr DX,CL
		add	dx, 10fh
		inc DX 					; размер в параграфах
		mov AH,31h
		int 21h
				
		pop es
		pop	dx
		pop	cx
		pop	bx
		pop	ax
		ret
LOADP	endp
;-------------------------------
UNLOADP	proc
		cli
		push ax
		push bx
		push dx
		push ds
		push es
		push si
		
		MOV AH, 35H ; функция получения вектора
		MOV AL, 1CH ; номер вектора
		INT 21H
		mov	si, offset keep_ip
		sub	si, offset rout
		mov	dx, es:[bx+si]
		mov	ax, es:[bx+si+2]
		push ds
		mov	ds, ax
		MOV AH, 25H 		; функция установки вектора
		MOV AL, 1CH 		; номер вектора
		INT 21H 			; меняем прерывание
		POP DS
		mov	ax, es:[bx+si+4]
		mov	es, ax
		push es
		mov	ax, es:[2ch]
		mov	es, ax
		mov	ah, 49h
		int	21h
		pop	es
		mov	ah, 49h
		int	21h
		
		sti
		
		pop	si
		pop	es
		pop	ds
		pop	dx
		pop	bx
		pop	ax
		ret
UNLOADP	endp
;-------------------------------
CHECKUN	proc
		push ax
		push es
		
		mov	ax, keep_psp
		mov	es, ax
		cmp	byte ptr es:[82h], '/'
		jne	endun
		cmp	byte ptr es:[83h], 'u'
		jne	endun
		cmp	byte ptr es:[84h], 'n'
		jne	endun
		mov	un, 1

endun:		
		pop es
		pop	ax
		ret
CHECKUN	endp
;-------------------------------
PRINT	proc	near
		mov	ah, 09h
		int 21h
		ret
PRINT 	endp
;-----------------------------------------------------
; Код
MAIN	PROC
        push  DS       ;\  Сохранение адреса начала PSP в стеке
        sub   AX,AX    ; > для последующего восстановления по
        push  AX       ;/  команде ret, завершающей процедуру.
        mov   AX,DATA             ; Загрузка сегментного
        mov   DS,AX               ; регистра данных.
		mov	keep_psp, es
		
		call check
		call checkun
		cmp	un, 1
		je unload1
		
		mov	al, loaded
		cmp	al, 1
		jne	load1
		mov	dx, offset	loaded_inf
		call print
		jmp	exit
		
load1:
		mov	dx, offset	load_inf
		call print
		call loadp
		jmp	exit
unload1:	
		cmp	loaded, 1
		jne	notloaded1
		call UNLOADP
		mov	dx, offset unload_inf
		call print
		jmp	exit
notloaded1:	
		mov	dx, offset not_load_inf
		call print

exit:
; Выход в DOS
		xor AL,AL
		mov AH,4Ch
		int 21H
MAIN	ENDP
CODE 	ENDS

AStack  SEGMENT  STACK
        DW 128 DUP(0)    
AStack  ENDS

DATA 	SEGMENT
	load_inf		db	'Interruption loaded',0DH,0AH,'$'
	loaded_inf		db	'Interruption already loaded',0DH,0AH,'$'
	unload_inf		db	'Interruption has been unloaded',0DH,0AH,'$'
	not_load_inf	db	'Interruption not loaded',0DH,0AH,'$'

	loaded		db	0
	un			db	0
DATA	ENDS


		END MAIN
