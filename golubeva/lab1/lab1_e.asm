stacks segment  STACK
    db 256 dup(?)
stacks ends    

data segment    

STRING_AX db 'Значение в регистре AX= ', '$'
string_ibm db 'Тип IBM: ','$'
STRING_OEM db 'Серийный номер OEM в 16сс:    ', '$'
STRING_SER_NUM db 'Серийный номер пользователя: ', '$'
STRING_VERS db 'Версия системы:       ', '$'
string_ent db ' ', 0AH, 0DH, '$'
string_dot db '.', '$'
string_t1 db 'PC','$'
string_t2 db 'PC/XT','$'
string_t3 db 'AT','$'
string_t4 db 'PS2 модель 30','$'
string_t5 db 'PS2 модель 80','$'
string_t6 db 'PCjr','$'
string_t7 db 'PC Convertible','$'
string_t8 db 'Неизвестный тип IBM','$'
;-----------------------------------------------------
data ends

code segment

    ASSUME CS:code, DS:data, SS:stacks
    
 
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
print proc near
    mov BH, AH
    
    mov dl, al
    mov ah, 02h
    int 21h
    
    mov dl, bh
    mov ah, 02h
    int 21h
    ret
print endp

enter proc near
	mov DX, offset string_ent
    mov ah, 09h
    int 21h
    ret
enter endp	

what_version proc near
    mov dx, offset string_ibm
    mov ah, 09h
    int 21h
    
    
l1: 
    cmp bl, 0FFh
    jne l2
    mov dx, offset string_t1
    mov ah, 09h
    int 21h
    ret
l2:
    cmp bl, 0FEh
    jne l2_2
l2_2:    
    cmp bl, 0FBh
    jne l3
    mov dx, offset string_t2
    mov ah, 09h
    int 21h
    ret
l3:
    cmp bl, 0FCh
    jne l4
    mov dx, offset string_t3
    mov ah, 09h
    int 21h
    ret
l4:
    cmp bl, 0FAh
    jne l5
    mov dx, offset string_t4
    mov ah, 09h
    int 21h
    ret
l5:
    cmp bl, 0F8h
    jne l6
    mov dx, offset string_t5
    mov ah, 09h
    int 21h
    ret
l6:
    cmp bl, 0FDh
    jne l7
    mov dx, offset string_t6
    mov ah, 09h
    int 21h
    ret
l7:
    cmp bl, 0F9h
    jne l8
    mov dx, offset string_t7
    mov ah, 09h
    int 21h

    ret
l8:
    mov dx, offset string_t8
    mov ah, 09h
    int 21h


    ret
what_version endp 

BEGIN proc far

    mov AX, data
    mov DS, AX
    mov DX, offset STRING_AX
    mov ah, 09h
    int 21h
    
ibm_pc:
    mov BX, 0F000h
    mov ES, BX
    mov AL, ES:[0FFFEh] 

    mov bl, al
    
    call BYTE_TO_HEX
    call print
    call enter
    
ibm_type:

    call what_version  
    call enter
    
    
base_version:
    
    mov ah, 30h
    int 21h
    
modif_num:


    push bx
    push ax
    
    
    mov al, ah
    mov si, offset STRING_VERS+22
    call BYTE_TO_DEC

    mov al, 2Eh
    
    mov [si], al
    dec si
    pop ax
    
    call BYTE_TO_DEC
    
    
 mov dx, offset STRING_VERS
    mov ah, 09h 
    int 21h
oem:
    pop bx
    ;call enter
    
    mov si, offset STRING_OEM+29
    
    mov al, bh
    call BYTE_TO_HEX
    mov [si], ah 
    mov [si-1], al
    
    mov dx, offset STRING_OEM
    mov ah, 09h 
    int 21h
    
    call enter
    
num:
    mov DX, offset STRING_SER_NUM
    mov ah, 09h 
    int 21h
    
    mov al, bl
    call BYTE_TO_HEX
    call print
    mov al, ch
    call BYTE_TO_HEX
    call print
    mov al, cl
    call BYTE_TO_HEX
    call print
   
    xor AL,AL
    mov AH,4Ch
    int 21H
begin endp    
code    ENDS
          END begin
