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
    je .fail

    mov r8b, dil     
    mov r9, rsi     

    mov rdi, 32
    call malloc
    test rax, rax
    je .fail

    mov qword [rax], NULL     
    mov qword [rax + 8], NULL   
    mov byte [rax + 16], r10b
    mov qword [rax + 24], r11
    ret

.fail:
    xor rax, rax
    ret

; ================================
; Agregar nodo a lista
; ================================
string_proc_list_add_node_asm:
    test rdi, rdi
    je .end

    mov r8, rdi       ; list
    mov r9b, sil      ; type
    mov r10, rdx      ; hash

    movzx edi, r9b
    mov rsi, r10
    call string_proc_node_create_asm
    test rax, rax
    je .end
    mov r11, rax      ; new_node

    mov rax, [r8]     ; list->first
    test rax, rax
    jne .append

    ; Lista vacía
    mov [r8], r11      ; list->first = new_node
    mov [r8 + 8], r11  ; list->last  = new_node
    jmp .end

.append:
    mov rcx, [r8 + 8] ; last node
    mov [rcx], r11    ; last->next = new_node
    mov [r11 + 8], rcx ; new_node->prev = last
    mov [r8 + 8], r11 ; list->last = new_node

.end:
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

.loop:
    test rax, rax
    je .combine

    mov bl, [rax + 16]   
    cmp bl, r9b
    jne .next

    mov rdi, r11
    mov rsi, [rax + 24]
    call str_concat
    mov r12, rax
    mov rdi, r11
    call free
    mov r11, r12

.next:
    mov rax, [rax]    
    jmp .loop

.combine:
    test r10, r10
    je .return

    mov rdi, r10
    mov rsi, r11
    call str_concat
    mov r12, rax
    mov rdi, r11
    call free
    mov r11, r12

.return:
    mov rax, r11
    ret

.fail:
    test r11, r11
    je .concat_null
    mov rdi, r11
    call free

.concat_null:
    xor rax, rax
    ret
