; #########################################################################
;
;                              GDI Animate
;
; This is a simple example of a GDI based animation technique. It uses the
; API function BitBlt to read different portions of a double bitmap and
; displays them on the client area of the window. The function is fast
; enough with a small bitmap to need a delay between each BLIT and the
; logic used is to have a double bitmap of the same image which is read
; in blocks that step across 1 pixel at a time until the width of the
; bitmap is completely read. This allows a continuous scrolling of the
; bitmap image.

; #########################################################################

      .386
      .model flat, stdcall  ; 32 bit memory model
      option casemap :none  ; case sensitive

.const
        WM_OK   equ     WM_USER+101h
        WM_TIMEOUT equ WM_USER+103h


        include animate.inc   ; local includes for this file
; continuação do .data

        EventStop BOOL FALSE
        ok1             db "Você perdeu!! Seu coco!",0
        timeout      db "Ocorreu time out ",0

.data?

        ThreadID     DWORD ?
        ThreadID1    DWORD ?
        ThreadID2    DWORD ?

        hThread      DWORD ?

        hEventStart  HANDLE ?
        hEventStop   HANDLE ?

        auxiliar     DWORD ?
        cabecacima   DWORD ?
        acertos      DWORD ?
        clicou       DWORD ?
        erros        DWORD ?
        recomecou    DWORD ?


; #########################################################################

.code

start:
      mov auxiliar, 0
      mov cabecacima, 0
      mov acertos,0
      mov erros,0
      mov clicou,0
      mov recomecou,0
    
      invoke GetModuleHandle, NULL
      mov hInstance, eax

      invoke LoadBitmap,hInstance,101
      mov hBmp, eax

      invoke LoadBitmap,hInstance,101
      mov hBmp2, eax

      invoke LoadBitmap,hInstance,102
      mov hBmp3, eax

      invoke GetCommandLine
      mov CommandLine, eax

      invoke WinMain,hInstance,NULL,CommandLine,SW_SHOWDEFAULT
      invoke ExitProcess,eax

; #########################################################################

WinMain proc hInst     :DWORD,
             hPrevInst :DWORD,
             CmdLine   :DWORD,
             CmdShow   :DWORD

      ;====================
      ; Put LOCALs on stack
      ;====================

      LOCAL wc   :WNDCLASSEX
      LOCAL msg  :MSG
      LOCAL Wwd  :DWORD
      LOCAL Wht  :DWORD
      LOCAL Wtx  :DWORD
      LOCAL Wty  :DWORD

      ;==================================================
      ; Fill WNDCLASSEX structure with required variables
      ;==================================================

      invoke LoadIcon,hInst,500    ; icon ID
      mov hIcon, eax

      szText szClassName,"Project_Class"

      mov wc.cbSize,         sizeof WNDCLASSEX
      mov wc.style,          CS_BYTEALIGNWINDOW or CS_BYTEALIGNCLIENT
      mov wc.lpfnWndProc,    offset WndProc
      mov wc.cbClsExtra,     NULL
      mov wc.cbWndExtra,     NULL
      m2m wc.hInstance,      hInst
      mov wc.hbrBackground,  COLOR_BTNFACE+1
      mov wc.lpszMenuName,   NULL
      mov wc.lpszClassName,  offset szClassName
      m2m wc.hIcon,          hIcon
        invoke LoadCursor,NULL,IDC_ARROW
      mov wc.hCursor,        eax
      m2m wc.hIconSm,        hIcon

      invoke RegisterClassEx, ADDR wc

      ;================================
      ; Centre window at following size
      ;================================

      mov Wwd, 240
      ;mov Wht, 400
      mov Wht, 600

      invoke GetSystemMetrics,SM_CXSCREEN
      invoke TopXY,Wwd,eax
      mov Wtx, eax

      invoke GetSystemMetrics,SM_CYSCREEN
      invoke TopXY,Wht,eax
      mov Wty, eax

      invoke CreateWindowEx,WS_EX_LEFT,
                            ADDR szClassName,
                            ADDR szDisplayName,
                            WS_OVERLAPPED or WS_SYSMENU,
                            Wtx,Wty,Wwd,Wht,
                            NULL,NULL,
                            hInst,NULL
      mov   hWnd,eax

      invoke LoadMenu,hInst,600  ; menu ID
      invoke SetMenu,hWnd,eax

      invoke ShowWindow,hWnd,SW_SHOWNORMAL
      invoke UpdateWindow,hWnd

      ;===================================
      ; Loop until PostQuitMessage is sent
      ;===================================

    StartLoop:
      invoke GetMessage,ADDR msg,NULL,0,0
      cmp eax, 0
      je ExitLoop
      invoke TranslateMessage, ADDR msg
      invoke DispatchMessage,  ADDR msg
      jmp StartLoop
    ExitLoop:

      return msg.wParam

WinMain endp


; #########################################################################
WndProc proc hWin   :DWORD,
             uMsg   :DWORD,
             wParam :DWORD,
             lParam :DWORD

    LOCAL var    :DWORD
    LOCAL caW    :DWORD
    LOCAL caH    :DWORD
    LOCAL Rct    :RECT
    LOCAL hDC    :DWORD
    LOCAL hOld   :DWORD
    LOCAL memDC  :DWORD
    LOCAL hDC2   :DWORD
    LOCAL hOld2  :DWORD
    LOCAL memDC2 :DWORD
    LOCAL Ps     :PAINTSTRUCT
    LOCAL buffer1[128]:BYTE  ; these are two spare buffers
    LOCAL buffer2[128]:BYTE  ; for text manipulation etc..

     invoke  GetDC, hWnd
     mov     hDC2,eax

     invoke CreateCompatibleDC,hDC2
     mov memDC2, eax
     invoke SelectObject,memDC2,hBmp
     mov hOld2, eax

    .if uMsg == WM_COMMAND
      .if wParam == 500 && auxiliar == 0 && cabecacima == 1 
            ;invoke PostMessage, hWnd, WM_OK, NULL,NULL
            ;invoke BitBlt,hDC,0,0,80,125,memDC,240,0,SRCCOPY
            inc acertos
            mov clicou, 1
      .elseif wParam == 501 && auxiliar == 3 && cabecacima == 1
            ;invoke PostMessage, hWnd, WM_OK, NULL,NULL
            ;invoke BitBlt,hDC,0,120,80,125,memDC,240,0,SRCCOPY
            inc acertos
            mov clicou, 1
      .elseif wParam == 502 && auxiliar == 6 && cabecacima == 1
            ;invoke PostMessage, hWnd, WM_OK, NULL,NULL
            ;invoke BitBlt,hDC,0,240,80,125,memDC,240,0,SRCCOPY
            inc acertos
            mov clicou, 1
      .elseif wParam == 503 && auxiliar == 1 && cabecacima == 1
            ;invoke PostMessage, hWnd, WM_OK, NULL,NULL
            ;invoke BitBlt,hDC,80,0,80,125,memDC,240,0,SRCCOPY
            inc acertos
            mov clicou, 1
      .elseif wParam == 504 && auxiliar == 4 && cabecacima == 1
            ;invoke PostMessage, hWnd, WM_OK, NULL,NULL
            ;invoke BitBlt,hDC,80,120,80,125,memDC,240,0,SRCCOPY
            inc acertos
            mov clicou, 1
      .elseif wParam == 505 && auxiliar == 7 && cabecacima == 1
            ;invoke PostMessage, hWnd, WM_OK, NULL,NULL
            ;invoke BitBlt,hDC,80,240,80,125,memDC,240,0,SRCCOPY
            inc acertos
            mov clicou, 1
      .elseif wParam == 506 && auxiliar == 2 && cabecacima == 1
            ;invoke PostMessage, hWnd, WM_OK, NULL,NULL
            ;invoke BitBlt,hDC,160,0,80,125,memDC,240,0,SRCCOPY   
            inc acertos 
            mov clicou, 1        
      .elseif wParam == 507 && auxiliar == 5 && cabecacima == 1
            ;invoke PostMessage, hWnd, WM_OK, NULL,NULL
            ;invoke BitBlt,hDC,160,120,80,125,memDC,240,0,SRCCOPY
            inc acertos
            mov clicou, 1
      .elseif wParam == 508 && auxiliar == 8 && cabecacima == 1
            ;invoke PostMessage, hWnd, WM_OK, NULL,NULL
            ;invoke BitBlt,hDC,160,240,80,125,memDC,240,0,SRCCOPY
            inc acertos
            mov clicou, 1
      .elseif wParam == 509 && erros > 3
            mov recomecou,1
            mov erros, 0
            mov acertos, 0
            mov clicou, 0
            mov cabecacima,0
            mov auxiliar,0
            ;invoke PostMessage, hWnd, WM_OK, NULL,NULL     
      .else
            inc erros
      .endif
    .elseif uMsg == WM_OK
        invoke MessageBox, NULL, ADDR ok1, ADDR szDisplayName, MB_OK


    ;======== menu commands ========
    .elseif uMsg == WM_CREATE
        szText RunIt," "
        szText RunIts,"Jogar novamente"

        invoke PushButton,ADDR RunIt,hWin,0,0,80,120,500

        invoke PushButton,ADDR RunIt,hWin,0,120,80,120,501

        invoke PushButton,ADDR RunIt,hWin,0,240,80,120,502

        invoke PushButton,ADDR RunIt,hWin,80,0,80,120,503

        invoke PushButton,ADDR RunIt,hWin,80,120,80,120,504

        invoke PushButton,ADDR RunIt,hWin,80,240,80,120,505

        invoke PushButton,ADDR RunIt,hWin,160,0,80,120,506

        invoke PushButton,ADDR RunIt,hWin,160,120,80,120,507

        invoke PushButton,ADDR RunIt,hWin,160,240,80,120,508

        invoke PushButton,ADDR RunIts,hWin,60,390,120,80,509

; criar thread
        invoke CreateEvent, NULL, TRUE, FALSE,NULL
        mov     hEventStart, eax

        invoke CreateEvent, NULL, TRUE, FALSE,NULL
        mov     hEventStop, eax

        mov     eax, OFFSET ThreadProc
        invoke CreateThread, NULL, NULL, eax, NULL, NORMAL_PRIORITY_CLASS, ADDR ThreadID 
        mov     hThread,eax

    .elseif uMsg == WM_SIZE

    .elseif uMsg == WM_PAINT
        invoke BeginPaint,hWin,ADDR Ps
          mov hDC, eax
        invoke EndPaint,hWin,ADDR Ps
        return 0

    .elseif uMsg == WM_CLOSE

    .elseif uMsg == WM_DESTROY
        invoke PostQuitMessage,NULL
        return 0 
    .endif
    

    invoke DefWindowProc,hWin,uMsg,wParam,lParam

    ret

WndProc endp

; #########################################################################

TopXY proc wDim:DWORD, sDim:DWORD

    shr sDim, 1      ; divide screen dimension by 2
    shr wDim, 1      ; divide window dimension by 2
    mov eax, wDim    ; copy window dimension into eax
    sub sDim, eax    ; sub half win dimension from half screen dimension

    return sDim

TopXY endp

; #########################################################################

PushButton proc lpText:DWORD,hParent:DWORD,
                a:DWORD,b:DWORD,wd:DWORD,ht:DWORD,ID:DWORD

    szText btnClass,"BUTTON"

    invoke CreateWindowEx,0,
            ADDR btnClass,lpText,
            WS_CHILD or WS_VISIBLE,
            a,b,wd,ht,hParent,ID,
            hInstance,NULL

    ret

PushButton endp

; ########################################################################

ThreadProc PROC USES ecx Param:DWORD, hWin:DWORD
    LOCAL var1   :DWORD
    LOCAL var2   :DWORD
    LOCAL var3   :DWORD
    LOCAL aux    :DWORD
    LOCAL hDC    :DWORD
    LOCAL hDC2   :DWORD
    LOCAL hOld   :DWORD
    LOCAL hOld2  :DWORD
    LOCAL memDC  :DWORD
    LOCAL memDC2 :DWORD
    LOCAL rec    :RECT

    RGB 255, 255, 255

    mov ebx, eax


        mov     var1,0
        mov     var2,0
        mov     aux ,0

        .WHILE EventStop == FALSE

            invoke WaitForMultipleObjects,2,ADDR hEventStart, FALSE, 100  ; INFINETE
            .IF eax == -1
               ; erro 
             .elseif eax == 0 
                  ; aqui codigo do start
                  invoke ResetEvent, hEventStart   
             .elseif eax == 1
                 ; aqui codigo do stop
                 invoke ResetEvent, hEventStop
                 mov    EventStop, TRUE

             .elseif erros < 3   ;; Time out
                ;invoke PostMessage, hWnd, WM_OK, NULL,NULL
                invoke  GetDC, hWnd
                mov     hDC2,eax

                invoke CreateCompatibleDC,hDC2
                mov memDC2, eax
                invoke SelectObject,memDC2,hBmp
                mov hOld2, eax

                .if recomecou == 1
                    mov var1,0
                    mov var2,0
                    mov aux, 0
                    mov recomecou, 0
                .endif

                .if erros == 0
                    invoke BitBlt,hDC2,30,380,45,45,memDC2,0,0,SRCCOPY
                    invoke BitBlt,hDC2,75,380,45,45,memDC2,0,0,SRCCOPY
                    invoke BitBlt,hDC2,120,380,45,45,memDC2,0,0,SRCCOPY
                .elseif erros == 1
                    invoke BitBlt,hDC2,30,380,45,45,memDC2,0,0,SRCCOPY
                    invoke BitBlt,hDC2,75,380,45,45,memDC2,0,0,SRCCOPY
                    invoke BitBlt,hDC2,120,380,45,45,memDC2,45,0,SRCCOPY
                .elseif erros == 2
                    invoke BitBlt,hDC2,30,380,45,45,memDC2,0,0,SRCCOPY
                    invoke BitBlt,hDC2,75,380,45,45,memDC2,45,0,SRCCOPY
                    invoke BitBlt,hDC2,120,380,45,45,memDC2,45,0,SRCCOPY
                .endif

                ;invoke BitBlt,hDC2,0,0,240,443,memDC2,0,0,SRCCOPY

                
                
                invoke GetDC, hWnd
                mov     hDC,eax
                
                ;invoke BitBlt,hDC2,0,0,240,443,memDC2,0,0,SRCCOPY 

                invoke CreateCompatibleDC,hDC
                mov memDC, eax
                invoke SelectObject,memDC,hBmp2
                mov hOld, eax

                .if var2 == 0 
                    ;invoke TransparentBlt, hDC, 0  , 25 , 80, 125, memDC, var1, 0, 80, 125, ebx
                    invoke BitBlt,hDC,0,0,80,125,memDC,var1,0,SRCCOPY
                    invoke BitBlt,hDC,80,0,80,125,memDC,0,0,SRCCOPY
                    invoke BitBlt,hDC,160,0,80,125,memDC,0,0,SRCCOPY
                    invoke BitBlt,hDC,0,120,80,125,memDC,0,0,SRCCOPY
                    invoke BitBlt,hDC,80,120,80,125,memDC,0,0,SRCCOPY
                    invoke BitBlt,hDC,160,120,80,125,memDC,0,0,SRCCOPY
                    invoke BitBlt,hDC,0,240,80,125,memDC,0,0,SRCCOPY
                    invoke BitBlt,hDC,80,240,80,125,memDC,0,0,SRCCOPY
                    invoke BitBlt,hDC,160,240,80,125,memDC,0,0,SRCCOPY
                .endif
                
                .if var2 == 1 
                    ;invoke TransparentBlt, hDC, 80 , 25 , 80, 125, memDC, var1, 0, 80, 125, ebx
                    invoke BitBlt,hDC,80,0,80,125,memDC,var1,0,SRCCOPY
                    invoke BitBlt,hDC,0,0,80,125,memDC,0,0,SRCCOPY
                    invoke BitBlt,hDC,160,0,80,125,memDC,0,0,SRCCOPY
                    invoke BitBlt,hDC,0,120,80,125,memDC,0,0,SRCCOPY
                    invoke BitBlt,hDC,80,120,80,125,memDC,0,0,SRCCOPY
                    invoke BitBlt,hDC,160,120,80,125,memDC,0,0,SRCCOPY
                    invoke BitBlt,hDC,0,240,80,125,memDC,0,0,SRCCOPY
                    invoke BitBlt,hDC,80,240,80,125,memDC,0,0,SRCCOPY
                    invoke BitBlt,hDC,160,240,80,125,memDC,0,0,SRCCOPY
                .endif
                
                .if var2 == 2
                    ;invoke TransparentBlt, hDC, 160, 25 , 80, 125, memDC, var1, 0, 80, 125, ebx
                    invoke BitBlt,hDC,160,0,80,125,memDC,var1,0,SRCCOPY
                    invoke BitBlt,hDC,0,0,80,125,memDC,0,0,SRCCOPY
                    invoke BitBlt,hDC,80,0,80,125,memDC,0,0,SRCCOPY
                    invoke BitBlt,hDC,0,120,80,125,memDC,0,0,SRCCOPY
                    invoke BitBlt,hDC,80,120,80,125,memDC,0,0,SRCCOPY
                    invoke BitBlt,hDC,160,120,80,125,memDC,0,0,SRCCOPY
                    invoke BitBlt,hDC,0,240,80,125,memDC,0,0,SRCCOPY
                    invoke BitBlt,hDC,80,240,80,125,memDC,0,0,SRCCOPY
                    invoke BitBlt,hDC,160,240,80,125,memDC,0,0,SRCCOPY
                .endif
                
                .if var2 == 3
                    ;invoke TransparentBlt, hDC, 0  , 150, 80, 125, memDC, var1, 0, 80, 125, ebx
                    invoke BitBlt,hDC,0,120,80,125,memDC,var1,0,SRCCOPY
                    invoke BitBlt,hDC,0,0,80,125,memDC,0,0,SRCCOPY
                    invoke BitBlt,hDC,80,0,80,125,memDC,0,0,SRCCOPY
                    invoke BitBlt,hDC,160,0,80,125,memDC,0,0,SRCCOPY
                    invoke BitBlt,hDC,80,120,80,125,memDC,0,0,SRCCOPY
                    invoke BitBlt,hDC,160,120,80,125,memDC,0,0,SRCCOPY
                    invoke BitBlt,hDC,0,240,80,125,memDC,0,0,SRCCOPY
                    invoke BitBlt,hDC,80,240,80,125,memDC,0,0,SRCCOPY
                    invoke BitBlt,hDC,160,240,80,125,memDC,0,0,SRCCOPY
                .endif
                
                .if var2 == 4 
                    ;invoke TransparentBlt, hDC, 80 , 150, 80, 125, memDC, var1, 0, 80, 125, ebx
                    invoke BitBlt,hDC,80,120,80,125,memDC,var1,0,SRCCOPY
                    invoke BitBlt,hDC,0,0,80,125,memDC,0,0,SRCCOPY
                    invoke BitBlt,hDC,80,0,80,125,memDC,0,0,SRCCOPY
                    invoke BitBlt,hDC,160,0,80,125,memDC,0,0,SRCCOPY
                    invoke BitBlt,hDC,0,120,80,125,memDC,0,0,SRCCOPY
                    invoke BitBlt,hDC,160,120,80,125,memDC,0,0,SRCCOPY
                    invoke BitBlt,hDC,0,240,80,125,memDC,0,0,SRCCOPY
                    invoke BitBlt,hDC,80,240,80,125,memDC,0,0,SRCCOPY
                    invoke BitBlt,hDC,160,240,80,125,memDC,0,0,SRCCOPY
                .endif
                
                .if var2 == 5 
                    ;invoke TransparentBlt, hDC, 160, 150, 80, 125, memDC, var1, 0, 80, 125, ebx
                    invoke BitBlt,hDC,160,120,80,125,memDC,var1,0,SRCCOPY
                    invoke BitBlt,hDC,0,0,80,125,memDC,0,0,SRCCOPY
                    invoke BitBlt,hDC,80,0,80,125,memDC,0,0,SRCCOPY
                    invoke BitBlt,hDC,160,0,80,125,memDC,0,0,SRCCOPY
                    invoke BitBlt,hDC,0,120,80,125,memDC,0,0,SRCCOPY
                    invoke BitBlt,hDC,80,120,80,125,memDC,0,0,SRCCOPY
                    invoke BitBlt,hDC,0,240,80,125,memDC,0,0,SRCCOPY
                    invoke BitBlt,hDC,80,240,80,125,memDC,0,0,SRCCOPY
                    invoke BitBlt,hDC,160,240,80,125,memDC,0,0,SRCCOPY
                .endif
                
                .if var2 == 6 
                    ;invoke TransparentBlt, hDC, 0  , 275, 80, 125, memDC, var1, 0, 80, 125, ebx
                    invoke BitBlt,hDC,0,240,80,125,memDC,var1,0,SRCCOPY
                    invoke BitBlt,hDC,0,0,80,125,memDC,0,0,SRCCOPY
                    invoke BitBlt,hDC,80,0,80,125,memDC,0,0,SRCCOPY
                    invoke BitBlt,hDC,160,0,80,125,memDC,0,0,SRCCOPY
                    invoke BitBlt,hDC,0,120,80,125,memDC,0,0,SRCCOPY
                    invoke BitBlt,hDC,80,120,80,125,memDC,0,0,SRCCOPY
                    invoke BitBlt,hDC,160,120,80,125,memDC,0,0,SRCCOPY
                    invoke BitBlt,hDC,80,240,80,125,memDC,0,0,SRCCOPY
                    invoke BitBlt,hDC,160,240,80,125,memDC,0,0,SRCCOPY
                .endif
                
                .if var2 == 7 
                    ;invoke TransparentBlt, hDC, 80 , 275, 80, 125, memDC, var1, 0, 80, 125, ebx
                    invoke BitBlt,hDC,80,240,80,125,memDC,var1,0,SRCCOPY
                    invoke BitBlt,hDC,0,0,80,125,memDC,0,0,SRCCOPY
                    invoke BitBlt,hDC,80,0,80,125,memDC,0,0,SRCCOPY
                    invoke BitBlt,hDC,160,0,80,125,memDC,0,0,SRCCOPY
                    invoke BitBlt,hDC,0,120,80,125,memDC,0,0,SRCCOPY
                    invoke BitBlt,hDC,80,120,80,125,memDC,0,0,SRCCOPY
                    invoke BitBlt,hDC,160,120,80,125,memDC,0,0,SRCCOPY
                    invoke BitBlt,hDC,0,240,80,125,memDC,0,0,SRCCOPY
                    invoke BitBlt,hDC,160,240,80,125,memDC,0,0,SRCCOPY
                .endif
                
                .if var2 == 8 
                    ;invoke TransparentBlt, hDC, 160, 275, 80, 125, memDC, var1, 0, 80, 125, ebx
                    invoke BitBlt,hDC,160,240,80,125,memDC,var1,0,SRCCOPY
                    invoke BitBlt,hDC,0,0,80,125,memDC,0,0,SRCCOPY
                    invoke BitBlt,hDC,80,0,80,125,memDC,0,0,SRCCOPY
                    invoke BitBlt,hDC,160,0,80,125,memDC,0,0,SRCCOPY
                    invoke BitBlt,hDC,0,120,80,125,memDC,0,0,SRCCOPY
                    invoke BitBlt,hDC,80,120,80,125,memDC,0,0,SRCCOPY
                    invoke BitBlt,hDC,160,120,80,125,memDC,0,0,SRCCOPY
                    invoke BitBlt,hDC,0,240,80,125,memDC,0,0,SRCCOPY
                    invoke BitBlt,hDC,80,240,80,125,memDC,0,0,SRCCOPY
                .endif

                ;-------------------- delay -------------------
                
                invoke GetTickCount
                mov var3, eax
                ;.if acertos < 5
                    ;add var3, 1000    ; nominal milliseconds delay
                ;.elseif acertos < 10
                    ;add var3, 500
                ;.elseif acertos < 10
                    add var3, 400
                ;.elseif acertos < 15
                    ;add var3, 250
                ;.elseif acertos < 25
                    ;add var3, 100
                ;.else
                    ;add var3, 50
                 ;.endif
                 
                .while eax < var3
                    invoke GetTickCount
                .endw
                
                invoke SelectObject,hDC,hOld
                invoke DeleteDC,memDC

                invoke ReleaseDC, hWnd,hDC

                add  var1, 80
                
                mov cabecacima,0
                
                .if var1 == 160
                   mov cabecacima,1
                .endif

                .if var1 > 160

                    .if acertos == 0
                        inc erros
                    .elseif
                        mov acertos, 0

                    mov     aux ,0
                    mov     var1,0
                    add     var2,1
                    add     auxiliar,1
                    
                    .if var2 > 8   
                        mov     var2,0 
                        mov     auxiliar,0
                    .endif
                    
                    .endif
                    
                .endif
             .elseif erros == 3
                  inc erros
                  invoke PostMessage, hWnd, WM_OK, NULL,NULL
             .endif
             
             ;invoke InvalidateRect, hWnd , NULL, TRUE

        .ENDW
        
        ret
        
ThreadProc ENDP




end start
