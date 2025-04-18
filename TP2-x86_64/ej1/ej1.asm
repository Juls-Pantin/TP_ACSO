%define NULL 0

section .text

global string_proc_list_create_asm
global string_proc_node_create_asm
global string_proc_list_add_node_asm
global string_proc_list_concat_asm

extern malloc
extern free
extern str_concat

string_proc_list_create_asm:
    mov rdi, 16
    call malloc
    test rax, rax
    je .fail_list
    mov qword [rax], NULL
    mov qword [rax + 8], NULL
    ret
.fail_list:
    xor rax, rax
    ret

string_proc_node_create_asm:
    test rsi, rsi
    je .fail_node
    mov r8b, dil
    mov r9, rsi

    mov rdi, 32
    call malloc
    test rax, rax
    je .fail_node

    mov qword [rax], NULL
    mov qword [rax + 8], NULL
    mov byte [rax + 16], r8b
    mov qword [rax + 24], r9
    ret
.fail_node:
    xor rax, rax
    ret

string_proc_list_add_node_asm:
    test rdi, rdi
    je .end_add

    mov r8, rdi        ; list
    mov r9, rsi        ; type
    mov r10, rdx       ; hash

    movzx edi, r9b
    mov rsi, r10
    call string_proc_node_create_asm
    test rax, rax
    je .end_add
    mov r11, rax

    mov rax, [r8]
    test rax, rax
    jne .append_node

    mov [r8], r11
    mov [r8 + 8], r11
    jmp .end_add

.append_node:
    mov rcx, [r8 + 8]
    mov [rcx], r11
    mov [r11 + 8], rcx
    mov [r8 + 8], r11

.end_add:
    ret

string_proc_list_concat_asm:
    test rdi, rdi
    je .fail_concat

    mov r8, rdi        ; list
    movzx r9d, sil     ; type
    mov r10, rdx       ; hash extra

    mov rdi, 1
    call malloc
    test rax, rax
    je .fail_concat
    mov byte [rax], 0
    mov r11, rax

    mov r12, [r8]      ; nodo actual

.loop_nodes:
    test r12, r12
    je .join_extra

    mov al, [r12 + 16]
    cmp al, r9b
    jne .next_iter

    mov rdi, r11
    mov rsi, [r12 + 24]
    call str_concat
    test rax, rax
    je .fail_concat
    mov rdi, r11
    mov r11, rax
    call free

.next_iter:
    mov r12, [r12]
    jmp .loop_nodes

.join_extra:
    test r10, r10
    je .done_concat

    mov rdi, r10
    mov rsi, r11
    call str_concat
    test rax, rax
    je .fail_concat
    mov rdi, r11
    mov r11, rax
    call free

.done_concat:
    mov rax, r11
    ret

.fail_concat:
    xor rax, rax
    ret
