code segment
assume  cs:code, ds:data, ss:stacks

stacks  segment stack
 dw  256 dup(0)
stacks  ends

data segment
    str_load db  "interruption has loaded",0dh,0ah,"$"
    str_loaded db  "interruption  already loaded",0dh,0ah,"$"
    str_unload db  "interruption has unloaded",0dh,0ah,"$"
    str_not_loaded  db  "interruption is not loaded",0dh,0ah,"$"
    is_load  db  0
    is_un db  0
data ends

interruption proc far
    jmp  start
interruptiondata:
    key_value db 0
    signature dw 6666h
    keep_ip dw 0
    keep_cs dw 0
    keep_psp dw 0
    keep_ax dw 0
    keep_ss dw 0
    keep_sp dw 0
    new_stack dw 256 dup(0)
		
start:
    mov keep_ax, ax
    mov keep_sp, sp
    mov keep_ss, ss
    mov ax, seg new_stack
    mov ss, ax
    mov ax, offset new_stack
    add ax, 256
    mov sp, ax	

    push ax
    push bx
    push cx
    push dx
    push si
    push es
    push ds
    mov ax, seg key_value
    mov ds, ax
    
    in al, 60h
    cmp al, 11h	
    je key_w
    cmp al, 12h
    je key_e
    cmp al, 13h
    je k_r
    
    pushf
    call dword ptr cs:keep_ip
    jmp end_interr

key_w:
    mov key_value, '1'
    jmp next_key
key_e:
    mov key_value, '2'
    jmp next_key
k_r:
    mov key_value, '3'

next_key:
    in al, 61h
    mov ah, al
    or 	al, 80h
    out 61h, al
    xchg al, al
    out 61h, al
    mov al, 20h
    out 20h, al
  
print_key:
    mov ah, 05h
    mov cl, key_value
    mov ch, 00h
    int 16h
    or 	al, al
    jz 	end_interr
    mov ax, 0040h
    mov es, ax
    mov ax, es:[1ah]
    mov es:[1ch], ax
    jmp print_key

end_interr:
    pop  ds
    pop  es
    pop		si
    pop  dx
    pop  cx
    pop  bx
    pop		ax

    mov sp, keep_sp
    mov ax, keep_ss
    mov ss, ax
    mov ax, keep_ax

    mov  al, 20h
    out  20h, al
iret
interruption endp
 _end:

is_interr_load proc
    push ax
    push bx
    push si
    
    mov  ah, 35h
    mov  al, 09h
    int  21h
    mov  si, offset signature
    sub  si, offset interruption
    mov  ax, es:[bx + si]
    cmp	 ax, signature
    jne  eeendis_l
    mov  is_load, 1
    
eeendis_l:
    pop  si
    pop  bx
    pop  ax
    ret
    is_interr_load endp

    int_load  proc
    push ax
    push bx
    push cx
    push dx
    push es
    push ds

    mov ah, 35h
    mov al, 09h
    int 21h
    mov keep_cs, es
    mov keep_ip, bx
    mov ax, seg interruption
    mov dx, offset interruption
    mov ds, ax
    mov ah, 25h
    mov al, 09h
    int 21h
    pop ds

    mov dx, offset _end
    mov cl, 4h
    shr dx, cl
    add	dx, 10fh
    inc dx
    xor ax, ax
    mov ah, 31h
    int 21h

    pop es
    pop dx
    pop cx
    pop bx
    pop ax
ret
int_load  endp

unload_interrupt proc
    cli
    push ax
    push bx
    push dx
    push ds
    push es
    push si
    
    mov ah, 35h
    mov al, 09h
    int 21h
    mov si, offset keep_ip
    sub si, offset interruption
    mov dx, es:[bx + si]
    mov ax, es:[bx + si + 2]
 
    push ds
    mov ds, ax
    mov ah, 25h
    mov al, 09h
    int 21h
    pop ds
    
    mov ax, es:[bx + si + 4]
    mov es, ax
    push es
    mov ax, es:[2ch]
    mov es, ax
    mov ah, 49h
    int 21h
    pop es
    mov ah, 49h
    int 21h
    
    sti
    
    pop si
    pop es
    pop ds
    pop dx
    pop bx
    pop ax
 
ret
unload_interrupt endp

is_unload_  proc
    push ax
    push es

    mov ax, keep_psp
    mov es, ax
    cmp byte ptr es:[82h], '\'
    jne eeendun
    cmp byte ptr es:[83h], 'u'
    jne eeendun
    cmp byte ptr es:[84h], 'n'
    jne eeendun
    mov is_un, 1
 
eeendun:
    pop es
    pop ax
 ret
is_unload_ endp

print_str proc near
    push ax
    mov ah, 09h
    int 21h
    pop ax
ret
print_str endp

begin proc
    push ds
    xor ax, ax
    push ax
    mov ax, data
    mov ds, ax
    mov keep_psp, es
    
    call is_interr_load
    call is_unload_
    cmp is_un, 1
    je unload
    mov al, is_load
    cmp al, 1
    jne load
    mov dx, offset str_loaded
    call print_str
    jmp eeend
load:
    mov dx, offset str_load
    call print_str
    call int_load
    jmp  eeend
unload:
    cmp  is_load, 1
    jne  not_loaded
    mov dx, offset str_unload
    call print_str
    call unload_interrupt
    jmp  eeend
not_loaded:
    mov  dx, offset str_not_loaded
    call print_str
eeend:
    xor al, al
    mov ah, 4ch
    int 21h
begin endp
code ends
end begin
