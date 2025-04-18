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
    test rsi, rsi
    je .node_fail

    mov r8b, dil    ; type
    mov r9, rsi     ; hash

    mov rdi, 32
    call malloc
    test rax, rax
    je .node_fail

    mov qword [rax], NULL
    mov qword [rax + 8], NULL
    mov byte  [rax + 16], r8b
    mov qword [rax + 24], r9
    ret
.node_fail:
    xor rax, rax
    ret

;==================================
; Agregar nodo a lista
;==================================
string_proc_list_add_node_asm:
    test rdi, rdi
    je .done

    mov r8, rdi     ; list
    mov r9, rdx     ; hash
    movzx r10d, sil  ; type

    mov rdi, r10
    mov rsi, r9
    call string_proc_node_create_asm
    test rax, rax
    je .done

    mov r11, rax        ; nuevo nodo

    mov rax, [r8]
    test rax, rax
    jne .append

    mov [r8], r11       ; list->first
    mov [r8 + 8], r11   ; list->last
    jmp .done

.append:
    mov rcx, [r8 + 8]
    mov [rcx], r11
    mov [r11 + 8], rcx
    mov [r8 + 8], r11

.done:
    ret

;===========================================================
; Concatenar todos los hashes del tipo y agregar nuevo nodo
;===========================================================
string_proc_list_concat_asm:
    test rdi, rdi
    je .null_exit

    mov r8, rdi     ; list
    movzx r9d, sil  ; type
    mov r10, rdx    ; hash final

    mov rdi, 1
    call malloc
    test rax, rax
    je .null_exit
    mov byte [rax], 0
    mov r11, rax      

    mov rax, [r8]    

.loop:
    test rax, rax
    je .after_loop

    mov bl, [rax + 16]
    cmp bl, r9b
    jne .next

    mov rdi, r11
    mov rsi, [rax + 24]
    call str_concat
    test rax, rax
    je .fail_concat

    mov r12, rax
    mov rdi, r11
    call free
    mov r11, r12

.next:
    mov rax, [rax]
    jmp .loop

.after_loop:
    test r10, r10
    je .add_node

    mov rdi, r10
    mov rsi, r11
    call str_concat
    test rax, rax
    je .fail_concat

    mov r12, rax
    mov rdi, r11
    call free
    mov r11, r12

.add_node:
    mov rdi, r8     ; list
    movzx rsi, r9b    ; type
    mov rdx, r11    ; hash
    call string_proc_list_add_node_asm

    mov rax, r11    ; liberar el string concatenado
    ret

.fail_concat:
    test r11, r11
    je .null_exit
    mov rdi, r11
    call free

.null_exit:
    xor rax, rax
    ret