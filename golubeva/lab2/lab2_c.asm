LAB2 SEGMENT
    ASSUME CS:LAB2, DS:LAB2, ES:NOTHING, SS:NOTHING
ORG 100H
    START: JMP BEGIN
s_address db '�������� ���� ������㯭�� ����� � 16��:     ', 0DH, 0AH, '$';43
s_envir db '�������� ���� �।�, ��।������� �ணࠬ�� � 16��:     ',  0DH, 0AH, '$';54
s_tail db '��㬥��� ��������� ��ப�: ', '$';28
s_contain db '����ঠ��� ������ �।�: ', 0DH, 0AH, '$'
s_path db '���� ����㦠����� �����: ', '$'
s_ent db ' ', 0DH, 0AH, '$'
    
;procedures
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

enter proc near
	mov DX, offset s_ent
    mov ah, 09h
    int 21h
    ret
enter endp

BEGIN:

address:
    mov ax, ds:[2h]
    mov di, offset s_envir-4
    call WRD_TO_HEX
    
    mov dx, offset s_address
    mov ah, 09h
    int 21h

environment:
    mov ax, ds:[2Ch]
    push ax
    
    mov di, offset s_tail-4
    call WRD_TO_HEX
    
    mov dx, offset s_envir
    mov ah, 09h
    int 21h

tail_command_line:
    mov dx, offset s_tail
    mov ah, 09h
    int 21h

    mov ch, ds:[80h]
    mov cl, 0h
    xor di, di
    
loop_str:
    cmp ch, cl
    jle contain_environment_area
    
    
    mov dl, ds:[81h+di]
    inc di
    mov ah, 02h
    int 21h
    dec ch
    
    jmp loop_str 

contain_environment_area:
    call enter
    mov dx, offset s_contain
    mov ah, 09h
    int 21h
    
    mov bx, ds
    
   
    pop ax
    push bx
    
    mov ds, ax

    xor di, di
    
    mov dl, [di]
    mov ah, 02h
    int 21h
    
    jmp loop_area

e:
    inc di
    mov dl, 2Ch
    mov ah, 02h
    int 21h
    
    mov dl, 20h
    mov ah, 02h
    int 21h
    
loop_area:  
 
    cmp word ptr [di], 0000h
    je path
    cmp byte ptr [di], 00h
    
    je e
    
    mov dl, [di]
    mov ah, 02h
    int 21h
    inc di
    
    jmp loop_area

path:
    
    pop bx
    mov ax, ds
    push ax
    mov ds, bx
    
    add di, 4h
    call enter
    mov dx, offset s_path
    mov ah, 09h
    int 21h
    
    pop bx
    mov ds, bx

loop_path:
    
    cmp byte ptr [di], 00h
    je end_pro
    
    mov dl, [di]
    mov ah, 02h
    int 21h
    
    inc di
    jmp loop_path

end_pro:
    xor AL,AL
    mov AH,4Ch
    int 21H
LAB2    ENDS
          END START
