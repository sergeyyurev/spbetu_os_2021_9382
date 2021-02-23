TESTPC SEGMENT
		ASSUME 	CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
		ORG 	100H
START: 	JMP 	BEGIN
; Данные
SegAddrMem	db	'Segment address of memory:     ',0DH,0AH,'$'	
SegAddrEnv	db	'Segment address of environment:     ',0DH,0AH,'$'	
Tail		db	'Command line tail: ',0DH,0AH,'$'	
NoTail		db	'No tail',0DH,0AH,'$'
TailInfo	db	' $'	
EnvContent	db	'Environment content:   ',0DH,0AH,'$'	
NewLine		db	0DH,0AH,'$'	
Path		db	'Loadable module path:',0DH,0AH,'$'	
; Процедуры
;-----------------------------------------------------
TETR_TO_HEX PROC near
		and AL,0Fh
		cmp AL,09
		jbe next
		add AL,07
next:
		add AL,30h
		ret
TETR_TO_HEX ENDP
;--------------------------------------
BYTE_TO_HEX PROC near
;байт в AL переводится в два символа шест. числа в AX
		push CX
		mov AH,AL
		call TETR_TO_HEX
		xchg AL,AH
		mov CL,4
		shr AL,CL
		call TETR_TO_HEX ;в AL старшая цифра
		pop CX 			;в AH младшая
		ret
BYTE_TO_HEX ENDP
;--------------------------------------
WRD_TO_HEX PROC near
;перевод в 16 с/с 16-ти разрядного числа
; в AX - число, DI - адрес последнего символа
		push BX
		mov BH,AH
		call BYTE_TO_HEX
		mov [DI],AH
		dec DI
		mov [DI],AL
		dec DI
		mov AL,BH
		call BYTE_TO_HEX
		mov [DI],AH
		dec DI
		mov [DI],AL
		pop BX
		ret
WRD_TO_HEX ENDP
;--------------------------------------
BYTE_TO_DEC PROC near
; перевод в 10с/с, SI - адрес поля младшей цифры
		push CX
		push DX
		xor AH,AH
		xor DX,DX
		mov CX,10	
loop_bd:
		div CX
		or DL,30h
		mov [SI],DL
		dec SI
		xor DX,DX
		cmp AX,10
		jae loop_bd
		cmp AL,00h
		je end_l
		or AL,30h
		mov [SI],AL
end_l:
		pop DX
		pop CX
		ret
BYTE_TO_DEC ENDP
;--------------------------------------
PRINT	proc	near
		mov	ah, 09h
		int 21h
		ret
PRINT 	endp
;-----------------------------------------------------
; Код
BEGIN:

;Сегментный адрес недоступной памяти
		mov	ax, ds:[02h]
		mov	di, offset SegAddrMem
		add	di, 29
		call wrd_to_hex
		mov dx, offset SegAddrMem
		call print 
		
;Сегментный адрес среды 
		mov	ax, ds:[2ch]
		mov	di, offset SegAddrEnv
		add	di, 34
		call wrd_to_hex
		mov	dx, offset SegAddrEnv
		call	print

;Хвост командной строки
		mov	dx, offset tail
		call print
		mov	cl, ds:[80h]
		mov ch, 0
		cmp	cl, 0
		je	empty
		mov	dx, offset tailinfo
		mov	di, offset tailinfo
		mov si, 0
tailLoop:
		mov	al, ds:[81h+si]
		mov [di], al
		inc	si
		inc	di
		loop tailloop
		jmp print1
		
empty:
		mov	dx, offset notail

print1:
		call print

;Содержимое области среды
		mov	dx, offset envcontent
		call print
		mov	es, ds:[2ch]
		xor	si, si
printStr:
		mov	al, es:[si]
		cmp	al, 0
		jne	printSymbol
		inc si
		mov	al, es:[si]
		mov	dx, offset newline
		call print
printSymbol:
		mov	dl, al
		mov	ah, 02h
		int	21h
		inc	si
		mov	ax, es:[si]
		cmp	ax, 0001
		jne	printStr
		
		
;Путь загружаемого модуля
		mov	dx, offset path
		call print
		add	si, 2
printSymb:
		mov al, es:[si]
		cmp al, 0
		je	exit
		mov	dl, al
		mov ah, 02h
		int	21h
		inc	si
		jmp	printsymb


exit:	; Выход в DOS
		xor AL,AL
		mov AH,4Ch
		int 21H
TESTPC ENDS
		END START