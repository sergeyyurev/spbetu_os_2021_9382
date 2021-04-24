stacks segment stack 
	dw 64 dup(?)
stacks ends

assume cs:code, ds:data, ss:stacks

code segment

int_count_func proc far
	jmp run
	
	keep_cs dw 0                               
	keep_ip dw 0                           
	nowPsp dw 0      							                   
	memAdrPsp dw 0	                          	
	count_interruptions dw 0fedch           
	keep_ss dw 0						
	keep_sp dw 0						
	keep_ax dw 0						
	count_mes db 'Count of interruptions: 0000 $' 
	newstack dw 64 dup(?)
run:

	mov keep_sp, sp 
    mov keep_ax, ax
    mov keep_ss, ss
    mov sp, offset run
    mov ax, seg newstack
    mov ss, ax
	
	push ax      
	push bx
	push cx
	push dx

	mov ah, 3h 
	mov bh, 0h 
	int 10h

	push dx 
	
	mov ah, 2h 
	mov bh, 0h
	mov bl, 2h
	mov dx, 0h
	int 10h

	push si
	push cx
	push ds

	mov ax, seg count_mes
	mov ds, ax
	mov si, offset count_mes
	add si, 27
	mov cx, 4

loop_m:
	mov ah,[si]
	inc ah
	mov [si], ah
	cmp ah, 3ah
	jne end_interrupt
	mov ah, 30h
	mov [si], ah	
	dec si
	loop loop_m
	
end_interrupt:
    pop ds
    pop cx
	pop si
	push es
	push bp

	mov ax, seg count_mes
	mov es, ax
	mov ax, offset count_mes
	mov bp, ax
	mov ah, 13h
	mov al, 00h
	mov cx, 28
	mov bh, 0
	int 10h

	pop bp
	pop es

	pop dx
	mov ah, 02h
	mov bh, 0h
	int 10h

	pop dx
	pop cx
	pop bx
	pop ax  
		
    mov ss, keep_ss
    mov ax, keep_ax
	mov sp, keep_sp

	iret
int_count_func endp

isBootFunc proc near
	push bx
	push dx
	push es

	mov ah, 35h
	mov al, 1ch
	int 21h

	mov dx, es:[bx + 11]
	cmp dx, 0fedch
	je int_is_set
	mov al, 00h
	jmp end_check_boot

int_is_set:
	mov al, 01h
	jmp end_check_boot

end_check_boot:
	pop es
	pop dx
	pop bx

	ret
isBootFunc endp

sizee:

check_unboot proc near
	push es
	
	mov ax, nowPsp
	mov es, ax
	
	mov al, es:[81h+1]
	cmp al, '/'
	jne end_check

	mov al, es:[81h+2]
	cmp al, 'u'
	jne end_check

	mov al, es:[81h+3]
	cmp al, 'n'
	jne end_check
	mov al, 1h
end_check:
	pop es

	ret
check_unboot endp

loadfunc proc near
	push ax
	push bx
	push dx
	push es

	mov ah, 35h 
	mov al, 1ch
	int 21h
	mov keep_ip, bx
	mov keep_cs, es

	push ds

	mov dx, offset int_count_func
	mov ax, seg int_count_func
	mov ds, ax
	mov ah, 25h 
	mov al, 1ch 
	int 21h 

	pop ds

	mov dx, offset str_load
	call print_str

	pop es
	pop dx
	pop bx
	pop ax

	ret
loadfunc endp

UnBootFunc proc near
	push ax
	push bx
	push dx
	push es

	mov ah, 35h
	mov al, 1ch
	int 21h

	push ds   

	mov dx, es:[bx + 5]  
	mov ax, es:[bx + 3]
	mov ds, ax
	mov ah, 25h
	mov al, 1ch
	int 21h 

	pop ds

	sti
	mov dx, offset str_unload
	call print_str

	push es	

	mov cx, es:[bx + 7] ;nowPsp
	mov es, cx
	mov ah, 49h
	int 21h

	pop es
	
	mov cx, es:[bx + 9] ;memAdrPsp
	mov es, cx
	int 21h

	pop es
	pop dx
	pop bx
	pop ax
	
	ret
UnBootFunc endp

print_str proc near
	push ax

	mov ah, 09h
	int	21h

	pop ax

	ret
print_str endp

main proc far
	mov bx, 02ch
	mov ax, [bx]
	mov memAdrPsp, ax
	mov nowPsp, ds  
	xor ax, ax    
	xor bx, bx

	mov ax, data  
	mov ds, ax    

	call check_unboot  
	cmp al, 01h
	je unload_mark

	call isBootFunc  
	cmp al, 01h
	jne interruption_is_not_loaded
	
	mov dx, offset str_already_load	
	call print_str
	jmp eeend
       
	mov ah,4ch
	int 21h

interruption_is_not_loaded:
	call loadfunc
	
	mov dx, offset sizee
	mov cl, 04h
	shr dx, cl
	add dx, 1bh
	mov ax, 3100h
	int 21h
         
unload_mark:
	call isBootFunc
	cmp al, 00h
	je not_set
	call UnBootFunc
	jmp eeend

not_set:
	mov dx, offset str_not_loaded
	call print_str
    jmp eeend
	
eeend:
	mov ah, 4ch
	int 21h
main endp

code ends

data segment
	str_not_loaded db "interrupt not loaded", 0DH, 0AH, '$'
	str_unload db "interrupt unloaded", 0DH, 0AH, '$'
	str_already_load db "interrupt is already load", 0DH, 0AH, '$'
	str_load db "interrupt was loaded", 0DH, 0AH, '$'
data ends

end main