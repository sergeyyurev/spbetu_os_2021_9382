TESTPC  SEGMENT

ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING

ORG 100H

START: JMP begin

str_avail_mem db 'Количество доступной памяти в байтах: ','$'
str_exp_mem db 'Размер расширенной памяти Кб: ', '$'
str_seg1 db 0DH, 0AH, '0000h - свободный участок',0DH, 0AH,'$'
str_seg2 db 0DH, 0AH, '0006h - участок принадлежит драйверу OS XMS UMB',0DH, 0AH,'$'
str_seg3 db 0DH, 0AH, '0007h - участок является исключенной верхней памятью драйверов',0DH, 0AH,'$'
str_seg4 db 0DH, 0AH, '0008h - участок принадлежит MS DOS',0DH, 0AH,'$'
str_seg5 db 0DH, 0AH, 'FFFAh - участок занят управляющим блоком 386MAX UMB',0DH, 0AH,'$'
str_seg6 db 0DH, 0AH, 'FFFDh - участок заблокирован 386MAX',0DH, 0AH,'$'
str_seg7 db 0DH, 0AH, 'FFFEh - участок принадлежит 386MAX UMB',0DH, 0AH,'$'
str_wr db 0DH, 0AH, 'Пользовательский участок',0DH, 0AH,'$'
str_size_b db 'Размер участка в байтах: ', '$'
str_sequ db 'Последовательность символов: ', '$'
str_ent db ' ', 0DH, 0AH, '$'
str_div db 0DH, 0AH, '------------------------------------', 0DH, 0AH, '$'

TETR_TO_HEX PROC NEAR
    AND AL, 0FH
    CMP AL, 09
    JBE NEXT
    ADD AL, 07

NEXT:
    ADD AL, 30H
    RET
TETR_TO_HEX ENDP


BYTE_TO_HEX PROC NEAR
    PUSH CX
    MOV AH, AL
    CALL TETR_TO_HEX
    XCHG AL, AH
    MOV CL, 4
    SHR AL, CL
    CALL TETR_TO_HEX
    POP CX
    RET
BYTE_TO_HEX ENDP


WRD_TO_HEX PROC NEAR
    PUSH BX
    MOV BH, AH
    CALL BYTE_TO_HEX
    MOV [DI], AH
    DEC DI
    MOV [DI], AL
    DEC DI
    MOV AL, BH
    CALL BYTE_TO_HEX
    MOV [DI], AH
    DEC DI
    MOV [DI], AL
    POP BX
    RET
WRD_TO_HEX ENDP


BYTE_TO_DEC PROC NEAR
    PUSH CX
    PUSH DX
    XOR AH, AH
    XOR DX, DX
    MOV CX, 10

LOOP_BD:
    DIV CX
    OR DL, 30H
    MOV [SI], DL
    DEC SI
    XOR DX, DX
    CMP AX, 10
    JAE LOOP_BD

    CMP AL, 00H
    JE END_L
    OR AL, 30H
    MOV [SI], AL

END_L:
    POP DX
    POP CX
    RET
BYTE_TO_DEC ENDP


PARAGRAPH2BYTES PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI

	MOV BX, 10H
	MUL BX
	MOV BX, 0AH
	XOR CX, CX

DIVISION:
	DIV BX
	PUSH DX
	INC CX
	XOR DX, DX
	CMP AX, 0H
	JNZ DIVISION

WRITE_SYMBOL:
	POP DX
	OR DL, 30H
	MOV [SI], DL
	INC SI
	LOOP WRITE_SYMBOL

    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
	RET
PARAGRAPH2BYTES ENDP

empty_func proc near
    mov ax, es
    push dx
    mul bx
    add bx, cx
    div cx
    
    
    pop dx
ret
empty_func endp


WRITE_STRING PROC NEAR
    PUSH AX
    MOV AH, 9H
    INT 21H
    POP AX
    RET
WRITE_STRING ENDP


avail_mem proc near
    push dx
    push bx
    push ax
    mov dx, offset str_avail_mem
    mov ah, 09h
    int 21h
    
    mov ah, 4ah
    mov bx, 0ffffh
    int 21h
    
    mov ax, bx

    mov bx, 16
    mul bx
    
    call print_number
    
    mov dx, offset str_exp_mem
    mov ah, 09h
    int 21h
    
    mov AL,30h 
    out 70h,AL
    in AL,71h
    mov BL,AL;
    mov AL,31h 
    out 70h,AL
    in AL,71h
    
    
    mov bh,al
    mov ax,bx
    
    mov bx,1h
	mul bx

    call print_number
    
    pop ax
    pop bx
    pop dx


ret 
avail_mem endp

print_number proc near
    push bx
    push cx
    push ax
	mov bx,0Ah
	xor cx,cx
divis:
	div bx
	push dx
	inc cx
	xor dx,dx
	cmp ax,0
	jne divis
	
print_simb:
	pop dx
	or dl,30h
	
	mov ah,02h
	int 21h
    loop print_simb
    
    call enter
    pop ax
    pop cx
    pop bx

ret
print_number endp


OFFSET_DECIMAL_NUMBER PROC NEAR
OFFSET_LOOP:
    CMP BYTE PTR [SI], ' '
    JNE EXIT_OFFSET_DECIMAL
    INC SI
    JMP OFFSET_LOOP

EXIT_OFFSET_DECIMAL:
    RET
OFFSET_DECIMAL_NUMBER ENDP

addr_psp proc near
    push dx

    cmp ax, 0000h
    mov dx, offset str_seg1
    je end_addr
    
    mov [di], ax
    cmp word ptr [di], 0006h
    mov dx, offset str_seg2
    je end_addr
    
    mov [di], ax
    cmp word ptr [di], 0007h
    mov dx, offset str_seg3
    je end_addr
    
    mov [di], ax
    cmp word ptr [di], 0008h
    mov dx, offset str_seg4
    je end_addr
 
    mov [di], ax
    cmp word ptr [di], 0FFFAh
    mov dx, offset str_seg5
    je end_addr 
    

    mov [di], ax
    cmp word ptr [di], 0FFFDh
    mov dx, offset str_seg6
    je end_addr 
    
    mov [di], ax
    cmp word ptr [di], 0FFFEh
    mov dx, offset str_seg7
    je end_addr 
    
    mov dx, offset str_wr
    
end_addr: 

    
    mov ah, 09h
    int 21h
    pop dx
    mov ax, bx
    mov bx, cx
    mov cx, dx
    mov dx, ax
    
ret 
addr_psp endp

enter proc near
    push dx
    push ax
    mov dx, offset str_ent
    mov ah, 09h
    int 21h
    pop ax
    pop dx

ret
enter endp



PRINT_MCB_CHAIN PROC NEAR
    push es
    
    mov ah, 52h
    int 21h


    mov ax, es:[bx-2]
    mov es, ax; in es the address of first mcb
    
loop_list:
    mov ax, es:[1]

    call addr_psp
    
    
    mov dx, offset str_size_b
    mov ah, 09h
    int 21h
    
    mov ax, es:[3h]
    mov bx, 16
    mul bx
    call print_number
    
    mov dx, offset str_sequ
    mov ah, 09h
    int 21h
    
    xor di, di
    mov cx, 8h
    
loo_: 
    mov dl, es:[8h+di]
    mov ah, 02h
    int 21h
    inc di
    loop loo_
    
    mov dx, offset str_div
    mov ah, 09h
    int 21h

    
    mov bx, es:[3h]
    mov al,es:[0h]
    cmp al, 5Ah
    je end_pr
    
    mov ax, es
	add ax,bx
	inc ax
	mov es,ax; in es the address of follow mcb
	
    jmp loop_list
    
    
end_pr:
    pop es
ret
PRINT_MCB_CHAIN endp

FREE_MEM PROC NEAR
    push ax
    push bx
    push dx

    LEA AX, end_this_code
    MOV BX, 10H
    XOR DX, DX
    DIV BX
    INC AX
    MOV BX, AX
    add bx, 5h
    MOV AL, 0
    MOV AH, 4AH
    INT 21H
    
    pop dx
    pop bx
    pop ax

    RET
FREE_MEM ENDP


begin:
    CALL avail_mem
    CALL free_mem
    CALL PRINT_MCB_CHAIN

    XOR AL, AL
    MOV AH, 4CH
    INT 21H


end_this_code:
TESTPC  ENDS
END START
