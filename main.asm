; Main program
; Wayne Cook
; 29 February 2024
; Controls the flow of the program
; Revised: WWC 14 March 2024 Added new module
; Revised 15 March 2024 Added this comment ot force a new commit.
; Revised: WWC 25 April 2024 Split out the console control into second file.
; Revised: WWC 13 September 2024 Minore updates for Fall 2024 semester.
; Register names:
; Register names are NOT case sensitive eax and EAX are the same register
; x86 uses 8 registers. EAX (Extended AX register has 32 bits while AX is the right most 16 bits of EAX). AL is the right-most 8 bits.
; Writing into AX or AL effects the right most bits of EAX.
;     EAX - caller saved register - usually used for communication between caller and callee.
;     EBX - Callee saved register
;     ECX - Caller saved register - Counter register 
;     EDX - Caller Saved register - data, I use it for saving and restoring the return address
;     ESI - Callee Saved register - Source Index
;     EDI - Callee Saved register - Destination Index
;     ESP - Callee Saved register - stack pointer
;     EBP - Callee Saved register - base pointer

.386P

.model flat
extern  _ExitProcess@4: near
extern initialize_console: near
extern start: near

.code

main PROC near
_main:
	;; Call initialize_console() - No Parameters, no return value
	call initialize_console
	;; Call start() - No Parameters, no return value
	call start
	;; ExitProcess(uExitCode)
	push 0
    call  _ExitProcess@4
main ENDP
END