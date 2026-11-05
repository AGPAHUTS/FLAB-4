; =====================================================================
; Georgette Eatery Ordering System in NASM (32-bit Linux)
; =====================================================================

section .data
    file_name   db "receipt.txt", 0
    
    msg_title   db "=== Welcome to Georgette Eatery ===", 10, 0
    len_title   equ $ - msg_title
    
    msg_menu    db "A. Rice : Plain Rice       Php 5.00", 10, "B. Rice : Java Rice        Php 10.00", 10, "C. Ulam 1: Fish            Php 35.00", 10, "D. Ulam 2: Pork            Php 50.00", 10, "E. Ulam 3: Vegetables      Php 20.00", 10, "F. Dessert: Saging con yelo Php 60.00", 10, 0
    len_menu    equ $ - msg_menu
    
    prompt_choice   db "Enter your choice (A-F): ", 0
    len_choice      equ $ - prompt_choice
    
    prompt_again    db "Do you want to order again? [Y/N]: ", 0
    len_again       equ $ - prompt_again
    
    msg_thanks      db 10, "Thank you! Please come again!", 10, "--- RECEIPT ---", 10, 0
    len_thanks      equ $ - msg_thanks
    
    ; Menu items data strings
    item_a          db "A. Rice : Plain Rice       Php 5.00", 10
    len_a           equ $ - item_a
    item_b          db "B. Rice : Java Rice        Php 10.00", 10
    len_b           equ $ - item_b
    item_c          db "C. Ulam 1: Fish            Php 35.00", 10
    len_c           equ $ - item_c
    item_d          db "D. Ulam 2: Pork            Php 50.00", 10
    len_d           equ $ - item_d
    item_e          db "E. Ulam 3: Vegetables      Php 20.00", 10
    len_e           equ $ - item_e
    item_f          db "F. Dessert: Saging con yelo Php 60.00", 10
    len_f           equ $ - item_f

    err_msg         db "Invalid choice! Please choose between A-F.", 10, 0
    len_err         equ $ - err_msg

    err_again_msg   db "Invalid input! Please enter Y or N.", 10, 0
    len_err_again   equ $ - err_again_msg

section .bss
    choice          resb 4
    again           resb 4
    receipt_buf     resb 2048    ; RAM buffer to accumulate all ordered items
    receipt_len     resd 1       ; Track total bytes stored in receipt_buf
    fd              resb 4

section .text
    global _start

; =====================================================================
; MACRO: print
; =====================================================================
%macro print 2
    mov eax, 4          ; sys_write
    mov ebx, 1          ; stdout
    mov ecx, %1
    mov edx, %2
    int 0x80
%endmacro

; =====================================================================
; MACRO: append_item (Safely copies selected item into receipt buffer)
; =====================================================================
%macro append_item 2
    push esi
    push edi
    push ecx
    
    mov esi, %1             ; Source string
    mov edi, receipt_buf
    mov ecx, [receipt_len]
    add edi, ecx            ; Destination pointer = receipt_buf + current length
    mov ecx, %2             ; Length of item string
    
%%copy_loop:
    mov al, [esi]
    mov [edi], al
    inc esi
    inc edi
    dec ecx
    jnz %%copy_loop
    
    add dword [receipt_len], %2 ; Safely update total receipt length with dword size specified
    
    pop ecx
    pop edi
    pop esi
%endmacro

_start:
    ; Initialize receipt length to 0
    mov dword [receipt_len], 0

order_loop:
    ; Call Procedure to display menu
    call display_menu

    ; Ask for user choice
    print prompt_choice, len_choice

    ; Read user choice from stdin
    mov eax, 3          ; sys_read
    mov ebx, 0          ; stdin
    mov ecx, choice
    mov edx, 4
    int 0x80

    ; Evaluate choice
    mov al, [choice]
    
    cmp al, 'A'
    je handle_a
    cmp al, 'a'
    je handle_a

    cmp al, 'B'
    je handle_b
    cmp al, 'b'
    je handle_b

    cmp al, 'C'
    je handle_c
    cmp al, 'c'
    je handle_c

    cmp al, 'D'
    je handle_d
    cmp al, 'd'
    je handle_d

    cmp al, 'E'
    je handle_e
    cmp al, 'e'
    je handle_e

    cmp al, 'F'
    je handle_f
    cmp al, 'f'
    je handle_f

    ; Invalid input handling for menu choice
    print err_msg, len_err
    jmp order_loop

handle_a:
    print item_a, len_a
    append_item item_a, len_a
    jmp ask_again

handle_b:
    print item_b, len_b
    append_item item_b, len_b
    jmp ask_again

handle_c:
    print item_c, len_c
    append_item item_c, len_c
    jmp ask_again

handle_d:
    print item_d, len_d
    append_item item_d, len_d
    jmp ask_again

handle_e:
    print item_e, len_e
    append_item item_e, len_e
    jmp ask_again

handle_f:
    print item_f, len_f
    append_item item_f, len_f
    jmp ask_again

ask_again:
    print prompt_again, len_again

    mov eax, 3
    mov ebx, 0
    mov ecx, again
    mov edx, 4
    int 0x80

    mov al, [again]
    cmp al, 'Y'
    je order_loop
    cmp al, 'y'
    je order_loop

    cmp al, 'N'
    je end_program
    cmp al, 'n'
    je end_program

    print err_again_msg, len_err_again
    jmp ask_again

; =====================================================================
; PROCEDURE: display_menu
; =====================================================================
display_menu:
    print msg_title, len_title
    print msg_menu, len_menu
    ret

end_program:
    ; 1. Print closing message and receipt header to stdout
    print msg_thanks, len_thanks

    ; 2. Print the complete receipt directly from RAM buffer to the screen!
    mov eax, 4          ; sys_write
    mov ebx, 1          ; stdout
    mov ecx, receipt_buf
    mov edx, [receipt_len]
    int 0x80

    ; 3. Create/Write the receipt buffer to receipt.txt file on disk
    mov eax, 5          ; sys_open
    mov ebx, file_name
    mov ecx, 0102h      ; O_WRONLY | O_CREAT | O_TRUNC
    mov edx, 0644h      ; Permissions
    int 0x80
    mov [fd], eax

    mov eax, 4          ; sys_write
    mov ebx, [fd]
    mov ecx, receipt_buf
    mov edx, [receipt_len]
    int 0x80

    mov eax, 6          ; sys_close
    mov ebx, [fd]
    int 0x80

    ; 4. Exit program cleanly
    mov eax, 1          ; sys_exit
    xor ebx, ebx
    int 0x80