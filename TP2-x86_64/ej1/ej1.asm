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
    jz .fail
    mov qword [rax], NULL
    mov qword [rax+8], NULL
    ret
.fail:
    xor rax, rax
    ret

string_proc_node_create_asm:
    test rsi, rsi
    jz .fail_node

    movzx ecx, dil       ; type -> ecx
    mov r8, rsi          ; hash -> r8

    mov rdi, 32
    call malloc
    test rax, rax
    jz .fail_node

    mov qword [rax], NULL
    mov qword [rax+8], NULL
    mov byte [rax+16], cl
    mov qword [rax+24], r8
    ret

.fail_node:
    xor rax, rax
    ret

string_proc_list_add_node_asm:
    test rdi, rdi
    jz .end_add

    mov r8, rdi       ; list
    mov r9b, sil      ; type
    mov r10, rdx      ; hash

    movzx edi, r9b
    mov rsi, r10
    call string_proc_node_create_asm
    test rax, rax
    jz .end_add

    mov r11, rax

    mov rax, [r8]
    test rax, rax
    jnz .add_to_end

    ; Lista vacía
    mov [r8], r11
    mov [r8+8], r11
    jmp .end_add

.add_to_end:
    mov rcx, [r8+8]
    mov [rcx], r11
    mov [r11+8], rcx
    mov [r8+8], r11

.end_add:
    ret

string_proc_list_concat_asm:
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 8

    mov rbx, rdi     ; list
    movzx r12d, sil  ; type
    mov r13, rdx     ; hash

    test rbx, rbx
    jz .ret_null

    mov rdi, 1
    call malloc
    test rax, rax
    jz .ret_null

    mov byte [rax], 0
    mov r14, rax         ; new_hash
    mov r15, [rbx]       ; current_node = list->first

.loop:
    test r15, r15
    jz .after_loop

    mov al, [r15+16]
    cmp al, r12b
    jne .next_node

    mov rdi, r14
    mov rsi, [r15+24]
    call str_concat
    test rax, rax
    jz .free_and_null

    mov rdi, r14
    mov r14, rax
    call free

.next_node:
    mov r15, [r15]
    jmp .loop

.after_loop:
    test r13, r13
    jz .ret_r14

    mov rdi, r13
    mov rsi, r14
    call str_concat
    test rax, rax
    jz .free_and_null

    mov rdi, r14
    mov r14, rax
    call free

.ret_r14:
    mov rax, r14
    add rsp, 8
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

.free_and_null:
    test r14, r14
    jz .ret_null
    mov rdi, r14
    call free

.ret_null:
    xor rax, rax
    add rsp, 8
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret