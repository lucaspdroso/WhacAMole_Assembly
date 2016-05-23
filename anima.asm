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
        ok1             db "Evento 0",0
        timeout      db "Ocorreu time out ",0

.data?

        ThreadID    DWORD ?
        ThreadID1    DWORD ?
        ThreadID2    DWORD ?

        hThread     DWORD ?

        hEventStart HANDLE ?
        hEventStop HANDLE ?


; #########################################################################

.code

start:
      invoke GetModuleHandle, NULL
      mov hInstance, eax

      invoke LoadBitmap,hInstance,100
      mov hBmp, eax

      invoke LoadBitmap,hInstance,101
      mov hBmp2, eax

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
    LOCAL Ps     :PAINTSTRUCT
    LOCAL buffer1[128]:BYTE  ; these are two spare buffers
    LOCAL buffer2[128]:BYTE  ; for text manipulation etc..

    .if uMsg == WM_COMMAND
      .if wParam == 500
          invoke GetDC,hWin
          mov hDC, eax
          invoke Paint_Proc,hWin,hDC,1
          invoke ReleaseDC,hWin,hDC
        return 0
      .elseif wParam == 501
         invoke InvalidateRect, hWin, NULL , TRUE 
         invoke PostMessage, hWnd, WM_OK, NULL,NULL

      .elseif wParam == 502
         invoke InvalidateRect, hWin, NULL , TRUE 

      .endif
    .elseif uMsg == WM_OK
        invoke MessageBox, NULL, ADDR ok1, ADDR szDisplayName, MB_OK


    ;======== menu commands ========
    .elseif uMsg == WM_CREATE
        szText RunIt,"Run"
        invoke PushButton,ADDR RunIt,hWin,40,90,100,25,500

        invoke PushButton,ADDR RunIt,hWin,40,130,100,25,501

; criar thread
        invoke CreateEvent, NULL, TRUE, FALSE,NULL
        mov     hEventStart, eax

        invoke CreateEvent, NULL, TRUE, FALSE,NULL
        mov     hEventStop, eax

        mov     eax, OFFSET ThreadProc
        invoke CreateThread, NULL, NULL, eax, \
                                               NULL, NORMAL_PRIORITY_CLASS, \
                                               ADDR ThreadID 
        mov     hThread,eax


    .elseif uMsg == WM_SIZE

    .elseif uMsg == WM_PAINT
        invoke BeginPaint,hWin,ADDR Ps
          mov hDC, eax
          invoke Paint_Proc,hWin,hDC,0
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

; ########################################################################

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

Paint_Proc proc hWin:DWORD, hDC:DWORD, movit:DWORD

    LOCAL hOld :DWORD
    LOCAL memDC:DWORD
    LOCAL var1 :DWORD
    LOCAL var2 :DWORD
    LOCAL var3 :DWORD
    RGB 255, 255, 255

    mov ebx, eax

    invoke CreateCompatibleDC,hDC
    mov memDC, eax
    
invoke SelectObject,memDC,hBmp
mov hOld, eax

    .if movit == 0
  ; -------------------
  ; for normal repaint
  ; -------------------
      ;invoke InvalidateRect, hWin, NULL , TRUE 
      invoke TransparentBlt, hDC, 0  , 25 , 80, 125, memDC, 0, 0, 80, 125, ebx
      invoke TransparentBlt, hDC, 80 , 25 , 80, 125, memDC, 0, 0, 80, 125, ebx
      invoke TransparentBlt, hDC, 160, 25 , 80, 125, memDC, 0, 0, 80, 125, ebx
      invoke TransparentBlt, hDC, 0  , 150, 80, 125, memDC, 0, 0, 80, 125, ebx
      invoke TransparentBlt, hDC, 80 , 150, 80, 125, memDC, 0, 0, 80, 125, ebx
      invoke TransparentBlt, hDC, 160, 150, 80, 125, memDC, 0, 0, 80, 125, ebx
      invoke TransparentBlt, hDC, 0  , 275, 80, 125, memDC, 0, 0, 80, 125, ebx
      invoke TransparentBlt, hDC, 80 , 275, 80, 125, memDC, 0, 0, 80, 125, ebx
      invoke TransparentBlt, hDC, 160, 275, 80, 125, memDC, 0, 0, 80, 125, ebx

    .else
  ; --------------------------
  ; when you press the button
  ; --------------------------
    ; ********************************************************

    mov var3, 0

    .while var3 < 4     ;<< set the number of times image is looped

      mov var1, 0
      .while var1 < 320 ;<<  Bitmap width
      ; ------------------------------------------------
      ; Read across the double bitmap 1 pixel at a time
      ; and display a set rectangle size on the screen
      ; ------------------------------------------------
        ;invoke InvalidateRect, hWin, NULL , TRUE 
        invoke TransparentBlt, hDC, 0  , 25 , 80, 125, memDC, var1, 0, 80, 125, ebx
        invoke TransparentBlt, hDC, 80 , 25 , 80, 125, memDC, var1, 0, 80, 125, ebx
        invoke TransparentBlt, hDC, 160, 25 , 80, 125, memDC, var1, 0, 80, 125, ebx
        invoke TransparentBlt, hDC, 0  , 150, 80, 125, memDC, var1, 0, 80, 125, ebx
        invoke TransparentBlt, hDC, 80 , 150, 80, 125, memDC, var1, 0, 80, 125, ebx
        invoke TransparentBlt, hDC, 160, 150, 80, 125, memDC, var1, 0, 80, 125, ebx
        invoke TransparentBlt, hDC, 0  , 275, 80, 125, memDC, var1, 0, 80, 125, ebx
        invoke TransparentBlt, hDC, 80 , 275, 80, 125, memDC, var1, 0, 80, 125, ebx
        invoke TransparentBlt, hDC, 160, 275, 80, 125, memDC, var1, 0, 80, 125, ebx

      ; -----------------------
      ; Simple delay technique
      ; -----------------------
        invoke GetTickCount
        mov var2, eax
        add var2, 100    ; nominal milliseconds delay

        .while eax < var2
          invoke GetTickCount
        .endw

;        inc var1
          add var1, 80 
      .endw

    inc var3
    .endw

    ; ********************************************************

    .endif

    invoke SelectObject,hDC,hOld
    invoke DeleteDC,memDC

    return 0

Paint_Proc endp

; ########################################################################

ThreadProc PROC USES ecx Param:DWORD
    LOCAL  var1  :DWORD
    LOCAL  hDC   :DWORD
    LOCAL  hDC2  :DWORD
    LOCAL hOld   :DWORD
    LOCAL hOld2  :DWORD
    LOCAL memDC  :DWORD
    LOCAL memDC2 :DWORD

    RGB 255, 255, 255

    mov ebx, eax


        mov     var1,0

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

             .else   ;; Time out
        ;        invoke PostMessage, hWnd, WM_OK, NULL,NULL


                invoke GetDC, hWnd
                mov     hDC2,eax

                invoke CreateCompatibleDC,hDC2
                mov memDC2, eax
                invoke SelectObject,memDC2,hBmp2
                mov hOld2, eax

                invoke BitBlt,hDC2,0,0,240,443,memDC2,0,0,SRCCOPY

                invoke GetDC, hWnd
                mov     hDC,eax

                invoke CreateCompatibleDC,hDC
                mov memDC, eax
                invoke SelectObject,memDC,hBmp
                mov hOld, eax

                ;invoke InvalidateRect, hWin, NULL , TRUE 
                invoke TransparentBlt, hDC, 0  , 25 , 80, 125, memDC, var1, 0, 80, 125, ebx
                invoke TransparentBlt, hDC, 80 , 25 , 80, 125, memDC, var1, 0, 80, 125, ebx
                invoke TransparentBlt, hDC, 160, 25 , 80, 125, memDC, var1, 0, 80, 125, ebx
                invoke TransparentBlt, hDC, 0  , 150, 80, 125, memDC, var1, 0, 80, 125, ebx
                invoke TransparentBlt, hDC, 80 , 150, 80, 125, memDC, var1, 0, 80, 125, ebx
                invoke TransparentBlt, hDC, 160, 150, 80, 125, memDC, var1, 0, 80, 125, ebx
                invoke TransparentBlt, hDC, 0  , 275, 80, 125, memDC, var1, 0, 80, 125, ebx
                invoke TransparentBlt, hDC, 80 , 275, 80, 125, memDC, var1, 0, 80, 125, ebx
                invoke TransparentBlt, hDC, 160, 275, 80, 125, memDC, var1, 0, 80, 125, ebx
                
                invoke SelectObject,hDC,hOld
                invoke DeleteDC,memDC

                invoke ReleaseDC, hWnd,hDC

                add  var1, 80

                .if var1 > 320
                    mov     var1,0
                .endif
             .endif   

        .ENDW
        
        ret
        
ThreadProc ENDP




end start
