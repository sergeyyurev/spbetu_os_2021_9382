LAB3 SEGMENT
    ASSUME CS:LAB3, DS:LAB3, ES:NOTHING, SS:NOTHING
ORG 100H
    START: JMP BEGIN
    
str_avail_mem db 'Количество доступной памяти в байтах: ', '$'
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

    
    
TETR_TO_HEX PROC near
    and AL, 0Fh
    cmp AL, 09
    jbe NEXT
    add AL, 07
NEXT: add AL, 30h
    ret
TETR_TO_HEX ENDP
;-------------------------------
BYTE_TO_HEX PROC near
;byte AL translate in two symbols on 16cc numbers in AX
    push CX
    mov AH,AL
    call TETR_TO_HEX
    xchg AL,AH
    mov CL, 4
    shr AL,CL
    call TETR_TO_HEX
    pop CX
ret
BYTE_TO_HEX ENDP
;-------------------------------
WRD_TO_HEX PROC near
;translate in 16cc a 16 discharge number
;in AL - number, DI - the address of the last symbol  
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
;translate in 10cc, SI - the adress of the field of younger digit
    push CX
    push DX
    xor AH,AH
    xor DX,DX
    mov CX,10
loop_bd: div CX
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
end_l: pop DX
    pop CX
ret
BYTE_TO_DEC ENDP
;-------------------------------

print_addr_psp proc near
    push bx

    mov BH, AH
    
    mov dl, al
    mov ah, 02h
    int 21h
    
    mov dl, bh
    mov ah, 02h
    int 21h
    pop bx


ret
print_addr_psp endp



addr_psp proc near

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

    
ret 
addr_psp endp

print_number proc near
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

ret
print_number endp

enter proc near
    mov dx, offset str_ent
    mov ah, 09h
    int 21h


ret
enter endp

avail_mem proc near
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


ret 
avail_mem endp


BEGIN:
    call avail_mem
    
    
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


    xor AL,AL
    mov AH,4Ch
    int 21H
end_this_code:
    
LAB3    ENDS
          END START
