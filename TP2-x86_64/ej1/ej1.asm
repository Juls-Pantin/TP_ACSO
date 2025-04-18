%define NULL 0

section .text

    global string_proc_list_create_asm
    global string_proc_node_create_asm
    global string_proc_list_add_node_asm
    global string_proc_list_concat_asm

    extern malloc
    extern free
    extern str_concat

; Crear lista vacía
data_structure_init:
    mov rdi, 16
    call malloc
    test rax, rax
    je .fail
    mov qword [rax], 0
    mov qword [rax+8], 0
    ret
.fail:
    xor rax, rax
    ret

string_proc_list_create_asm:
    push rbp
    mov rbp, rsp
    call data_structure_init
    pop rbp
    ret

; Crear nodo con tipo y hash
string_proc_node_create_asm:
    push rbp
    mov rbp, rsp
    push rbx
    push r10

    test rsi, rsi
    je .error_node

    mov bl, dil
    mov r10, rsi

    mov rdi, 32
    call malloc
    test rax, rax
    je .error_node

    mov qword [rax], 0
    mov qword [rax+8], 0
    mov byte [rax+16], bl
    mov qword [rax+24], r10

    pop r10
    pop rbx
    pop rbp
    ret

.error_node:
    xor rax, rax
    pop r10
    pop rbx
    pop rbp
    ret

; Agregar nodo a lista
string_proc_list_add_node_asm:
    push rbp
    mov rbp, rsp
    push r8
    push r9
    push r10

    mov r8, rdi
    mov r9, rsi
    mov r10, rdx

    movzx edi, r9b
    mov rsi, r10
    call string_proc_node_create_asm
    test rax, rax
    je .done_add

    mov rdx, rax
    mov rax, [r8]
    test rax, rax
    jne .nonempty

    mov [r8], rdx
    mov [r8+8], rdx
    jmp .done_add

.nonempty:
    mov rcx, [r8+8]
    mov [rcx], rdx
    mov [rdx+8], rcx
    mov [r8+8], rdx

.done_add:
    pop r10
    pop r9
    pop r8
    pop rbp
    ret

; Concatenar todos los hashes del tipo y agregar nuevo nodo
string_proc_list_concat_asm:
    push rbp
    mov rbp, rsp
    push r8
    push r9
    push r10
    push r11
    push r12
    push r13
    sub rsp, 8

    mov r8, rdi
    movzx r9d, sil
    mov r10, rdx

    test r8, r8
    je .fail_concat

    mov rdi, 1
    call malloc
    test rax, rax
    je .fail_concat

    mov byte [rax], 0
    mov r11, rax
    mov r12, [r8]  ; current_node

.loop:
    test r12, r12
    je .loop_done
    mov al, byte [r12+16]
    cmp al, r9b
    jne .skip
    mov rdi, r11
    mov rsi, [r12+24]
    call str_concat
    test rax, rax
    je .fail_free

    mov r13, rax
    mov rdi, r11
    call free
    mov r11, r13
.skip:
    mov r12, [r12]
    jmp .loop

.loop_done:
    mov rdi, r8
    movzx esi, r9b
    mov rdx, r11
    call string_proc_list_add_node_asm

    mov rax, r11
    add rsp, 8
    pop r13
    pop r12
    pop r11
    pop r10
    pop r9
    pop r8
    pop rbp
    ret

.fail_free:
    mov rdi, r11
    call free

.fail_concat:
    xor rax, rax
    add rsp, 8
    pop r13
    pop r12
    pop r11
    pop r10
    pop r9
    pop r8
    pop rbp
    ret