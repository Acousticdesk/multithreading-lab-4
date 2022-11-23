; WIN32 Lab 4
; By Andrii Kicha 23.11.2022

.386
.MODEL flat, stdcall

ExitProcess proto, dwExitCode:DWORD

; akicha added
GetModuleHandleA proto, lpModuleName:DWORD

.data
	note db 'Note',0
	noteClassName db 'NOTECLASS',0
	editClassName db 'EDIT',0
	editHandle dd 0

.code
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
	call dword ptr [GetModuleHandleA] ; kernel32.dll
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

	NoteWindowProc :
	push ebp
	mov ebp, esp
	push ebx
	push esi
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
	push 503000C4h ; WS_VISIBLE | WS_CHILD | ES_MULTILINE ...
	push 0 ; lpWindowName
	push offset editClassName
	push 0 ; dwExStyle
	call dword ptr [CreateWindowExA] ; user32.dll
	mov dword ptr [editHandle ], eax
	xor eax,eax
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