testpc	   segment
assume  cs:testpc, ds:testpc, es:nothing, ss:nothing
org	   100h
start: jmp begin

str_not_mem 		db 'inaccessible memory:     ', 0dh,0ah,'$'
str_env_adr		db 'enviroment adress:     ', 0dh,0ah,'$'
str_tail			db 'command line tail:', 0dh,0ah,'$'
endl			db  0dh,0ah,'$'
str_env			db 'enviroment: ', 0dh,0ah,'$'
str_path			db 'path: ', 0dh,0ah,'$'
str_empty			db ' ', 0dh,0ah,'$'


tetr_to_hex proc near
	and al,0fh
	cmp al,09
	jbe next
	add al,07
next:	add al,30h
	ret
tetr_to_hex endp

byte_to_hex proc near
	push cx
	mov ah,al
	call tetr_to_hex
	xchg al,ah
	mov cl,4
	shr al,cl
	call tetr_to_hex  
	pop cx
	ret
byte_to_hex endp

wrd_to_hex proc near
	push bx
	mov bh,ah
	call byte_to_hex
	mov [di],ah
	dec di
	mov [di],al
	dec di
	mov al,bh
	call byte_to_hex
	mov [di],ah
	dec di
	mov [di],al
	pop bx
	ret
wrd_to_hex endp

print proc near
	push ax
	mov ah, 09h
	int 21h
	pop ax
	ret
print endp

not_enough_mem_proc proc near
	mov ax, ds:[02h]	
   	mov di, offset str_not_mem	 
   	add di, 24
   	call wrd_to_hex
   	mov dx, offset str_not_mem	
   	call print
   	ret
not_enough_mem_proc endp

env_info_proc proc near
	mov ax, ds:[2ch]
   	mov di, offset str_env_adr
   	add di, 22
   	call wrd_to_hex	
   	mov dx, offset str_env_adr
   	call print
   	ret
env_info_proc endp

tail_info_proc proc near
	xor cx, cx
	mov cl, ds:[80h]
	mov si, offset str_tail
	add si, 18
   	cmp cl, 0h
   	je isstr_empty
	xor di, di
	xor ax, ax
tail_loop: 
	mov al, ds:[81h+di]
   	inc di
   	mov [si], al
	inc si
	loop tail_loop
	mov dx, offset str_tail
	jmp endstr_tail
isstr_empty:
	mov dx, offset str_empty
endstr_tail: 
   	call print
   	ret
tail_info_proc endp

info_proc proc near
	mov dx, offset str_env
   	call print
   	xor di,di
   	mov ds, ds:[2ch]
_str:
	cmp byte ptr [di], 00h
	jz endline
	mov dl, [di]
	mov ah, 02h
	int 21h
	jmp isend
endline:
   	cmp byte ptr [di+1],00h
   	jz isend
   	push ds
   	mov cx, cs
	mov ds, cx
	mov dx, offset endl
	call print
	pop ds
isend:
	inc di
	cmp word ptr [di], 0001h
	jnz _str
	call path
	ret
info_proc endp

path proc near
	push ds
	mov ax, cs
	mov ds, ax
	mov dx, offset str_path 
	call print
	pop ds
	add di, 2
path_loop:
	cmp byte ptr [di], 00h
	jz pend
	mov dl, [di]
	mov ah, 02h
	int 21h
	inc di
	jmp path_loop
pend:
	ret
path endp

begin:	
	call not_enough_mem_proc
	call env_info_proc
	call tail_info_proc
	call info_proc
	xor al,al
	mov ah,01h
	int 21h 
	mov ah,4ch
	int 21h
testpc ends
	end start
