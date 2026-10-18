[org 0x0100]
jmp start

; ---- DATA ----

title: db 'TEXT VIEWER', 0

line1: db '8088 Assembly Language Text Viewer', 0
line2: db 'String instructions: LODSB STOSW MOVSW', 0
line3: db 'STACK parameters and BP addressing', 0
line4: db 'Search keyword: STACK', 0
line5: db 'Scrolling inside the viewport window', 0
line6: db 'Video memory segment is B800h', 0

keyword: db 'STACK', 0

status_text: db 'Total Matches Found: ', 0
status_tail: db ' | Viewport Status: ACTIVE', 0

matches: dw 0
outpos: dw 0
textattr: db 07h
blank: dw 0720h

; ---- MAIN ----

start:
    push cs
    pop ds

    mov ax, 0B800h
    mov es, ax

    ; clear screen
    xor di, di
    mov ax, 0720h
    mov cx, 2000
    cld
    rep stosw

    ; top-left
    mov di, 3*160+8*2
    mov ax, 07C9h
    stosw

    ; top line
    mov di, 3*160+9*2
    mov ax, 07CDh
    mov cx, 63
    rep stosw

    ; top-right
    mov di, 3*160+72*2
    mov ax, 07BBh
    stosw

    ; bottom-left
    mov di, 21*160+8*2
    mov ax, 07C8h
    stosw

    ; bottom line
    mov di, 21*160+9*2
    mov ax, 07CDh
    mov cx, 63
    rep stosw

    ; bottom-right
    mov di, 21*160+72*2
    mov ax, 07BCh
    stosw

    ; side borders
    mov bx, 4

vertical_loop:
    cmp bx, 21
    jae vertical_done

    ; left
    mov ax, bx
    mov si, 160
    mul si
    mov di, ax
    add di, 8*2
    mov ax, 07BAh
    stosw

    ; right
    mov ax, bx
    mov si, 160
    mul si
    mov di, ax
    add di, 72*2
    mov ax, 07BAh
    stosw

    inc bx
    jmp vertical_loop

vertical_done:

    ; title
    mov si, title
    mov di, 3*160+35*2
    mov ah, 1Eh

title_loop:
    lodsb
    cmp al, 0
    je title_done
    stosw
    jmp title_loop

title_done:

    ; text lines
    push word line1
    push word 5*160+10*2
    call printline

    push word line2
    push word 7*160+10*2
    call printline

    push word line3
    push word 9*160+10*2
    call printline

    push word line4
    push word 11*160+10*2
    call printline

    push word line5
    push word 13*160+10*2
    call printline

    push word line6
    push word 15*160+10*2
    call printline

    ; scroll up by 1

    push word 1
    push word 72
    push word 21
    push word 8
    push word 3
    call scroll_window_up

    ; search and highlight
    push word 0CEh
    push word keyword
    call find_and_highlight

    ; status bar
    mov di, 23*160
    mov si, status_text
    mov ah, 0Fh

status_loop:
    lodsb
    cmp al, 0
    je status_count
    stosw
    jmp status_loop

status_count:
    mov [outpos], di        ; start of number
    push word [matches]
    call printNum
    mov di, [outpos]        ; after number

    ; rest of status
    mov si, status_tail
    mov ah, 0Fh

tail_loop:
    lodsb
    cmp al, 0
    je tail_done
    stosw
    jmp tail_loop

tail_done:
    ; wait for key
    xor ah, ah
    int 16h

    ; exit
    mov ax, 4C00h
    int 21h


;  PRINT LINE 

; [bp+4] screen offset
; [bp+6] string offset

printline:
    push bp
    mov bp, sp
    push ax
    push si
    push di

    mov si, [bp+6]
    mov di, [bp+4]
    mov ah, 07h
    cld

printline_loop:
    lodsb
    cmp al, 0
    je printline_done

    stosw
    jmp printline_loop

printline_done:
    pop di
    pop si
    pop ax
    pop bp
    ret 4


;  SCROLL WINDOW UP 

; [bp+4] top
; [bp+6] left
; [bp+8] bottom
; [bp+10] right
; [bp+12] N
;
; [bp-2] current row
; [bp-4] source row
; [bp-6] width
; [bp-8] rows to copy

scroll_window_up:
    push bp
    mov bp, sp
    sub sp, 8

    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push ds
    push es
    pop ds                  ; DS is video segment

    ; width
    mov ax, [bp+10]
    sub ax, [bp+6]
    dec ax
    mov [bp-6], ax

    ; rows to copy
    mov ax, [bp+8]
    sub ax, [bp+4]
    dec ax
    sub ax, [bp+12]
    mov [bp-8], ax

    ; first dest row
    mov ax, [bp+4]
    inc ax
    mov [bp-2], ax

scroll_copy_row:
    cmp word [bp-8], 0
    jg scroll_copy_go
    jmp scroll_clear_start
scroll_copy_go:

    ; source row
    mov ax, [bp-2]
    add ax, [bp+12]
    mov [bp-4], ax

    ; source offset
    mov ax, [bp-4]
    mov bx, 160
    mul bx
    mov si, ax

    mov ax, [bp+6]
    inc ax
    shl ax, 1
    add si, ax

    ; dest offset
    mov ax, [bp-2]
    mov bx, 160
    mul bx
    mov di, ax

    mov ax, [bp+6]
    inc ax
    shl ax, 1
    add di, ax

    ; copy one row
    mov cx, [bp-6]
    cld
    rep movsw

    inc word [bp-2]
    dec word [bp-8]
    jmp scroll_copy_row

scroll_clear_start:
    ; clear vacated rows
    mov ax, [bp+8]
    sub ax, [bp+12]
    mov [bp-2], ax

scroll_clear_row:
    ; last interior row
    mov ax, [bp+8]
    dec ax
    cmp [bp-2], ax
    jbe scroll_clear_go
    jmp scroll_done
scroll_clear_go:

    ; offset
    mov ax, [bp-2]
    mov bx, 160
    mul bx
    mov di, ax

    mov ax, [bp+6]
    inc ax
    shl ax, 1
    add di, ax

    ; clear interior
    mov cx, [bp-6]
    mov ax, 0720h
    cld
    rep stosw

    inc word [bp-2]
    jmp scroll_clear_row

scroll_done:
    pop ds                  ; restore DS
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax

    mov sp, bp
    pop bp
    ret 10


;  FIND AND HIGHLIGHT 

; [bp+4] keyword offset
; [bp+6] attribute
;
; rows 4 to 20
; text from column 10
; last text column 70
;
; [bp-2] row
; [bp-4] keyword length
; [bp-6] match count
; [bp-8] max byte offset
;
; SI keyword pointer
; DI video position

find_and_highlight:
    push bp
    mov bp, sp
    sub sp, 8

    push ax
    push bx
    push cx
    push dx
    push si
    push di

    cld

    mov word [bp-2], 0
    mov word [bp-4], 0
    mov word [bp-6], 0
    mov word [matches], 0

    ; keyword length
    mov si, [bp+4]

keyword_length_loop:
    cmp byte [si], 0
    je keyword_length_done

    inc word [bp-4]
    inc si
    jmp keyword_length_loop

keyword_length_done:
    ; empty keyword
    cmp word [bp-4], 0
    jne kw_ok1
    jmp search_finished

kw_ok1:

    ; max 61 chars
    cmp word [bp-4], 61
    jbe kw_ok2
    jmp search_finished
kw_ok2:

    ; max start column
    mov ax, 71
    sub ax, [bp-4]
    shl ax, 1
    mov [bp-8], ax

    ; start row 4
    mov word [bp-2], 4

search_row:
    cmp word [bp-2], 21
    jb row_ok
    jmp search_finished
row_ok:

    ; row start
    mov ax, [bp-2]
    mov bx, 160
    mul bx
    add ax, 20
    mov di, ax

search_position:
    ; offset in row
    mov ax, di
    mov bx, 160
    xor dx, dx
    div bx

    cmp dx, [bp-8]
    jbe pos_ok
    jmp search_next_row
pos_ok:

    ; save candidate
    push di
    push dx

    ; reset keyword
    mov si, [bp+4]
    mov cx, [bp-4]

compare_keyword:
    ; compare
    cmpsb
    je cmp_ok
    jmp search_no_match
cmp_ok:

    ; skip attribute
    inc di

    ; until all match
    loop compare_keyword

    ; full match
    pop dx
    pop di
    push di

    ; highlight attributes
    mov cx, [bp-4]
    mov si, di
    mov al, [bp+6]

highlight_loop:
    mov byte [es:si+1], al
    add si, 2
    loop highlight_loop

    ; count match
    inc word [bp-6]

    ; next start
    pop di
    add di, 2
    jmp search_position

search_no_match:
    ; restore
    pop dx
    pop di

    ; next char
    add di, 2
    jmp search_position

search_next_row:
    inc word [bp-2]
    jmp search_row

search_finished:
    mov ax, [bp-6]
    mov [matches], ax

    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax

    mov sp, bp
    pop bp
    ret 4


; ---- PRINT NUMBER ----

; [bp+4] number
; recursive
; position in outpos

printNum:
    push bp
    mov bp, sp
    sub sp, 2

    push ax
    push bx
    push dx
    push di

    ; divide by 10
    mov ax, [bp+4]
    mov bx, 10
    xor dx, dx
    div bx

    ; last digit
    mov [bp-2], dx

    ; print higher digits first
    cmp ax, 0
    je print_digit

    push ax
    call printNum

print_digit:
    mov di, [outpos]
    mov al, byte [bp-2]
    add al, '0'
    mov ah, 0Fh
    stosw
    mov [outpos], di

    pop di
    pop dx
    pop bx
    pop ax

    mov sp, bp
    pop bp
    ret 2