.586
.model flat,stdcall
option casemap:none

   include windows.inc
   include user32.inc
   include kernel32.inc
   
   includelib user32.lib
   includelib kernel32.lib
   
   assume fs:nothing

node struc
	Next dd 0
	Handle dd 0
node ends

.data
	g_sz1 db "ExceptHandle1", 0
	g_sz2 db "ExceptHandle2", 0

.code


; 回调函数
ExceptHandle1 proc pER:ptr EXCEPTION_RECORD, pEF:LPVOID, pCR:ptr CONTEXT, pDC:LPVOID
	
	mov esi, pER
	mov edi, pCR
	assume esi:ptr EXCEPTION_RECORD
	assume edi:ptr CONTEXT
	
	invoke MessageBox, NULL, offset g_sz1, NULL, MB_OK
	.if [esi].ExceptionCode == EXCEPTION_INT_DIVIDE_BY_ZERO
		add [edi].regEip, 2
		mov eax, ExceptionContinueExecution
		ret
	.endif
	
	mov eax, ExceptionContinueSearch
	ret

ExceptHandle1 endp

ExceptHandle2 proc pER:ptr EXCEPTION_RECORD, pEF:LPVOID, pCR:ptr CONTEXT, pDC:LPVOID
	
	invoke MessageBox, NULL, offset g_sz2, NULL, MB_OK
	
	mov eax, ExceptionContinueSearch
	ret

ExceptHandle2 endp

Foo2 proc
	LOCAL @node:node
	
	; 注册回调函数
	push offset ExceptHandle2
	push fs:[0]
	mov fs:[0], esp

	
	; 产生异常
	xor eax, eax
	div eax
	
	; 删除SEH
	pop fs:[0]
	
	ret

Foo2 endp


Foo1 proc
	LOCAL @node:node
	
	; 注册回调函数
	push offset ExceptHandle1
	push fs:[0]
	mov fs:[0], esp

	
	invoke Foo2
	
	; 产生异常
	mov eax, 15h
	mov [eax], eax
	
	; 删除SEH
	pop fs:[0]
	
	ret

Foo1 endp


start:
	
	invoke Foo1
	
	invoke ExitProcess, 0

end start
