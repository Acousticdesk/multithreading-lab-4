; WIN32 Lab 4
; By Andrii Kicha 23.11.2022

.386
.MODEL flat, stdcall

; akicha added
ExitProcess proto, dwExitCode:DWORD
Sleep proto, dwMilliseconds:DWORD
GetModuleHandleA proto, lpModuleName:DWORD ; get a handle to the .exe file that executes the process

.data
	note db 'Note',0
	noteClassName db 'NOTECLASS',0
	editClassName db 'EDIT',0
	editHandle dd 0
	; akicha added
	editMessage db ?
	saveFileName db 'backup.txt', 0
	saveFileBytesWritten db 0

.code
	autosave PROC:
		asloop:

		push eax ; save the old value of eax because it will be erase by the procedure calls

		; get text typed by the user
		; arguments for the GetWindowTextA procedure
		push 1024 ; length to write to a buffer
		push offset editMessage ; buffer
		push dword ptr [editHandle] ; edit window handle
		; 12 bytes total
		
		call GetWindowTextA

		add esp, 12 ; clean 12 bytes from the call stack

		; open or create a file
		; arguments for the CreateFile procedure
		push 0
		push 80h ; FILE_ATTRIBUTE_NORMAL
		push 2 ; CREATE_ALWAYS
		push 0 ; default security
		push 0 ; do not share
		push 40000000h ; GENERIC_WRITE
		push offset saveFileName
		; 28 bytes total

		call CreateFile ; eax register now contains the address memory to the handle to the file

		add esp, 28 ; clean 28 bytes of arguments for CreateFile procedure

		; save the contents to the file
		; arguments for the WriteFile procedure
		push 0 ; no overlapped files
		push saveFileBytesWritten ; address memore as to where to store the bytes written
		push 1024 ; buffer length
		push offset editMessage ; address memory where the buffer is stored
		push eax ; file handle

		call WriteFile

		push 600000 ; ms in 10 minutes
		call Sleep
		add esp, 4 ; 4 bytes - remove the Sleep arguments from the call stack
		
		pop eax ; restore the old value of the eax register
		
		jmp asloop
	autosave ENDP

	noteClass :
	dd 0 ; style
	dd NoteWindowProc
	dd 0 ; cbClsExtra
	dd 0 ; cbWndExtra
	nc_hInstance dd 0 ; hInstance
	dd 0 ; hIcon
	dd 0 ; hCursor
	dd 5 ; hbrBackground
	dd 0 ; lpszMenuName
	dd noteClassName

	; akicha question
	message :
	dd ? ; hwnd
	dd ? ; message
	dd ? ; wParam
	dd ? ; lParam
	dd ? ; time
	dd ? ; pt.x
	dd ? ; pt.y
	dd ?

	rect :
	r_left dd ?
	r_top dd ?
	r_right dd ?
	r_bottom dd ?

	EntryPoint :
	push 0 ; lpModuleName
	; akicha question, can we just use call GetModuleHandleA?
	call dword ptr [GetModuleHandleA] ; kernel32.dll

	; akicha question, can't we just use "mov nc_hInstance, eax"?
	; akicha question, what is the nc_hInstance
	mov dword ptr [nc_hInstance ], eax
	push offset noteClass
	call dword ptr [RegisterClassA] ; user32.dll

	push 0 ; hInstance
	push dword ptr [nc_hInstance ]
	push 0 ; hMenu
	push 0 ; hWndParent
	push 200 ; nHeight
	push 300 ; nWidth
	push 100 ; Y
	push 100 ; X
	push 10CF0000h ; WS_VISIBLE | WS_OVERLAPPEDWINDOW
	push offset note
	push offset noteClassName
	push 0 ; dwExStyle
	call dword ptr [CreateWindowExA] ; user32.dll

	; akicha question, when this loop starts the iteration?
	LoopStart :
	push 0 ; wMsgFilterMax
	push 0 ; wMsgFilterMin
	push 0 ; hWnd
	push offset message
	call dword ptr [GetMessageA] ; user32.dll
	cmp eax, 1
	jb Quit
	jne LoopStart

	push offset message
	call dword ptr [TranslateMessage] ; user32.dll

	push offset message
	call dword ptr [DispatchMessageA] ; user32.dll
	jmp LoopStart

	Quit :
	push 0
	call dword ptr [ExitProcess] ; kernel32.dll

	; we get here after the DispatchMessageA call
	NoteWindowProc :
	push ebp
	mov ebp, esp
	push ebx
	push esi; akicha question, what is the purpose in using the esi and edi registers?
	push edi
	mov eax, dword ptr [ebp+0Ch] ; uMsg
	cmp eax, 1 ; WM_CREATE
	je OnCreate
	cmp eax, 5 ; WM_SIZE
	je OnSize
	cmp eax, 2 ; WM_DESTROY
	je OnDestroy
	jmp OnOther

	OnCreate :
	push offset rect
	push dword ptr [ebp+8] ; hwnd
	call dword ptr [GetClientRect] ; user32.dll
	push 0 ; lpParam
	push dword ptr [nc_hInstance ]
	push 0 ; hMenu
	push dword ptr [ebp+8] ; hWndParent
	push dword ptr [r_bottom ] ; nHeight
	push dword ptr [r_right ] ; nWidth
	push dword ptr [r_top ] ; Y
	push dword ptr [r_left ] ; X
	push 503000C4h ; WS_VISIBLE | WS_CHILD | ES_MULTILINE ... akicha question, how did we come up with this value?
	push 0 ; lpWindowName
	push offset editClassName
	push 0 ; dwExStyle
	call dword ptr [CreateWindowExA] ; user32.dll
	; akicha question
	mov dword ptr [editHandle ], eax
	xor eax,eax

	; akicha added

	; CreateThreadA arguments (reverse order)
	push 0 ; pointer to save the trhread id (no need in our case)
	push 0 ; default creational flags
	push 0 ; no arguments that need to be sent to the autosave procedure
	push offset autosave ; pointer to the austosave procedure location
	push 0 ; stack size, use the default one - pass 0
	push 0 ; security flags
		   ; total 24 bytes

	call CreateThreadA
	add esp, 24 ; clean 24 bytes from the call stack

	jmp Return

	OnSize :
	push offset rect
	push dword ptr [ebp+8] ; hwnd
	call dword ptr [GetClientRect] ; user32.dll
	push 1
	push dword ptr [r_bottom ] ; nHeight
	push dword ptr [r_right ] ; nWidth
	push dword ptr [r_top ] ; Y
	push dword ptr [r_left ] ; X
	push dword ptr [editHandle ] ; hWnd
	call dword ptr [MoveWindow] ; user32.dll
	xor eax,eax
	jmp Return

	OnDestroy :
	push 0 ; nExitCode
	call dword ptr [PostQuitMessage] ; user32.dll
	xor eax,eax
	jmp Return
	
	OnOther :
	push dword ptr [ebp+14h] ; lParam
	push dword ptr [ebp+10h] ; wParam
	push dword ptr [ebp+0Ch] ; uMsg
	push dword ptr [ebp+8] ; hwnd
	call dword ptr [DefWindowProcA] ; user32.dll
	jmp Return

	Return :
	pop edi
	pop esi
	pop ebx
	leave
	ret 10h

END main