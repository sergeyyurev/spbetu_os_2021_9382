AStack  SEGMENT  STACK
        DW 100h DUP(?)    
AStack  ENDS

DATA 	SEGMENT
IBMPC		db	'IBM PC type:',0DH,0AH,'$'
typePC 		db  'PC',0DH,0AH,'$'
typePCXT 	db 	'PC/XT',0DH,0AH,'$'
typeAT 		db  'AT',0DH,0AH,'$'
typePS230 	db 	'PS2 модель 30',0DH,0AH,'$'
typePS250 	db 	'PS2 модель 50 или 60',0DH,0AH,'$'
typePS280 	db 	'PS2 модель 80',0DH,0AH,'$'
typePCjr	db 	'PСjr',0DH,0AH,'$'
typePCC 	db 	'PC Convertible',0DH,0AH,'$'
enothertype	db	'  ',0DH,0AH,'$'

ver		 	db 	'Version of MS-DOS:',0DH,0AH,'$'
ver0		db	'<2.0', 0DH,0AH,'$'
vern0		db	'00.00', 0DH,0AH,'$'
OEM 		db  'OEM serial number :   ',0DH,0AH,'$'
userNum 	db  'User serial number:         $'
DATA	ENDS

CODE 	SEGMENT
		ASSUME CS:CODE, DS:DATA, SS:AStack
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
;-------------------------------
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
;-------------------------------
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
;--------------------------------------------------
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
;-------------------------------
; Код
MAIN	PROC	FAR
        push  DS       ;\  Сохранение адреса начала PSP в стеке
        sub   AX,AX    ; > для последующего восстановления по
        push  AX       ;/  команде ret, завершающей процедуру.
        mov   AX,DATA             ; Загрузка сегментного
        mov   DS,AX               ; регистра данных.
		
;Определение типа PC
		mov	dx, offset IBMPC
		mov	ah, 09h
		int	21h
		
		mov AX,0F000H ;указывает ES на ПЗУ
		mov ES,AX ;
		mov AL,ES:[0FFFEH] ;получаем байт
				
		cmp al, 0ffh
		je 	t1
		cmp al, 0feh
		je 	t2
		cmp al, 0fbh
		je 	t2
		cmp al, 0fch
		je 	t3
		cmp al, 0fah
		je 	t4
		cmp al, 0fch
		je 	t5
		cmp al, 0f8h
		je 	t6
		cmp al, 0fdh
		je 	t7
		cmp al, 0f9h
		je 	t8
		jmp enother
t1:
		mov	dx, offset typePC
		jmp	write
t2:
		mov	dx, offset typePCXT
		jmp	write
t3:
		mov	dx, offset typeAT
		jmp	write
t4:
		mov	dx, offset typePS230
		jmp	write
t5:
		mov	dx, offset typePS250
		jmp	write
t6:
		mov	dx, offset typePS280
		jmp	write
t7:
		mov	dx, offset typePCjr
		jmp	write
t8:
		mov	dx, offset typePCC
		jmp	write
enother:
		call byte_to_hex
		mov	si, offset enothertype
		add	si, 1
		mov	[si], ax
		mov dx, offset enothertype
		
write:
		mov	ah, 09h
		int	21h


;версия системы
		mov	dx, offset ver
		mov	ah, 09h
		int	21h
		
		mov ah, 30h
		int 21h
		
		cmp	al, 0
		jne	not0
		mov	dx, offset ver0
		jmp	write2
not0:	
		mov	si, offset vern0
		add	si, 1
		call byte_to_dec
		
		add	si, 3
		mov al, ah
		call byte_to_dec
		mov dx, offset vern0
		
write2:
		mov	ah, 09h
		int	21h
		
;серийный номер oem
		mov si, offset OEM
		add si, 20d
		mov al, bh
		call byte_to_dec
		mov dx, offset OEM
		mov ah, 09h
		int 21h
		
;серийный номер пользователя		
		mov si, offset userNum
		add si, 20d
		mov al, bl
		call byte_to_hex
		mov [si], ax
		add si, 2
		mov al, ch
		call byte_to_hex
		mov [si], ax
		add si, 2
		mov al, cl
		call byte_to_hex
		mov [si], ax
		mov dx, offset userNum
		mov ah, 09h
		int 21h

; Выход в DOS
		xor AL,AL
		mov AH,4Ch
		int 21H
MAIN	ENDP
CODE 	ENDS
		END MAIN