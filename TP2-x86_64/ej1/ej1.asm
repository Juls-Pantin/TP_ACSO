%define NULL 0

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

; ================================
; Crear lista vacía
; ================================
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

; ================================
; Crear nodo con tipo y hash
; ================================
string_proc_node_create_asm:
    test rsi, rsi
    je .fail_node
    mov r10, rsi
    movzx r11d, dil
    mov rdi, 32
    call malloc
    test rax, rax
    je .fail_node
    mov qword [rax], NULL
    mov qword [rax + 8], NULL
    mov byte [rax + 16], r11b
    mov qword [rax + 24], r10
    ret
.fail_node:
    xor rax, rax
    ret

; ================================
; Agregar nodo a lista
; ================================
string_proc_list_add_node_asm:
    test rdi, rdi
    je .done_add
    mov r8, rdi        ; list
    mov r9, rdx        ; hash
    mov r10d, esi      ; type

    mov dil, sil
    mov rsi, r9
    call string_proc_node_create_asm
    test rax, rax
    je .done_add
    mov r11, rax

    mov rax, [r8]
    test rax, rax
    jne .append

    ; Lista vacía
    mov [r8], r11
    mov [r8 + 8], r11
    jmp .done_add

.append:
    mov r12, [r8 + 8]
    mov [r12], r11
    mov [r11 + 8], r12
    mov [r8 + 8], r11

.done_add:
    ret

; ================================
; Concatenar hashes
; ================================
string_proc_list_concat_asm:
    ; rdi = list, sil = type, rdx = hash
    test rdi, rdi
    je .just_return_hash
    mov r8, rdi
    movzx r9d, sil
    mov r10, rdx

    mov rdi, 1
    call malloc
    test rax, rax
    je .concat_fail
    mov byte [rax], 0
    mov r11, rax

    mov r12, [r8]

.scan_nodes:
    test r12, r12
    je .combine_hash

    movzx eax, byte [r12 + 16]
    cmp eax, r9d
    jne .next_node

    mov rdi, r11
    mov rsi, [r12 + 24]
    call str_concat
    test rax, rax
    je .concat_fail
    mov r13, rax
    cmp r11, r10
    je .skip_free_r11
    test r11, r11
    je .skip_free_r11
    mov rdi, r11

.skip_free_r11:
    mov r11, r13

.next_node:
    mov r12, [r12]
    jmp .scan_nodes

.combine_hash:
    test r10, r10
    je .return_final

    mov rdi, r10
    mov rsi, r11
    call str_concat
    test rax, rax
    je .concat_fail
    mov r13, rax
    mov rdi, r11
    call free
    mov r11, r13

.return_final:
    mov rax, r11
    ret

.just_return_hash:
    mov rdi, empty_string
    mov rsi, rdx
    call str_concat
    test rax, rax
    je .concat_fail
    ret

.concat_fail:
    xor rax, rax
    ret