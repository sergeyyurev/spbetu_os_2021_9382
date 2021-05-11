TESTPC SEGMENT
		ASSUME 	CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
		ORG 	100H
START: 	JMP 	BEGIN
; Данные
AvailableMem	db	'Available memory:        b',0DH,0AH,'$'	
ExtMem			db	'Extended memory:        kb',0DH,0AH,'$'
MCB				db	'MCB:      $'
Owner			db	'Owner: $'
AreaSize		db	'Size:       $'
LastBytes		db	0DH,0AH,'last 8 bytes: $'
FREE			db  ' free               $'
XMS 			db  ' OS XMS UMB         $'
TM		 		db  ' driver memory      $'
DOS 			db  ' MS DOS             $'
Busy		 	db  ' busy by 386MAX UMB $'
Block			db  ' blocked by 386MAX  $'
OWN_386 		db  ' 386MAX UMB         $'
Empty			db 	'                    $'
EndL	 		db  0Dh, 0Ah, '$'
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
;--------------------------------------
WORD_TO_DEC PROC near 
		push cx
		push dx
		mov cx, 10
loop1:
		div cx
		or 	dl, 30h
		mov [si], dl
		dec si
		xor dx, dx
		cmp ax, 0
		jnz loop1

		pop dx
		pop cx
		ret
WORD_TO_DEC ENDP

;-----------------------------------------------------
; Код
BEGIN:
;available mem
		mov ah, 4ah
		mov bx, 0ffffh
		int 21h
		
		mov ax, bx
		mov cx, 16
		mul cx
		mov	si, offset AvailableMem + 23
		call word_to_dec
		mov dx, offset AvailableMem
		call print
;-------------------------------
;extended mem
		xor ax, ax
		xor dx, dx

		mov AL, 30h ; запись адреса ячейки CMOS
		out 70h, AL
		in AL, 71h  ; чтение младшего байта
		mov BL, AL  ; расщиренной памяти
		mov AL, 31h ; запись адреса ячейки CMOS
		out 70h, AL
		in AL, 71h  ; чтение старшего байта
					; размера расширенной памяти
		mov bh, al
		mov ax, bx
		mov si, offset extmem+22
		call word_to_dec
		mov dx, offset extmem
		call print
;-------------------------------
;MCB
		xor	ax, ax
		mov ah, 52h
		int 21h
		mov ax, es:[bx-2]
		mov es, ax
		xor cx, cx
		inc	cx
next_mcb:
;mcb number......................
		mov	si, offset mcb+7
		mov	al, cl
		push cx
		call byte_to_dec
		mov	dx, offset mcb
		call print		
;owner...........................
		mov dx, offset owner
		call print
		xor	ah, ah
		mov	al, es:[0]
		push ax
		mov	ax, es:[1]
		
		cmp	ax, 0
		mov	dx, offset free
		je	printOwn
		cmp	ax, 6
		mov	dx, offset xms
		je	printOwn
		cmp	ax, 7
		mov	dx, offset tm
		je	printOwn
		cmp	ax, 8
		mov	dx, offset dos
		je	printOwn
		cmp	ax, 0fffah
		mov	dx, offset busy
		je	printOwn
		cmp	ax, 0fffdh
		mov	dx, offset block
		je	printOwn
		cmp	ax, 0fffeh
		mov	dx, offset own_386
		je	printOwn

		mov	di, offset empty+4
		call wrd_to_hex
		mov	dx, offset empty
printOwn:
		call print
;size............................
		mov	ax, es:[3]
		mov	cx, 16
		mul	cx
		mov	si, offset areasize+11
		call word_to_dec
		mov	dx, offset areasize
		call print
;data............................
		xor	dx, dx
		mov	dx, offset lastbytes
		call print
		mov cx, 8
		xor	di, di
symbol:
		mov	dl, es:[di+8]
		mov	ah, 02h
		int 21h
		inc di
		loop symbol
		mov dx, offset endl
		call print
;................................	
		mov ax,es:[3]	
		mov bx,es
		add bx,ax
		inc bx
		mov es,bx
		pop ax
		pop cx
		inc cx
		cmp al,5Ah ; проверка на не последний ли это сегмент
		je	exit
		cmp al,4Dh 
		jne exit
		jmp next_mcb

exit:	; Выход в DOS
		xor AL,AL
		mov AH,4Ch
		int 21H
TESTPC ENDS
		END START
