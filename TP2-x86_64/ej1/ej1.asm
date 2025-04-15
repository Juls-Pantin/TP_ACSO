%define NULL 0
%define TRUE 1
%define FALSE 0

section .data

section .text
extern printf
extern strdup

global string_proc_list_create_asm
global string_proc_node_create_asm
global string_proc_list_add_node_asm
global string_proc_list_concat_asm

; FUNCIONES auxiliares que pueden llegar a necesitar:
extern malloc
extern free
extern str_concat

#ifndef LOG_INFO
#define LOG_INFO(x)
#endif

#ifndef LOG_ERROR
#define LOG_ERROR(x)
#endif

string_proc_list_create_asm:
    ;reservar 16 bytes para la lista
    mov rdi, 16     ;argumento de malloc -> rdi = 16
    call malloc     ;malloc(16), puntero resultante en rax

    ;verificar si malloc fallo (rax == NULL)
    test rax, rax
    je .return_null     ;si es NULL, saltar al final

    ;inicializar list->first = NULL
    mov qword [rax], 0

    ;inicializar list->last = NULL
    mov qword [rax + 8], 0

.return_null:
    ret



string_proc_node_create_asm:
    ; debug: imprimir type y hash recibidos
    push rsi
    movzx rsi, dil
    pop rsi

    ;rdi = type(uint8_t)
    ;rsi = hash(char *)

    ;reservar 32 bytes para el nodo
    ;rdi = type(uint8_t)
    ;rsi = hash(char *)

    ;reservar 32 bytes para el nodo
    mov rdx, rdi        ;guardamos type en rdx (porque rdi se pisa en malloc)
    mov rcx, rsi        ;guardamos hash en rcx

    mov rdi, 32         ;malloc(32)
    call malloc         
    test rax, rax
    je .return_null     ;si malloc falla, devolvemos NULL

    ;rax = puntero al nodo

    ;inicializar next = NULL
    mov qword[rax + 0], 0

    ;inicializar previous = NULL
    mov qword[rax + 8], 0

    ;escribir type (1 byte)
    mov byte [rax + 16], dl     ;(type estaba en rdx -> parte baja dl)

    ;escribir hash
    mov qword[rax + 24], rcx    ;(hash estaba en rcx)

.return_null:
    ret



string_proc_list_add_node_asm:
    ; rdi = list
    ; rsi = type
    ; rdx = hash

    push rbx
    push r12
    push r13
    push r8

    ; Guardar list en rbx, type en r8, hash en rcx (corregido)
    mov rbx, rdi        ; rbx = list
    mov r8, rsi         ; r8 = type
    mov rcx, rdx        ; rcx = hash

    ; Llamar a string_proc_node_create_asm(type, hash)
    mov rdi, r8         ; rdi = type
    mov rsi, rcx        ; rsi = hash
    call string_proc_node_create_asm
    test rax, rax
    je .return          ; si falla malloc, salimos

    ; rax = new_node

    ; if (list->first == NULL)
    cmp qword [rbx], 0
    je .lista_vacia

.lista_no_vacia:
    ; new_node->previous = list->last
    mov rcx, [rbx + 8]       ; rcx = list->last
    mov [rax + 8], rcx       ; new_node->previous = rcx

    ; list->last->next = new_node
    mov [rcx], rax           ; list->last->next = new_node

    ; list->last = new_node
    mov [rbx + 8], rax

    jmp .return

.lista_vacia:
    ; list->first = new_node
    mov [rbx], rax

    ; list->last = new_node
    mov [rbx + 8], rax

.return:
    pop r8
    pop r13
    pop r12
    pop rbx
    ret



string_proc_list_concat_asm:
    ; rdi = list
    ; rsi = type
    ; rdx = hash

    ; Validar que list != NULL y hash != NULL
    test rdi, rdi
    je .ret_null
    test rdx, rdx
    je .ret_null

    ; Guardar list en rbx, type en cl, hash en r8
    mov rbx, rdi
    mov cl, sil          ; type (uint8_t) → cl
    mov r8, rdx          ; hash → r8

    ; result = str_concat("", hash)
    mov rdi, r8
    call strdup
    mov r12, rax         ; r12 = result

    ; current = list->first
    mov r13, [rbx]       ; r13 = current

.loop:
    test r13, r13
    je .done             ; while (current != NULL)

    ; comparar current->type con type
    mov al, [r13 + 16]   ; current->type
    cmp al, cl
    jne .next_node       ; if (type != current->type) skip

    ; llamar a str_concat(result, current->hash)
    mov rdi, r12         ; result
    mov rsi, [r13 + 24]  ; current->hash
    call str_concat      ; retorna nuevo string en rax

    ; liberar viejo result
    mov rdi, r12
    call free

    ; result = nuevo string
    mov r12, rax

.next_node:
    ; current = current->next
    mov r13, [r13]       ; current = current->next
    jmp .loop

.done:
    mov rax, r12
    ret

.ret_null:
    mov rax, 0
    ret
