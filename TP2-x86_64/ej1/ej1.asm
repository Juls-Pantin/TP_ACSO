%define NULL 0
%define TRUE 1
%define FALSE 0

section .data
empty_string: db 0

section .text

extern malloc
extern free
extern str_concat

global string_proc_list_create_asm
global string_proc_node_create_asm
global string_proc_list_add_node_asm
global string_proc_list_concat_asm

string_proc_list_create_asm:
    mov rdi, 16
    call malloc
    test rax, rax
    je .return_null
    mov qword [rax], 0
    mov qword [rax + 8], 0
    ret

.return_null:
    mov rax, 0
    ret

string_proc_node_create_asm:
    movzx rdx, dil
    mov r10, rsi

    mov rdi, 32
    call malloc
    test rax, rax
    je .return_null

    mov qword [rax], 0
    mov qword [rax + 8], 0
    mov byte  [rax + 16], dl
    mov qword [rax + 24], r10
    ret

.return_null:
    mov rax, 0
    ret

string_proc_list_add_node_asm:
    test rdi, rdi
    je .return

    mov r8, rdi
    movzx r9d, sil
    mov r10, rdx

    xor edi, edi         ; Limpiamos edi antes de cargar el tipo
    mov dil, sil         ; Pasamos correctamente el uint8_t al arg1
    mov rsi, rdx         ; Ya estaba bien (hash)
    call string_proc_node_create_asm
    test rax, rax
    je .return
    mov r11, rax

    mov rax, [r8]
    test rax, rax
    jne .not_empty

    mov [r8], r11
    mov [r8 + 8], r11
    ret

.not_empty:
    mov rax, [r8 + 8]
    mov [r11 + 8], rax
    mov [rax], r11
    mov [r8 + 8], r11

.return:
    ret

string_proc_list_concat_asm:
    mov r8, rdi
    movzx r9d, sil
    mov r10, rdx

    test r8, r8
    je .copy_only_hash

    mov rax, [r8]
    test rax, rax
    je .copy_only_hash

    ; result = str_concat("", hash)
    mov rdi, empty_string
    mov rsi, r10
    call str_concat
    mov r11, rax

    mov r12, [r8]  ; current = list->first

.loop:
    test r12, r12
    je .done

    mov al, [r12 + 16]  ; current->type
    cmp al, r9b
    jne .next_node

    mov rdi, r11
    mov rsi, [r12 + 24]
    call str_concat
    mov r13, rax

    mov rdi, r11
    call free

    mov r11, r13

.next_node:
    mov r12, [r12]
    jmp .loop

.done:
    mov rax, r11
    ret

.copy_only_hash:
    mov rdi, empty_string
    mov rsi, r10
    call str_concat
    ret