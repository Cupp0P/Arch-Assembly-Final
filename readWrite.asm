; Main Console program
; Wayne Cook
; 10 March 2024
; Show how to do input and output
; Revised: WWC 14 March 2024 Added new module
; Revised: WWC 15 March 2024 Added this comment ot force a new commit.
; Revised: WWC 13 September 2024 Minor updates for Fall 2024 semester.
; Revised: WWC 23 September 2024 Split to have main, utils, & program.
; Revised: WWC 4 October 2024 Make writeNumber a recursive call.
; Revised: JB  4 November 2024 Added headers
; Revised: JB  8 November 2024 Updated headers and comments
; Register names:
; Register names are NOT case sensitive eax and EAX are the same register
; x86 uses 8 registers. EAX (Extended AX register has 32 bits while AX is
;	the right most 16 bits of EAX). AL is the right-most 8 bits.
; Writing into AX or AL effects the right most bits of EAX.
;		EAX - caller saved register - usually used for communication between
;			caller and callee.
;		EBX - Callee saved register
;		ECX - Caller saved register - Counter register 
;		EDX - Caller Saved register - data, I use it for saving and restoring
;			the return address
;		ESI - Callee Saved register - Source Index
;		EDI - Callee Saved register - Destination Index
;		ESP - Callee Saved register - stack pointer
;		EBP - Callee Saved register - base pointer.386P
; 
; Routines:
;	initialize_console()						--	79
;	readline()									--	106
;	charCount(addr)								--	135
;	writeline(addr, chars)						--	173
;	writeNumber(number)							--	209
;	genNumber(number, pointer to ASCII buffer)	--	252
; 
; For Comments:
;	[--] means -4 bytes from ESP	(Add item to stack)
;		[-*#] means -(#*4) bytes from ESP
;	[++] means +4 bytes to ESP		(Remove item from stack)
;		[+*#] means +(#*4) bytes to ESP
; Comments on process end lines:
;	[ESP+-=bytes added/taken (Net change * 4)], Whether all parameters were
;			removed from stack [+- net # item removed/added to stack]


.model flat

; Library calls used for input from and output to the console
extern	_GetStdHandle@4:	near
extern	_WriteConsoleA@20:	near
extern	_ReadConsoleA@20:	near
extern	_ExitProcess@4:		near

.data

msg				byte	"Hello, World", 10, 0			; ends with line feed (10) and NULL
prompt			byte	"Please type your name: ", 0	; ends with string terminator (NULL or 0)
results			byte	10,"You typed: ", 0
space			byte	" ",0
outputHandle	dword	?		; Output handle writing to consol. uninitslized
inputHandle		dword	?		; Input handle reading from consolee. uninitslized
written			dword	?
INPUT_FLAG		equ		-10
OUTPUT_FLAG		equ		-11

; Reading and writing requires buffers. I fill them with 00h.
readBuffer		byte	1024		DUP(00h) 
writeBuffer		byte	1024		DUP(00h)
numberBuffer	byte	1024		DUP(00h)
numCharsToRead	dword	1024
numCharsRead	dword	1024


.code

;;******************************************************************;
;; Call initialize_console()
;; Parameters:		None
;; Returns:			Nothing
;; Registers Used:	EAX
;; 
;; Initialize Input and Output handles so you only have to do that 
;;		once.
;; This is your first assembly routine
;; 
;; 
;; This process sets up the console by storing the handles to the 
;;		Input and the Output in inputHandle and outputHandle 
;;		respectively. The process gets the output handle from pushing 
;;		the OUTPUT_FLAG (-11) to _GetStdHandle@4 which returns the 
;;		output handle in EAX. Likewize, the input handle is retrieved 
;;		by pushing the INPUT_FLAG (-10) to _GetStdHandle@4 which 
;;		returns the input handle in EAX. Since inputHandle and 
;;		outputHandle are stored in the memory, they can be retrieved 
;;		by other processes to get input from inputHandle or write 
;;		strings to outputHandle. This process had no parameters to 
;;		remove from the stack. This process only needs to be called 
;;		once (preferably when the program starts) to set up the 
;;		handles.
;; 
;; 
;; call initialize_console
;; 
;; Procedure removes all parameters from the stack.
;;******************************************************************;
initialize_console PROC near
_initialize_console:
	; handle = GetStdHandle(-11)
	push  OUTPUT_FLAG			; [--]
	call  _GetStdHandle@4		; [--] [+*2]
	mov   outputHandle, eax
	; handle = GetStdHandle(-10)
	push  INPUT_FLAG			; [--]
	call  _GetStdHandle@4		; [--] [+*2]
	mov   inputHandle, eax
	ret							; [++]
initialize_console ENDP			; [ESP+=4], Parameters removed from stack [++]


;;******************************************************************;
;; Call readline()
;; Parameters:		None
;; Returns:			EAX - ptr to buffer
;; Registers Used:	EAX
;; 
;; Now the read/write handles are set, read a line
;; 
;; 
;; This process has no parameters. Instead it uses the
;;		_ReadConsoleA@20 library to get text input from the user via 
;;		the console referenced in the inputHandle. The library has 5 
;;		parameters. The first parameter pushed is the null character, 
;;		or the string terminator. The second parameter is the address 
;;		of a buffer to hold the number of chars read. The third 
;;		parameter is the max amount of chars to read from the handle. 
;;		The fourth parameter is the address of the buffer to store 
;;		the read input in. The fifth parameter holds the handle the 
;;		input is being read from. ReadConsoleA@20 stores the inputted 
;;		string in readBuffer. The address to the string is stored in 
;;		EAX which can then be used by the caller.
;; 
;; 
;; call  readline()
;; 
;; Procedure removes all parameters from the stack.
;;******************************************************************;
readline PROC near
_readline:
	  ; ReadConsole(handle, &buffer, numCharToRead, numCharsRead, null)
	push  0						; Null [--]
	push  offset numCharsRead	; Number of characters read (1024) [--]
	push  numCharsToRead		; Number of characters to read (1024) [--]
	push  offset readBuffer		; Buffer to hold input in [--]
	push  inputHandle			; Handle for input [--]
	call  _ReadConsoleA@20		; Get input [--] [+*6]
	mov   eax, offset readBuffer	    ; Move readBuffer to EAX
	ret							; Return input in EAX [++]
readline ENDP					; [ESP+=4], Parameters removed from stack [++]


;;******************************************************************;
;; Call charCount(addr)
;; Parameters:		addr - address of buffer = &addr[0]
;; Returns:			EAX - character count
;; Registers Used:	EAX, EBX, ECX, EDX
;; 
;; All strings need to end with a NULL (0). So I do not have to 
;;		manually count the number of characters in the line, I wrote 
;;		this routine.
;; 
;; 
;; This process counts the number of character in a string. It pops 
;;		the address of buffer containing the string to be counted 
;;		into EBX. EAX is used as the counter, and ECX is used to pull 
;;		individual characters from the buffer to count them and check 
;;		for the string terminator. The process goes through a loop to 
;;		pull each character from EBX into the last 8 bits of ECX, 
;;		checks if the character is the string terminator (0), 
;;		increments EAX and increments EBX to the next character. If 
;;		the pulled character is the string terminator, the loop is 
;;		terminated and the process returns to the caller with the 
;;		character count in EAX. All parameters are removed from the 
;;		stack, so no adjustments to ESP are needed.
;; 
;; 
;; push  addr
;; call  charCount
;; 
;; Procedure removes all parameters from the stack.
;;******************************************************************;
charCount PROC near
_charCount:
	pop   edx					; Save return address [++]
	pop   ebx					; save offset/address of string [++]
	push  edx					; Put return address back on the stack [--]
	mov   eax,0					; load counter to 0
	mov   ecx,0					; Clear ECX register
_countLoop:
	mov   cl,[ebx]				; Look at the character in the string
	cmp   cl,0					; check for end of string.
	je    _endCount
	inc   eax					; Up the count by one
	inc   ebx					; go to next letter
	jmp   _countLoop
_endCount:
	ret							; Return with EAX containing character count [++]
charCount ENDP					; [ESP+=8], Parameter removed from stack [+*2]


;;******************************************************************;
;; Call writeline(addr, chars) - push parameter in reverse order
;; Parameters:		addr - address of buffer = &addr[0]
;;					chars - character count in the buffer
;; Returns:			Nothing
;; Registers Used:	EAX, EBX, EDX
;; 
;; For all routines, the last item to be pushed on the stack is the 
;;		return address, save it to a register then save any other 
;;		expected parameters in registers, then restore the return
;;		address to the stack.
;; 
;; 
;; This routine has two parameters. The first parameter, addr, is 
;;		stored in EBX. The second parameter, chars, is stored in EAX. 
;;		addr is the address of the string to write to the console, 
;;		chars is the number of characters in the string. 
;;		_WriteConsoleA@20 is used to write to the console and it 
;;		takes 5 parameters. The first parameter pushed is the 
;;		character being used as null, or the string terminator. The 
;;		second parameter is a buffer to hold the characters written. 
;;		The third parameter is the number of chars to write, or chars. 
;;		The fourth parameter is the address of the buffer holding the 
;;		string to be written. The fifth parameter is the handle to 
;;		write to. All parameters are removed from the stack so no 
;;		adjustments to ESP are needed.
;; 
;; 
;; push  chars
;; push  addr
;; call  writeline
;; 
;; Procedure removes all parameters from the stack.
;;******************************************************************;
writeline PROC near
_writeline:
	pop   edx					; pop return address from the stack into EDX [++]
	pop   ebx					; Pop the buffer location of string to be printed into EBX [++]
	pop   eax					; Pop the buffer size string to be printed into EAX. [++]
	push  edx					; Restore return address to the stack [--]


	; WriteConsole(handle, &msg[0], numCharsToWrite, &written, 0)
	push  0						; [--]
	push  offset written		; [--]
	push  eax					; return size to the stack for the call to _WriteConsoleA@20 (20 is how many bits are in the call stack) [--]
	push  ebx					; return the offset of the line to be written [--]
	push  outputHandle			; [--]
	call  _WriteConsoleA@20		; [--] [+*6]
	ret							; [++]
writeline ENDP					; [ESP+=12], Parameters removed from stack [+*3]


;;******************************************************************;
;; Call writeNumber(number)
;; Parameters:		number - decimal number to translate
;; Returns:			Nothing
;; Registers Used:	EAX, EBX, EDX, ESP
;; 
;; Takes a DD integer and writes it to the console as ASCII characters
;; writeNumber(number) was divided so genNumber could be a recursive 
;;		procedure
;; Uses the genNumber(number)
;; 
;; 
;; This process writes a number to the console. It has one parameter, 
;;		number, which is popped from the stack into EBX. The program 
;;		starts by using genNumber to convert the digits in number to 
;;		ASCII characters, which are then stored in the numberBuffer 
;;		that was pushed to the stack for genNumber. Since genNumber 
;;		does not remove all the parameters to the stack, 8 bytes are 
;;		added to ESP. Now that the number has been translated into a 
;;		string, the string is pushed to the stack so charCount can be 
;;		used to count the number of characters in the string. The 
;;		amount of characters is stored in EAX by charCount, so EAX is 
;;		pushed to the stack, along with the pointer to numberBuffer, 
;;		to be used by writeline to write the number to the output 
;;		handle. Finally a space with a length of 1 is pushed to the 
;;		stack to write a space to the output handle using writeline. 
;;		All parameters have been removed from the stack, so no 
;;		adjustment to ESP is needed.
;; 
;; 
;; push  number
;; call  writeNumber
;; 
;; Procedure removes all parameters from the stack.
;;******************************************************************;
writeNumber PROC near
	pop   edx					; pop return address from the stack into EDX [++]
	pop   ebx					; Pop the number to be printed into EBX [++]
	push  edx					; Restore return address to the stack [--]
	push  offset numberBuffer	; Supplied buffer where number is written. [--]
	push  ebx					; and the number to be printed. [--]
	call  genNumber				; Generate the number [--] [++]
	add   esp, 8				; Remove both parameters. [+*2]
	push  offset numberBuffer	; Supplied buffer where number is written. [--]
	call  charCount				; Count the number of chars in ASCII number [++]
	push  eax					; Return count in EAX [--]
	push  offset numberBuffer	; [--]
	call  writeline				; Write the number. [--] [+*3]
	push  1						; [--]
	push  offset space			; [--]
	call  writeline				; [--] [+*3]
	ret							; And it is time to exit. [++]
writeNumber ENDP				; [ESP+=8], Parameters removed from stack [+*2]


;;******************************************************************;
;; Call genNumber(number, pointer to ASCII buffer)
;; Parameters:		number - decimal number to be converted to ASCII
;;					pointer to ASCII buffer - Address of buffer where 
;;						to store generated ASCII number
;; Returns:			ASCII buffer in parameters has generated ASCII 
;;						number.
;; Registers Used:	EAX (s), EBX, ECX (s), EDX (s), EBP (s), ESP (s),
;;					EDI (s), ESI (s)
;; 
;; genNumber(number, pointer to ASCII buffer) create the ASCII value
;;	 of a number.
;; To help callers, I will save all registers, except eax, which 
;;	 will be location in number ASCII string to be written. This 
;;	 routine will show the official way to handle the stack and base 
;;	 pointers. It is less effecient, but it preserves all registers.
;; 
;; 
;; This process is used to translate a number to a string of ASCII 
;;		characters. This process is recursive, so care should be 
;;		taken to ensure there is not a stack overflow. This process 
;;		has two parameters: the number to translate, and the pointer 
;;		to a buffer to store the resulting string in. Both parameters 
;;		are accessed using EBP but are not removed from the stack. 
;;		The pointer that ESP contains at the start is stored in EBP 
;;		so that the parameters can be accessed, and so ESP can be 
;;		restored back to its inital value at the end so the return 
;;		address is not buried. Each recursive iteration, EAX is used 
;;		to hold the dividend which is the current number held in the 
;;		stack. If EAX equals 0, the recursive loop will end, EBX is 
;;		used to hold the pointer to the buffer. ECX is used to divide 
;;		the value held in EAX by 10 to remove the least significant 
;;		digit from the number to get ready to translate the next 
;;		digit. The least significant digit removed by the divide is 
;;		stored in EDX. The value in DX is then added to value of the 
;;		ASCII value for '0' to force translate the digit into ASCII. 
;;		The next recursive iteration is then called with the same 
;;		buffer address, but the number is set to the dividend stored 
;;		in EAX. Once the last iteration is reached, each iteration 
;;		will append the character they have stored in DX to the end 
;;		of the buffer, and EBX will be incremented to get ready for 
;;		the next iteration to appends its character. DX will then be
;;		set to a terminating null and appended to EBX. The working 
;;		registers are then restored and ESP is set back to the value 
;;		it had at the start of the routine. Finally the program 
;;		returns to the caller. The parameters are not removed from 
;;		the stack, so ESP needs to be adjusted by adding 8 bytes to 
;;		it. The resultant string will be stored in the buffer that 
;;		was passed to the stack as a parameter for genNumber.
;; 
;; 
;; push  pointer to ASCII buffer
;; push  number
;; call  genNumber
;; add   esp, 8					; Remove the two parameters
;;******************************************************************;
genNumber PROC near
_genNumber:
	; Subroutine Prologue
	push  ebp					; Save the old base pointer value. [--]
	mov	  ebp, esp				; Set the new base pointer value to access parameters [EBP = ESP-=4]
	sub   esp, 4				; Make room for one 4-byte local variable, if needed [--]
	push  edi					; Save the values of registers that the function [--]
	push  esi					; will modify. This function uses EDI and ESI. [--]
	; The eax, ebx, ecx, edx registers do not need to be saved,
	;		but they are for the sake of the calling routine.
	push  eax					; EAX needed as a dividend [--]
	;push  ebx					; Only save if not used as a return value [--]
	push  ecx					; Ditto [--]
	push  edx					; Ditto [--]
	; Subroutine Body
	mov   eax, [ebp+8]			; Move number value to be converted to ASCII
	mov   ebx, [ebp+12]			; The start of the generated ASCII buffer for storage
	mov   ecx, 10				; Set the divisor to ten
	;mov   esi, 0				; Count number of numbers written
;; The dividend is place in eax, then divide by ecx, the result goes into eax, with the remiander in edx
	cmp   eax, 0				; Stop when the number is 0
	jle   numExit
	mov   edx, 0				; Clear the register for the remainder
	div   ecx					; Do the divide
	add   dx,'0'				; Turn the remainer into an ASCII number
	;push  dx					; Now push the remainder onto the stack
	;inc   esi					; increment number count
;; Do another recursive call;
	push  ebx					; Pass on the start of the number buffer. [--]
	push  eax					; And the number [--]
	call  genNumber				; ******Do the recursion***** [--] [++]
	add   esp, 8				; Remove the two parameters [+*2]
;; Load the number, one digit at a time.
	mov   [ebx], dx				; Add the number to the output sring
	inc   ebx					; go to the next ASCII location
	mov   dx, 0					; cannot load a literal into an addressed location
	mov   [ebx], dx				; Add a terminating NULL to the end of the number
	
numExit:
	
	; If eax is used as a return value, make sure it is loaded by now.
	; And restore all saved registers
	; Subroutine Epilogue
	pop   edx					; [++]
	pop   ecx					; [++]
	;pop   ebx					; [++]
	pop   eax					; [++]
	pop   esi					; Recover register values [++]
	pop   edi					; [++]
	mov   esp, ebp				; Deallocate local variables [ESP-=4]
	pop   ebp					; Restore the caller's base pointer value [++]
	ret							; [++]
genNumber ENDP					; [ESP+=4], 2 Parameters left on stack [++]

END