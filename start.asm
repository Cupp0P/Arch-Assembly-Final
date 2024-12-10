; Decimal to Binary Converter
; Thomas Orozco
; Dec 9, 2024
; Converts a user inputted decimal to binary
.386P
.model flat

extern initialize_console: near
extern writeline: near
extern readline: near
extern charCount: near
extern writeNumber: near
extern   _ExitProcess@4: near


.data
decOut dd 0 ;;What the user inputs
errorFlag dd 0 ;; Allows other functons to see if a error has been raise
twoMult dd 1 ;;Initialized at one so it maybe multiplied will be divisor for binary conversion

;;Message variables
welcomeMsg db "Hello! Please enter a positive decimal number to convert to binary: ", 10, 0
decMsg db "Decimal: ", 0
binMsg db 10, "Binary: ", 0
overflowErrorMsg db 10, "Inputted number too large please reset and select something under 1,000,000,000", 10,0
zeroMsg db "0",0
oneMsg db "1",0

.code
;; Converts the string readLine outputs into a integer so it can be worked
;; Traverses string then decriments the ascii by 48 and then passes it to decOut
toInt PROC near
_toInt:
	mov esi, eax
	mov eax,0
	push esi
	;; weird registers use to keep the writeLine buffer from being overwritten
	;; eax will be the number of digits in the string it will then be used to in the toIntLoop to count when its done running
	call charCount
	mov ecx, esi
	mov esi, 0
	mov ebx, 0
	sub eax, 3
	cmp eax, 10
	jg _overflowError ;;if a number greater then 1,000,000,000 is inputted it overflows the register and causes errors so we reject it
	mov edx, 1
	;;Moves the strng to bl then converts from ascii to int and then multiplies it by edx which counts which space its int and then adds it to
	;;dec out
	toIntLoop:
		mov bl, [ecx+eax]
		sub bl, 48
		imul ebx, edx
		add decOut, ebx
		mov ebx, 0
		imul edx, 10
		cmp eax, 0
		je _outIntLoop
		dec eax
		jmp toIntLoop
	;;Loop End
	;;triggers overflow error and resets the function and asks for another input
	_overflowError:
		push offset overflowErrorMsg
		call charCount
		push eax
		push offset overflowErrorMsg
		call writeLine
		mov errorFlag, 1
		mov ecx, 0
		ret
		;;END ERROR
	
	_outIntLoop:

	;;this little section write the string 0 since int 0 is null and write no character for if the input is 0
	cmp decOut, 0
	jg _notZero
	call writeZero
	ret

	_notZero:
	ret
toInt ENDP

;; Write the string 0
writeZero PROC near
_writeZero:
	push 1
	push offset zeroMsg
	call writeLine
	ret
writeZero ENDP

;;write the string 1
writeOne PROC near
_writeOne:
	push 1
	push offset oneMsg
	call writeLine
	ret
writeOne ENDP

;;======================================================================
start PROC near
_start:

;;write welcome message
push offset welcomeMsg
call charCount
push eax
push offset welcomeMsg
call writeLine

;;main loop that reads wahat the input is, checks if its valid and changes it to a str
_fromselect:
	mov eax, 0
	mov errorFlag, 0
	call readLine
	call toInt
	cmp errorFlag, 1
	je _end ;;trouble with the readLine function forced me to end the program if a overflow error occurs

	;; writes the decimal and the "Binary: " part of the output
	push offset decMsg
	call charCount
	push eax
	push offset decMsg
	call writeLine
	push decOut
	call writeNumber
	push offset binMsg
	call charCount
	push eax
	push offset binMsg
	call writeLine
	jmp binZeroSkip

;; Name is holdover from old prototype this is the section that reads the decimal and writes out 1s and 0s
binZeroSkip:
mov ebx, 1
mov eax, decOut
;;The set loop inciments twoMult by multiplying it by two until the result is greater then the input then return it to the last twoMult
binSetLoop:
	sub eax, ebx
	cmp eax, 0
	mov twoMult, ebx
	jle _setLoopEnd
	imul ebx, 2
	jmp binSetLoop
	_setLoopEnd:

;;Main loop subtracks the twoMult by the input and checks if its less then 0, then divides the twoMult by 2 until it equals 0
binBuildLoop:
	mov eax, twoMult
	mov ebx, decOut
	mov ecx, 2
	mov edx, 0

	sub ebx, eax
	mov twoMult, eax
	;; if ebx is greater then 0 it saves the decimented input and writes a 1 if its less it discards the decriments and write a 0
	cmp ebx, 0
	jge _buildOne
	call writeZero
	jmp _loopReset
	
	;;called if a 1 is needed
	_buildOne:
	mov decOut, ebx
	call writeOne
	jmp _loopReset

	;;Resets the registers for the next run of the loop, may be excessive but it works
	_loopReset:
	mov eax, twoMult
	mov ebx, decOut
	mov ecx, 2
	mov edx, 0
	cdq
	idiv ecx
	mov twoMult, eax
	cmp edx, 0
	je binBuildLoop 

	_outBinBuildLoop:
	;;ENDLOOP

	_end:

start ENDP
	


END