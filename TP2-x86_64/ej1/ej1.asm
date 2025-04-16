%define NULL 0

section .text

extern malloc
extern free
extern str_concat

global string_proc_list_create_asm
global string_proc_node_create_asm
global string_proc_list_add_node_asm
global string_proc_list_concat_asm

; -------------------------------------------------------------
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

; -------------------------------------------------------------
string_proc_node_create_asm:
    ; rdi: type (uint8_t), rsi: hash
    movzx rdx, dil
    mov r10, rsi

    mov rdi, 32
    call malloc
    test rax, rax
    je .return_null_node

    mov qword [rax], 0         ; next = NULL
    mov qword [rax + 8], 0     ; previous = NULL
    mov byte [rax + 16], dl    ; type
    mov qword [rax + 24], r10  ; hash
    ret

.return_null_node:
    mov rax, 0
    ret

; -------------------------------------------------------------
string_proc_list_add_node_asm:
    ; rdi: list, sil: type, rdx: hash
    test rdi, rdi
    je .return

    mov r8, rdi        ; list
    movzx r9d, sil     ; type
    mov r10, rdx       ; hash

    mov dil, r9b
    mov rsi, r10
    call string_proc_node_create_asm
    test rax, rax
    je .return
    mov r11, rax    

    mov rax, [r8]     
    test rax, rax
    jne .not_empty

    ; lista vacía
    mov [r8], r11      
    mov [r8 + 8], r11  
    jmp .return

.not_empty:
    mov rax, [r8 + 8]      
    mov [r11 + 8], rax      
    mov [rax], r11           
    mov [r8 + 8], r11       

.return:
    ret

; -------------------------------------------------------------
string_proc_list_concat_asm:
    ; rdi: list, sil: type, rdx: hash
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

    mov r12, [r8] 

.loop:
    test r12, r12
    je .done

    movzx eax, byte [r12 + 16]
    cmp eax, r9d
    jne .next

    mov rdi, r11
    mov rsi, [r12 + 24]
    call str_concat
    mov r13, rax

    mov rdi, r11
    call free
    mov r11, r13

.next:
    mov r12, [r12]  ; current = current->next
    jmp .loop

.done:
    mov rax, r11
    ret

.copy_only_hash:
    mov rdi, empty_string
    mov rsi, r10
    call str_concat
    ret

section .data
empty_string: db 0