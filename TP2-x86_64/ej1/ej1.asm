%define NULL 0

section .text

global string_proc_list_create_asm
global string_proc_node_create_asm
global string_proc_list_add_node_asm
global string_proc_list_concat_asm

extern malloc
extern free
extern str_concat

; ================================
; Crear lista vacía
; ================================
string_proc_list_create_asm:
    mov rdi, 16
    call malloc
    test rax, rax
    je .return_null
    mov qword [rax], NULL
    mov qword [rax + 8], NULL
    ret
.return_null:
    xor rax, rax
    ret

; ================================
; Crear nodo con tipo y hash
; ================================
string_proc_node_create_asm:
    test rsi, rsi
    je .node_fail

    mov r10b, dil
    mov r11, rsi

    mov rdi, 32
    call malloc
    test rax, rax
    je .node_fail

    mov qword [rax], NULL     
    mov qword [rax + 8], NULL    
    mov byte [rax + 16], r10b
    mov qword [rax + 24], r11       
    ret

.node_fail:
    xor rax, rax
    ret

; ================================
; Agregar nodo a lista
; ================================
string_proc_list_add_node_asm:
    test rdi, rdi
    je .done

    mov r8, rdi        ; list
    mov r9b, sil        ; type
    mov r10, rdx        ; hash

    movzx edi, r9b
    mov rsi, r10
    call string_proc_node_create_asm
    test rax, rax
    je .done
    mov r11, rax

    mov rax, [r8]
    test rax, rax
    jne .append

    ; Lista vacía
    mov [r8], r11
    mov [r8 + 8], r11
    jmp .done

.append:
    mov rcx, [r8 + 8]
    mov [rcx], r11
    mov [r11 + 8], rcx
    mov [r8 + 8], r11

.done:
    ret

; ================================
; Concatenar hashes 
; ================================
string_proc_list_concat_asm:
    test rdi, rdi
    je .concat_null

    mov r8, rdi
    movzx r9d, sil
    mov r10, rdx

    mov rdi, 1
    call malloc
    test rax, rax
    je .concat_null
    mov byte [rax], 0
    mov r11, rax

    mov rax, [r8]

.concat_loop:
    test rax, rax
    je .combine_hash

    mov bl, [rax + 16]
    cmp bl, r9b
    jne .next

    mov rdi, r11
    mov rsi, [rax + 24]
    call str_concat
    test rax, rax
    jz .concat_fail

    mov r12, rax
    mov rdi, r11
    call free
    mov r11, r12

.next:
    mov rax, [rax]
    jmp .concat_loop

.combine_hash:
    test r10, r10
    je .return_concat

    mov rdi, r10
    mov rsi, r11
    call str_concat
    test rax, rax
    jz .concat_fail

    mov r12, rax
    test r11, r11
    jz .skip_free
    mov rdi, r11
    call free

.skip_free:
    mov r11, r12
    jmp .return_concat

.return_concat:
    mov rax, r11
    ret

.concat_fail:
    cmp r11, 0
    je .concat_null
    mov al, byte [r11]
    cmp al, 0
    jne .maybe_free
    mov al, byte [r11 + 1]
    cmp al, 0
    je .concat_null

.maybe_free:
    mov rdi, r11
    call free

.concat_null:
    xor rax, rax
    ret