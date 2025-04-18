%define NULL 0

section .text

    global string_proc_list_create_asm
    global string_proc_node_create_asm
    global string_proc_list_add_node_asm
    global string_proc_list_concat_asm

    extern malloc
    extern free
    extern str_concat

==================================
; Crear lista vacía
==================================
string_proc_node_create_asm:
    mov rdi, 16
    call malloc
    test rax, rax
    je .fail
    mov qword [rax], 0
    mov qword [rax + 8], 0
    ret
.fail:
    xor rax, rax
    ret

==================================
; Crear nodo con tipo y hash
==================================
string_proc_node_create_asm:
    test rsi, rsi
    je .node_fail

    mov r10b, dil       ; guardar type
    mov r11, rsi        ; guardar hash

    mov rdi, 32
    call malloc
    test rax, rax
    je .node_fail

    mov qword [rax], 0          ; next
    mov qword [rax + 8], 0      ; previous
    mov byte [rax + 16], r10b   ; type
    mov qword [rax + 24], r11   ; hash
    ret

.node_fail:
    xor rax, rax
    ret

==================================
; Agregar nodo a lista
==================================
string_proc_list_add_node_asm:
    test rdi, rdi
    je .done

    mov r8, rdi     ; list
    mov r9, rdx     ; hash
    movzx ecx, sil  ; type

    mov rdi, rcx
    mov rsi, r9
    call string_proc_node_create_asm
    test rax, rax
    je .done

    mov r10, rax        ; nuevo nodo

    mov rax, [r8]
    test rax, rax
    jne .append

    mov [r8], r10       ; list->first
    mov [r8 + 8], r10   ; list->last
    jmp .done

.append:
    mov r11, [r8 + 8]
    mov [r11], r10
    mov [r10 + 8], r11
    mov [r8 + 8], r10

.done:
    ret

===========================================================
; Concatenar todos los hashes del tipo y agregar nuevo nodo
===========================================================
string_proc_list_concat_asm:
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
    mov r11, rax        ; new_hash

    mov rax, [r8]       ; current = list->first

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

    mov rdi, r11
    mov r11, rax
    call free

.next:
    mov rax, [rax]
    jmp .loop

.after_loop:
    test r10, r10
    je .finish

    mov rdi, r10
    mov rsi, r11
    call str_concat
    test rax, rax
    je .fail_concat

    mov rdi, r11
    mov r11, rax
    call free

.finish:
    mov rax, r11
    ret

.fail_concat:
    test r11, r11
    je .null_exit
    mov rdi, r11
    call free

.null_exit:
    xor rax, rax
    ret