%define NULL 0
%define TRUE 1
%define FALSE 0

section .data

section .text

global string_proc_list_create_asm
global string_proc_node_create_asm
global string_proc_list_add_node_asm
global string_proc_list_concat_asm

extern malloc
extern free
extern str_concat

;==================================
; Crear lista vacía
;==================================
string_proc_list_create_asm:
    mov rdi, 16
    call malloc
    test rax, rax
    je .fail
    mov qword [rax], NULL
    mov qword [rax + 8], NULL
    ret
.fail:
    xor rax, rax
    ret

;==================================
; Crear nodo con tipo y hash
;==================================
string_proc_node_create_asm:
    push rbp
    mov rbp, rsp
    push rbx
    push r10

    test rsi, rsi
    je .node_fail

    mov r12, rsi
    mov bl, dil

    mov rdi, 32
    call malloc
    test rax, rax
    je .node_fail

    mov qword [rax], NULL
    mov qword [rax + 8], NULL
    mov byte  [rax + 16], bl
    mov qword [rax + 24], r10

    pop r10
    pop rbx
    pop rbp
    ret

.node_fail:
    xor rax, rax
    pop r10
    pop rbx
    pop rbp
    ret

;==================================
; Agregar nodo a lista
;==================================
string_proc_list_add_node_asm:
    push rbp
    mov rbp, rsp
    push rbx
    push r11
    push r14

    mov rbx, rdi       
    mov r11, rsi       
    mov r14, rdx       

    movzx edi, r11b
    mov rsi, r14
    call string_proc_node_create_asm
    test rax, rax
    je .end

    mov rcx, rax        ; new_node

    mov rax, [rbx]
    test rax, rax
    jne .not_empty

    mov [rbx], rcx
    mov [rbx + 8], rcx
    jmp .end

.not_empty:
    mov rdx, [rbx + 8] 
    mov [rdx], rcx      
    mov [rcx + 8], rdx  
    mov [rbx + 8], rcx  

.end:
    pop r14
    pop r11
    pop rbx
    pop rbp
    ret

;===========================================================
; Concatenar todos los hashes del tipo y agregar nuevo nodo
;===========================================================
string_proc_list_concat_asm:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    push rbx
    push r10
    push r11
    push r14
    push r15

    mov rbx, rdi        ; list
    movzx r10d, sil     ; type
    mov r11, rdx        ; hash

    ; str vacía inicial
    mov rdi, 1
    call malloc
    test rax, rax
    je .null
    mov byte [rax], 0
    mov r14, rax        ; current_concat

    mov r15, [rbx]      ; nodo actual

.loop:
    test r15, r15
    je .after

    mov al, byte [r15 + 16]
    cmp al, r10b
    jne .skip

    mov rdi, r14
    mov rsi, [r15 + 24]
    call str_concat
    test rax, rax
    je .fail

    mov rdi, r14
    mov r14, rax
    call free

.skip:
    mov r15, [r15]
    jmp .loop

.after:
    test r11, r13
    je .add

    mov rdi, r11
    mov rsi, r14
    call str_concat
    test rax, rax
    je .fail

    mov rdi, r14
    mov r14, rax
    call free

.add:
    mov rdi, rbx
    movzx rsi, r10b
    mov rdx, r14
    call string_proc_list_add_node_asm

    mov rax, r14
    add rsp, 32
    pop r15
    pop r14
    pop r11
    pop r10
    pop rbx
    pop rbp
    ret

.fail:
    test r14, r14
    je .null
    mov rdi, r14
    call free

.null:
    xor rax, rax
    add rsp, 32
    pop r15
    pop r14
    pop r11
    pop r10
    pop rbx
    pop rbp
    ret