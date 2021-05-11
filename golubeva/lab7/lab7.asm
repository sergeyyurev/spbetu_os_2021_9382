data segment
	file1 db "f1.ovl", 0
	file2 db "f2.ovl", 0
	program dw 0	
	dta_mem db 43 dup(0)
	mem_flag db 0
	cl_pos db 128 dup(0)
	ovls_addr dd 0
	keep_psp dw 0

	eof db 0dh, 0ah, '$'
	str_mcb_crash_error db 'error: mcb crashed', 0dh, 0ah, '$' 
	str_no_memory_error db 'error: there is not enough memory to execute this function', 0dh, 0ah, '$' 
	str_addr_error db 'error: invalid memory address', 0dh, 0ah, '$'
	str_free_memory db 'memory has been freed' , 0dh, 0ah, '$'
	str_fn_error db 'error: function doesnt exist', 0dh, 0ah, '$' 
	str_file_error db 'error: file not found(load err)', 0dh, 0ah, '$' 
	str_route_error db 'error: route not found(load err)', 0dh, 0ah, '$' 
	str_files_error db 'error: you opened too many files', 0dh, 0ah, '$'
	str_access_error db 'error: no access', 0dh, 0ah, '$' 
	str_mem_error db 'error: insufficient memory', 0dh, 0ah, '$' 
	str_envs_error db 'error: wrong string of environment ', 0dh, 0ah, '$' 	
	str_normal_end db  'load was successful', 0dh, 0ah, '$'
	str_allocation_mem_end db  'allocation_mem was successful', 0dh, 0ah, '$'
	str_all_file_error db  'error: file not found(allocation_mem err)' , 0dh, 0ah, '$'
	str_all_route_error db  'error: route not found(allocation_mem err)' , 0dh, 0ah, '$'
	end_data db 0
data ends

stacks segment stack
	dw 128 dup(?)
stacks ends

code segment

assume cs:code, ds:data, ss:stacks

print_str proc 
 	push ax
 	mov ah, 09h
 	int 21h 
 	pop ax
 	ret
print_str endp 

free_memory proc 
	push ax
	push bx
	push cx
	push dx
	
	mov ax, offset end_data
	mov bx, offset eeend
	add bx, ax
	
	mov cl, 4
	shr bx, cl
	add bx, 2bh
	mov ah, 4ah
	int 21h 

	jnc free_mem_end
	mov mem_flag, 1
	
_mcb_crash:
	cmp ax, 7
	jne no_memory
	mov dx, offset str_mcb_crash_error
	call print_str
	jmp end_free	
no_memory:
	cmp ax, 8
	jne _addr
	mov dx, offset str_no_memory_error
	call print_str
	jmp end_free	
_addr:
	cmp ax, 9
	mov dx, offset str_addr_error
	call print_str
	jmp end_free
free_mem_end:
	mov mem_flag, 1
	mov dx, offset str_free_memory
	call print_str
	
end_free:
	pop dx
	pop cx
	pop bx
	pop ax
	ret
free_memory endp

load_proc proc 
	push ax
	push bx
	push cx
	push dx
	push ds
	push es
	
	mov ax, data
	mov es, ax
	mov bx, offset ovls_addr
	mov dx, offset cl_pos
	mov ax, 4b03h
	int 21h 
	
	jnc _loads
	
_fn_err:
	cmp ax, 1
	jne file_err
	mov dx, offset eof
	call print_str
	mov dx, offset str_fn_error
	call print_str
	jmp _loade
file_err:
	cmp ax, 2
	jne route_err
	mov dx, offset str_file_error
	call print_str
	jmp _loade
route_err:
	cmp ax, 3
	jne _files_err
	mov dx, offset eof
	call print_str
	mov dx, offset str_route_error
	call print_str
	jmp _loade
_files_err:
	cmp ax, 4
	jne _access_err
	mov dx, offset str_files_error
	call print_str
	jmp _loade
_access_err:
	cmp ax, 5
	jne _mem_err
	mov dx, offset str_access_error
	call print_str
	jmp _loade
_mem_err:
	cmp ax, 8
	jne envs_error
	mov dx, offset str_mem_error
	call print_str
	jmp _loade
envs_error:
	cmp ax, 10
	mov dx, offset str_envs_error
	call print_str
	jmp _loade

_loads:
	mov dx, offset str_normal_end
	call print_str
	
	mov ax, word ptr ovls_addr
	mov es, ax
	mov word ptr ovls_addr, 0
	mov word ptr ovls_addr+2, ax

	call ovls_addr
	mov es, ax
	mov ah, 49h
	int 21h

_loade:
	pop es
	pop ds
	pop dx
	pop cx
	pop bx
	pop ax
	ret
load_proc endp

path proc 
	push ax
	push bx
	push cx 
	push dx
	push di
	push si
	push es
	
	mov program, dx

	mov ax, keep_psp
	mov es, ax
	mov es, es:[2ch]
	mov bx, 0
	
findz:
	inc bx
	cmp byte ptr es:[bx-1], 0
	jne findz

	cmp byte ptr es:[bx+1], 0 
	jne findz
	
	add bx, 2
	mov di, 0
	
_loop:
	mov dl, es:[bx]
	mov byte ptr [cl_pos+di], dl
	inc di
	inc bx
	cmp dl, 0
	je _end_loop
	cmp dl, '\'
	jne _loop
	mov cx, di
	jmp _loop
_end_loop:
	mov di, cx
	mov si, program
	
_fn:
	mov dl, byte ptr [si]
	mov byte ptr [cl_pos+di], dl
	inc di 
	inc si
	cmp dl, 0 
	jne _fn
		
	
	pop es
	pop si
	pop di
	pop dx
	pop cx
	pop bx
	pop ax
	ret
path endp

allocation_mem proc
	push ax
	push bx
	push cx
	push dx

	push dx 
	mov dx, offset dta_mem
	mov ah, 1ah
	int 21h
	pop dx 
	mov cx, 0
	mov ah, 4eh
	int 21h

	jnc _all_success

_allfile_err:
	cmp ax, 2
	je _allroute_err
	mov dx, offset str_all_file_error
	call print_str
	jmp _all_end
_allroute_err:
	cmp ax, 3
	mov dx, offset str_all_route_error
	call print_str
	jmp _all_end

_all_success:
	push di
	mov di, offset dta_mem
	mov bx, [di+1ah] 
	mov ax, [di+1ch]
	pop di
	push cx
	mov cl, 4
	shr bx, cl
	mov cl, 12
	shl ax, cl
	pop cx
	add bx, ax
	add bx, 1
	mov ah, 48h
	int 21h
	mov word ptr ovls_addr, ax
	mov dx, offset str_allocation_mem_end
	call print_str

_all_end:
	pop dx
	pop cx
	pop bx
	pop ax
	ret
allocation_mem endp

begin_ovl proc
	push dx
	call path
	mov dx, offset cl_pos
	call allocation_mem
	call load_proc
	pop dx
	ret
begin_ovl endp

begin proc far
	push ds
	xor ax, ax
	push ax
	mov ax, data
	mov ds, ax
	mov keep_psp, es
	call free_memory 
	cmp mem_flag, 0
	je _end

	mov dx, offset file1
	call begin_ovl
	mov dx, offset eof
	call print_str
	mov dx, offset file2
	call begin_ovl

_end:
	xor al, al
	mov ah, 4ch
	int 21h
	
begin endp

eeend:
code ends
end begin
