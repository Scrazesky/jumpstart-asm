; ============================================================
;  JUMPY! Learning Adventures — x86 Assembly (NASM/Win32)
;  Retro single-screen platformer. 3 game modes.
;  v3: Fixed background color, character rendering, menu alignment.
; ============================================================
bits 32

extern _GetModuleHandleA@4
extern _ExitProcess@4
extern _RegisterClassExA@4
extern _CreateWindowExA@32
extern _ShowWindow@8
extern _UpdateWindow@4
extern _GetMessageA@16
extern _TranslateMessage@4
extern _DispatchMessageA@4
extern _DefWindowProcA@16
extern _PostQuitMessage@4
extern _BeginPaint@8
extern _EndPaint@8
extern _InvalidateRect@12
extern _SetTimer@16
extern _KillTimer@8
extern _CreateCompatibleDC@4
extern _CreateCompatibleBitmap@12
extern _SelectObject@8
extern _DeleteDC@4
extern _DeleteObject@4
extern _BitBlt@36
extern _StretchBlt@44
extern _SetStretchBltMode@8
extern _FillRect@12
extern _CreateSolidBrush@4
extern _SetBkMode@8
extern _SetTextColor@8
extern _TextOutA@20
extern _GetDC@4
extern _ReleaseDC@8
extern _SetTextAlign@8
extern _GetModuleFileNameA@12
extern _LoadLibraryA@4
extern _GetProcAddress@8
extern _CreateFontA@56
extern _AdjustWindowRect@12
extern _Polygon@12
extern _Ellipse@20
extern _GetStockObject@4
extern _LoadImageA@24
extern _CreateFileA@28
extern _ReadFile@20
extern _WriteFile@20
extern _CloseHandle@4

%define CS_HREDRAW       0x0002
%define CS_VREDRAW       0x0001
%define WS_OVERLAPPED    0x00000000
%define WS_CAPTION       0x00C00000
%define WS_SYSMENU       0x00080000
%define WS_MINIMIZEBOX   0x00020000
%define WS_VISIBLE       0x10000000
%define CW_USEDEFAULT    0x80000000
%define SW_SHOW          5
%define WM_CREATE        0x0001
%define WM_DESTROY       0x0002
%define WM_PAINT         0x000F
%define WM_TIMER         0x0113
%define WM_KEYDOWN       0x0100
%define WM_KEYUP         0x0101
%define MM_MCINOTIFY     0x03B9
%define SRCCOPY          0x00CC0020
%define TRANSPARENT      1
%define TIMER_ID         1
%define TIMER_MS         16

; Background bitmap constants
%define IMAGE_BITMAP        0
%define LR_LOADFROMFILE     0x00000010
%define LR_CREATEDIBSECTION 0x00002000
%define HALFTONE            4
%define BMP_W               612
%define BMP_H               344
%define MY_WS  WS_OVERLAPPED | WS_CAPTION | WS_SYSMENU | WS_MINIMIZEBOX | WS_VISIBLE

%define VK_LEFT   0x25
%define VK_UP     0x26
%define VK_RIGHT  0x27
%define VK_SPACE  0x20
%define VK_ESCAPE 0x1B
%define VK_1      0x31
%define VK_2      0x32
%define VK_3      0x33
%define VK_4      0x34
%define VK_5      0x35
%define VK_6      0x36
%define VK_BACK   0x08
%define VK_RETURN 0x0D
%define VK_W      0x57
%define VK_A      0x41
%define VK_S      0x53
%define VK_D      0x44
%define NAME_MAX  12

; Player block offsets (each block = 44 bytes = PB_SZ)
%define PB_X        0
%define PB_Y        4
%define PB_VY       8
%define PB_ONG     12
%define PB_KL      16
%define PB_KR      20
%define PB_KJ      24
%define PB_KJP     28
%define PB_INV     32
%define PB_SCORE   36
%define PB_LIVES   40
%define PB_SZ      44

; Spawn coordinates
%define P1_SPAWNX  60
%define P2_SPAWNX  716
%define SPAWN_Y    490

; Difficulty constants
%define DIFF_EASY   0
%define DIFF_MED    1
%define DIFF_HARD   2
%define COLL_EASY   3
%define COLL_MED    5
%define COLL_HARD   6

; Game mode constants
%define MODE_LETTERS  0
%define MODE_NUMBERS  1
%define MODE_SHAPES   2

; Shape ID constants
%define SHAPE_CIRCLE  0
%define SHAPE_TRI     1
%define SHAPE_SQUARE  2
%define SHAPE_PENTA   3
%define SHAPE_HEXA    4
%define SHAPE_HEPTA   5
%define SHAPE_OCTA    6
%define SHAPE_NONA    7

; Collectible box dimensions
%define BOX_W_LN      28
%define BOX_H_LN      28
%define BOX_W_SH      80
%define BOX_H_SH      30

; GDI stock object for null (transparent) pen
%define NULL_PEN      8

; File I/O constants
%define GENERIC_READ          0x80000000
%define GENERIC_WRITE         0x40000000
%define CREATE_ALWAYS         2
%define OPEN_EXISTING         3
%define FILE_ATTR_NORMAL      0x80
%define INVALID_HANDLE_VALUE  -1
%define SB_MAGIC              0x31425350   ; "JSB1" little-endian

; Scoreboard constants
%define SB_MAX        10
%define SB_ENTRY_SZ   24
%define SB_OFS_NAME    0
%define SB_OFS_LEN    16
%define SB_OFS_SCORE  20

%define SW  800
%define SH  600
%define PW  24
%define PH  32
%define GRAV       1
%define JUMPF     -14
%define SPEED      4
%define NPLAT     11
%define NCOLL      6

; Retro colors (BGR)
%define C_BG       0x00200010
%define C_GROUND   0x00006600
%define C_PLAT     0x0000AA00
%define C_PLAYER   0x00FFFF00
%define C_CORRECT  0x0000FFFF
%define C_WRONG    0x006060FF
%define C_HUD      0x0000FF00
%define C_TITLE    0x0000FFFF
%define C_WHITE    0x00FFFFFF
%define C_GRAY     0x00808080
%define C_DARK     0x00404040
%define C_PLAYER2  0x00FF00FF      ; magenta (BGR) for player 2

; Text alignment
%define TA_LEFT    0
%define TA_CENTER  6

; ============================================================
section .data
; ============================================================
className   db "JumpyRetro", 0
winTitle    db "JUMPY! Learning Adventures", 0

; Sequences — ALL CAPS, simple characters only
letters     db "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
letLen      dd 26
numbers     db "1234567890"
numLen      dd 10
shapes      db 0,1,2,3,4,5,6,7        ; shape IDs (byte sequence)
shpLen      dd 8

; Shape full names for wide collectible boxes and HUD
sShName0    db "CIRCLE",   0
sShName0Len dd 6
sShName1    db "TRIANGLE", 0
sShName1Len dd 8
sShName2    db "SQUARE",   0
sShName2Len dd 6
sShName3    db "PENTAGON", 0
sShName3Len dd 8
sShName4    db "HEXAGON",  0
sShName4Len dd 7
sShName5    db "HEPTAGON", 0
sShName5Len dd 8
sShName6    db "OCTAGON",  0
sShName6Len dd 7
sShName7    db "NONAGON",  0
sShName7Len dd 7

; Shape name lookup tables (indexed by shape ID 0..7)
shapeNamePtrs:
    dd sShName0, sShName1, sShName2, sShName3
    dd sShName4, sShName5, sShName6, sShName7
shapeNameLens:
    dd 6, 8, 6, 8, 7, 8, 7, 7

; Polygon vertex tables (x,y pairs, absolute screen coords)
; Figure anchored at top-right: center (cx=745, cy=85), radius ~40
; Region: x=700..790, y=40..130 (below the 24-px HUD bar)
shpTri:    dd 745,45,  780,105,  710,105                               ; 3 verts
shpSquare: dd 710,50,  780,50,   780,120,  710,120                    ; 4 verts
shpPenta:  dd 745,45,  783,73,   768,118,  722,118,  707,73           ; 5 verts
shpHexa:   dd 710,65,  745,45,   780,65,   780,105,  745,125, 710,105 ; 6 verts
shpHepta:  dd 745,45,  780,68,   784,108,  759,127,  731,127, 706,108, 710,68  ; 7 verts
shpOcta:   dd 729,45,  761,45,   785,69,   785,101,  761,125, 729,125, 705,101, 705,69  ; 8 verts (regular octagon, flat top/bottom)
shpNona:   dd 745,45,  774,55,   786,82,   778,112,  755,127, 735,127, 712,112, 704,82, 716,55  ; 9 verts

; Shape vertex pointer + count tables (indexed by shape ID 0..7)
; Index 0 (CIRCLE) -> Ellipse call, pointer ignored
shapeVerts: dd 0, shpTri, shpSquare, shpPenta, shpHexa, shpHepta, shpOcta, shpNona
shapeVcnt:  dd 0, 3,      4,         5,         6,       7,        8,       9

; Menu strings — option rows drawn TA_LEFT at x=270
sTitle      db "J  U  M  P  Y  !", 0
sTitleLen   dd 16
sTitle2     db "Learning Adventures", 0
sTitle2Len  dd 19
sFontFace   db "Arial", 0
sMenu1      db "[ 1 ]   A B C   Letters", 0
sMenu1Len   dd 23
sMenu2      db "[ 2 ]   1 2 3   Numbers", 0
sMenu2Len   dd 23
sPrompt     db "Press  1,  2,  or  3  to start", 0
sPromptLen  dd 31

; HUD strings
sStars      db "STARS: ", 0
sLives      db "LIVES: ", 0
sFind       db "FIND:  ", 0
sGameOver   db "G A M E    O V E R", 0
sGOLen      dd 18
sRestart    db "SPACE = Retry     ESC = Menu", 0
sRestartLen dd 28
sScoreLbl   db "Your Score:  ", 0
sScoreLblLen dd 13

; Competitive 2P HUD strings
sP1Hud    db "P1 S:", 0
sP1HudLen dd 5
sP2Hud    db "P2 S:", 0
sP2HudLen dd 5
sLHud     db " L:", 0
sLHudLen  dd 3

; Login screen strings
sLoginTitle    db "ENTER YOUR NAME", 0
sLoginTitleLen dd 15
sLoginHint     db "A-Z   BACKSPACE = delete   ENTER = confirm", 0
sLoginHintLen  dd 43
sMenu3Game     db "[ 3 ]   O  ^  []     Shapes", 0
sMenu3GameLen  dd 27
sMenu4         db "[ 4 ]   Change Player Name", 0
sMenu4Len      dd 26
sMenu5_1P      db "[ 5 ]   1 Player Mode", 0
sMenu5_1PLen   dd 21
sMenu5_2P      db "[ 5 ]   2 Players Mode", 0
sMenu5_2PLen   dd 22
sMenu6         db "[ 6 ]   Change Player 2 Name", 0
sMenu6Len      dd 28
sMenu0         db "[ 0 ]   Top Scores", 0
sMenu0Len      dd 18

; Player 2 name (2P mode) — captured via gameState 5
sTeamTitle     db "ENTER PLAYER 2 NAME", 0
sTeamTitleLen  dd 19
player2Name    times NAME_MAX + 1 db 0
player2NameLen dd 0

; Difficulty select screen strings
sDiffTitle     db "SELECT DIFFICULTY", 0
sDiffTitleLen  dd 17
sDiffEasy      db "[  1  ]   EASY     -  3 boxes", 0
sDiffEasyLen   dd 29
sDiffMed       db "[  2  ]   MEDIUM   -  5 boxes", 0
sDiffMedLen    dd 29
sDiffHard      db "[  3  ]   HARD     -  6 boxes", 0
sDiffHardLen   dd 29
sDiffBack      db "ESC = back to menu", 0
sDiffBackLen   dd 18
sDiffHud       db "DIFF: ", 0
sDiffHudLen    dd 6
diffChar       db "H", 0           ; kept for layout stability (unused after word upgrade)

; Full difficulty word strings for HUD display
sDiffEasyW     db "EASY", 0
sDiffEasyWLen  dd 4
sDiffMedW      db "MEDIUM", 0
sDiffMedWLen   dd 6
sDiffHardW     db "HARD", 0
sDiffHardWLen  dd 4

; Scoreboard UI strings
sHiTitle       db "HIGH SCORES", 0
sHiTitleLen    dd 11
sHiTitleS      db "TOP SCORES", 0
sHiTitleSLen   dd 10
sNoScores      db "-- NO SCORES YET --", 0
sNoScoresLen   dd 19

; Player name buffer (A-Z only, up to NAME_MAX chars, null-padded)
playerName     times NAME_MAX + 1 db 0
nameLen        dd 0

; Scoreboard: 10 entries × 24 bytes each
;   +0   name[16]    first NAME_MAX bytes used, rest zero-padded
;   +16  nameLen     dword
;   +20  score       dword (highest score for this name)
scoreboard     times SB_MAX * SB_ENTRY_SZ db 0
sbCount        dd 0
lastSavedIdx   dd -1           ; index of last-saved entry (for highlight); -1=none

; Index of P2's entry in the unified scoreboard (for highlight); -1=none
lastSavedIdxP2 dd -1

; Active scoreboard pointers — set by caller before RenderScoreboard
sbActiveBase   dd 0
sbActiveCount  dd 0

; Game state (3 = login on first launch)
gameState   dd 3
gameMode    dd 0

; Player blocks — laid out so PB_* offsets match exactly
; PB_X=0, PB_Y=4, PB_VY=8, PB_ONG=12, PB_KL=16, PB_KR=20, PB_KJ=24, PB_KJP=28, PB_INV=32
player1:
pX          dd P1_SPAWNX
pY          dd SPAWN_Y
pVY         dd 0
pOnG        dd 0
kL          dd 0
kR          dd 0
kJump       dd 0
kJumpPrev   dd 0
invT        dd 0
pScore      dd 0
pLives      dd 3

player2:
pX2         dd P2_SPAWNX
pY2         dd SPAWN_Y
pVY2        dd 0
pOnG2       dd 0
kL2         dd 0
kR2         dd 0
kJump2      dd 0
kJumpPrev2  dd 0
invT2       dd 0
pScore2     dd 0
pLives2     dd 3

playerCount dd 1                ; 1 = single-player, 2 = competitive
difficulty  dd DIFF_HARD        ; 0=Easy, 1=Medium, 2=Hard
collActive  dd COLL_HARD        ; live collectible count for current round (3/5/6)
boxW        dd BOX_W_LN         ; current collectible box width (updated by StartGame)
boxH        dd BOX_H_LN         ; current collectible box height

; Current target — initialize seqPtr to letters (NOT zero)
seqPtr      dd letters
seqLen      dd 10
targIdx     dd 0
targChar    db "A", 0

; Platforms: x, y, w — every gap ≤ 80px (jumpable with JUMPF=-14, max=105px)
platforms:
    dd 0,   540, 800             ; P0:  ground
    dd 30,  460, 150             ; P1:  left low          (80px up from ground)
    dd 230, 390, 150             ; P2:  left mid          (70px up from P1)
    dd 420, 340, 150             ; P3:  center            (50px up from P2)
    dd 600, 400, 150             ; P4:  right mid         (60px down, reachable)
    dd 670, 460, 120             ; P5:  right low         (60px down)
    dd 80,  320, 130             ; P6:  upper-left        (70px up from P2)
    dd 260, 260, 130             ; P7:  high left         (60px up from P6)
    dd 450, 260, 130             ; P8:  high right        (same height as P7)
    dd 640, 330, 120             ; P9:  upper-right       (70px down from P8)
    dd 330, 190, 160             ; P10: top center        (70px up from P7/P8)

; Collectibles sitting ON platforms (positions set by SetupCollectibles)
; Format: x, y, charCode (ASCII), isCorrect, collected
collectibles:
    dd 380, 160, 65, 1, 0       ; C0: correct (65 = 'A')
    dd 60,  430, 66, 0, 0       ; C1: wrong
    dd 270, 360, 67, 0, 0       ; C2: wrong
    dd 630, 370, 68, 0, 0       ; C3: wrong
    dd 120, 290, 70, 0, 0       ; C4: wrong
    dd 490, 230, 72, 0, 0       ; C5: wrong

; Platform rotation order (indices 1-10, all unique, cycled by targIdx)
platOrder   dd 10, 1, 4, 7, 2, 8, 5, 3, 9, 6

digitBuf    times 12 db 0

; Audio filenames and MCI command fragments
wavBgName    db "BG MUSIC.wav", 0
wavErrName   db "ERROR.wav", 0
wavOkName    db "SUCCESS.wav", 0
sbFileName   db "scoreboard.dat", 0
sbMagicMem   dd SB_MAGIC
dllWinmm     db "winmm.dll", 0
; Background image filenames
bmp1Name     db "stars1.bmp", 0
bmp2Name     db "stars2.bmp", 0
procPlay     db "PlaySoundA", 0
procMci      db "mciSendStringA", 0
mciOpenPre   db 'open "', 0
mciOpenSuf   db '" type waveaudio alias bgmusic', 0
mciPlayCmd   db "play bgmusic from 0 notify", 0
mciStopCmd   db "stop bgmusic", 0
mciCloseCmd  db "close bgmusic", 0

; ============================================================
section .bss
; ============================================================
hInst       resd 1
wndRect     resb 16
hWnd        resd 1
msgBuf      resb 48
wc          resb 48
ps          resb 68
hdcMem      resd 1
hbmBack     resd 1
hbmOld      resd 1
brBg        resd 1
brGround    resd 1
brPlat      resd 1
brPlayer    resd 1
brCorrect   resd 1
brWrong     resd 1
brDark      resd 1
brPlayer2   resd 1     ; player 2 color (magenta)
brWinBg     resd 1     ; window background brush (dark, avoids white bars)
brShape     resd 1     ; shape figure fill brush (shapes mode)
hPenNull    resd 1     ; cached NULL_PEN stock object (no outline)
hPenOld     resd 1     ; saved pen during DrawShapeFigure
hBrShOld    resd 1     ; saved brush during DrawShapeFigure

; Audio path buffers (built at runtime from exe directory)
exeDir      resb 260
wavPathBg   resb 260
wavPathErr  resb 260
wavPathOk   resb 260
sbPath      resb 260
ioBytes     resd 1
mciOpenCmd  resb 512
; Runtime winmm function pointers
hWinmm      resd 1
pfnPlay     resd 1
pfnMci      resd 1
; Title font handle
hFontTitle  resd 1
hFontOld    resd 1
; Background bitmap paths and handles
bmp1Path     resb 260
bmp2Path     resb 260
hbmStars1    resd 1   ; in-game background bitmap handle
hbmStars2    resd 1   ; menu/other-state background bitmap handle
hdcImg       resd 1   ; reusable compatible DC for blitting bitmaps
hbmImgOld    resd 1   ; saved bitmap when selecting into hdcImg

; ============================================================
section .text
; ============================================================
global _WinMain@16

_WinMain@16:
    push    dword 0
    call    _GetModuleHandleA@4
    mov     [hInst], eax

    ; ---- Create dark background brush BEFORE class registration ----
    push    C_BG
    call    _CreateSolidBrush@4
    mov     [brWinBg], eax

    ; Register class with dark background brush (no more white bars)
    mov     dword [wc + 0],  48
    mov     dword [wc + 4],  CS_HREDRAW | CS_VREDRAW
    mov     dword [wc + 8],  WndProc
    mov     dword [wc + 12], 0
    mov     dword [wc + 16], 0
    mov     eax, [hInst]
    mov     [wc + 20], eax
    mov     dword [wc + 24], 0
    mov     dword [wc + 28], 0
    mov     eax, [brWinBg]
    mov     [wc + 32], eax               ; dark background brush
    mov     dword [wc + 36], 0
    mov     dword [wc + 40], className
    mov     dword [wc + 44], 0
    push    wc
    call    _RegisterClassExA@4
    test    eax, eax
    jz      .exit

    ; Compute exact window size so client area == SW x SH
    mov     dword [wndRect + 0], 0
    mov     dword [wndRect + 4], 0
    mov     dword [wndRect + 8], SW
    mov     dword [wndRect + 12], SH
    push    dword 0
    push    dword MY_WS
    push    wndRect
    call    _AdjustWindowRect@12

    mov     eax, [wndRect + 8]
    sub     eax, [wndRect + 0]           ; eax = adjusted window width
    mov     ebx, [wndRect + 12]
    sub     ebx, [wndRect + 4]           ; ebx = adjusted window height

    push    dword 0
    push    dword [hInst]
    push    dword 0
    push    dword 0
    push    ebx
    push    eax
    push    dword CW_USEDEFAULT
    push    dword CW_USEDEFAULT
    push    dword MY_WS
    push    winTitle
    push    className
    push    dword 0
    call    _CreateWindowExA@32
    test    eax, eax
    jz      .exit
    mov     [hWnd], eax
    push    SW_SHOW
    push    eax
    call    _ShowWindow@8
    push    dword [hWnd]
    call    _UpdateWindow@4

.ml:
    push    dword 0
    push    dword 0
    push    dword 0
    push    msgBuf
    call    _GetMessageA@16
    test    eax, eax
    jz      .exit
    push    msgBuf
    call    _TranslateMessage@4
    push    msgBuf
    call    _DispatchMessageA@4
    jmp     .ml
.exit:
    push    dword 0
    call    _ExitProcess@4

; ============================================================
WndProc:
    push    ebp
    mov     ebp, esp
    push    ebx
    push    esi
    push    edi

    mov     eax, [ebp + 12]
    cmp     eax, WM_CREATE
    je      .wCreate
    cmp     eax, WM_TIMER
    je      .wTimer
    cmp     eax, WM_PAINT
    je      .wPaint
    cmp     eax, WM_KEYDOWN
    je      .wKeyDn
    cmp     eax, WM_KEYUP
    je      .wKeyUp
    cmp     eax, WM_DESTROY
    je      .wDest
    cmp     eax, MM_MCINOTIFY
    je      .wMciNotify
    jmp     .wDef

.wCreate:
    ; Save hWnd now so InitAudio (called below) can pass a valid callback HWND
    mov     eax, [ebp + 8]
    mov     [hWnd], eax
    push    dword 0
    push    TIMER_MS
    push    TIMER_ID
    push    dword [ebp + 8]
    call    _SetTimer@16
    push    dword [ebp + 8]
    call    _GetDC@4
    mov     esi, eax
    push    esi
    call    _CreateCompatibleDC@4
    mov     [hdcMem], eax
    push    SH
    push    SW
    push    esi
    call    _CreateCompatibleBitmap@12
    mov     [hbmBack], eax
    push    eax
    push    dword [hdcMem]
    call    _SelectObject@8
    mov     [hbmOld], eax
    push    esi
    push    dword [ebp + 8]
    call    _ReleaseDC@8

    ; Create all game brushes once
    push    C_BG
    call    _CreateSolidBrush@4
    mov     [brBg], eax
    push    C_GROUND
    call    _CreateSolidBrush@4
    mov     [brGround], eax
    push    C_PLAT
    call    _CreateSolidBrush@4
    mov     [brPlat], eax
    push    C_PLAYER
    call    _CreateSolidBrush@4
    mov     [brPlayer], eax
    push    C_PLAYER2
    call    _CreateSolidBrush@4
    mov     [brPlayer2], eax
    push    C_CORRECT
    call    _CreateSolidBrush@4
    mov     [brCorrect], eax
    push    C_WRONG
    call    _CreateSolidBrush@4
    mov     [brWrong], eax
    push    C_DARK
    call    _CreateSolidBrush@4
    mov     [brDark], eax
    push    C_TITLE
    call    _CreateSolidBrush@4
    mov     [brShape], eax
    push    NULL_PEN
    call    _GetStockObject@4
    mov     [hPenNull], eax

    ; Create large bold title font (32px Arial Bold)
    push    sFontFace          ; lpszFace
    push    dword 0             ; PitchAndFamily
    push    dword 0             ; Quality
    push    dword 0             ; ClipPrecision
    push    dword 0             ; OutputPrecision
    push    dword 0             ; CharSet
    push    dword 0             ; StrikeOut
    push    dword 0             ; Underline
    push    dword 0             ; Italic
    push    dword 700           ; Weight = FW_BOLD
    push    dword 0             ; Orientation
    push    dword 0             ; Escapement
    push    dword 0             ; Width (auto)
    push    dword -32           ; Height (32px)
    call    _CreateFontA@56
    mov     [hFontTitle], eax

    call    InitAudio
    call    InitBackgrounds
    call    LoadScoreboard
    xor     eax, eax
    jmp     .wRet

.wTimer:
    cmp     dword [gameState], 1
    jne     .noUpd
    call    GameUpdate
.noUpd:
    push    dword 0
    push    dword 0
    push    dword [ebp + 8]
    call    _InvalidateRect@12
    xor     eax, eax
    jmp     .wRet

.wPaint:
    push    ps
    push    dword [ebp + 8]
    call    _BeginPaint@8
    mov     esi, eax
    call    Render
    push    SRCCOPY
    push    dword 0
    push    dword 0
    push    dword [hdcMem]
    push    SH
    push    SW
    push    dword 0
    push    dword 0
    push    esi
    call    _BitBlt@36
    push    ps
    push    dword [ebp + 8]
    call    _EndPaint@8
    xor     eax, eax
    jmp     .wRet

.wKeyDn:
    mov     eax, [ebp + 16]

    ; ---- Login (state 3) ----
    cmp     dword [gameState], 3
    jne     .notLogin3
    call    LoginInput
    jmp     .kdDone
.notLogin3:

    ; ---- Player 2 Name Input (state 5) ----
    cmp     dword [gameState], 5
    jne     .notLogin
    call    Player2NameInput
    jmp     .kdDone
.notLogin:

    ; ---- Menu (state 0) ----
    cmp     dword [gameState], 0
    jne     .notMenu
    cmp     eax, VK_1
    je      .goLet
    cmp     eax, VK_2
    je      .goNum
    cmp     eax, VK_3
    je      .goShp
    cmp     eax, VK_4
    je      .goName
    cmp     eax, VK_5
    je      .toggle2P
    cmp     eax, VK_6
    je      .goTeamName
    cmp     eax, 0x30           ; VK_0
    je      .goScoreboard
    jmp     .kdDone
.goScoreboard:
    mov     dword [gameState], 6
    jmp     .kdDone
.goShp:
    mov     dword [gameMode], MODE_SHAPES
    mov     dword [gameState], 4    ; go to Difficulty Select
    jmp     .kdDone
.toggle2P:
    mov     eax, [playerCount]
    xor     eax, 3              ; 1 -> 2, 2 -> 1
    mov     [playerCount], eax
    cmp     eax, 2              ; just switched TO 2P?
    jne     .kdDone
    cmp     dword [player2NameLen], 0
    jne     .kdDone             ; already have a player 2 name
    mov     dword [gameState], 5
    jmp     .kdDone
.goTeamName:
    cmp     dword [playerCount], 2
    jne     .kdDone             ; [6] only active in 2P mode
    mov     dword [player2NameLen], 0
    mov     byte [player2Name], 0
    mov     dword [gameState], 5
    jmp     .kdDone
.goName:
    ; Reset name buffer then go to login screen
    mov     dword [nameLen], 0
    mov     byte [playerName], 0
    mov     dword [gameState], 3
    jmp     .kdDone
.goLet:
    mov     dword [gameMode], 0
    mov     dword [gameState], 4    ; go to Difficulty Select
    jmp     .kdDone
.goNum:
    mov     dword [gameMode], 1
    mov     dword [gameState], 4
    jmp     .kdDone
.notMenu:
    ; ---- Scoreboard view (state 6) ----
    cmp     dword [gameState], 6
    jne     .notSb
    cmp     eax, VK_ESCAPE
    jne     .kdDone
    mov     dword [gameState], 0
    jmp     .kdDone
.notSb:
    ; ---- Difficulty Select (state 4) ----
    cmp     dword [gameState], 4
    jne     .notDiff
    cmp     eax, VK_1
    je      .diffE
    cmp     eax, VK_2
    je      .diffM
    cmp     eax, VK_3
    je      .diffH
    cmp     eax, VK_ESCAPE
    jne     .kdDone
    mov     dword [gameState], 0
    jmp     .kdDone
.diffE:
    mov     dword [difficulty], DIFF_EASY
    call    StartGame
    jmp     .kdDone
.diffM:
    mov     dword [difficulty], DIFF_MED
    call    StartGame
    jmp     .kdDone
.diffH:
    mov     dword [difficulty], DIFF_HARD
    call    StartGame
    jmp     .kdDone
.notDiff:
    ; ---- Game Over (state 2) ----
    cmp     dword [gameState], 2
    jne     .notGO
    cmp     eax, VK_SPACE
    jne     .goE
    mov     dword [gameState], 4    ; back to difficulty select to re-pick
    jmp     .kdDone
.goE:
    cmp     eax, VK_ESCAPE
    jne     .kdDone
    mov     dword [gameState], 0
    jmp     .kdDone
.notGO:
    ; Playing — WASD always controls player 1
    cmp     eax, VK_A
    jne     .nkWA
    mov     dword [kL], 1
.nkWA:
    cmp     eax, VK_D
    jne     .nkWD
    mov     dword [kR], 1
.nkWD:
    cmp     eax, VK_W
    jne     .nkWW
    mov     dword [kJump], 1
.nkWW:
    ; Route arrow keys by player count
    cmp     dword [playerCount], 2
    je      .nkArrowsP2
    ; 1P: arrows + space also control player 1
    cmp     eax, VK_LEFT
    jne     .nk1L
    mov     dword [kL], 1
.nk1L:
    cmp     eax, VK_RIGHT
    jne     .nk1R
    mov     dword [kR], 1
.nk1R:
    cmp     eax, VK_UP
    je      .nk1J
    cmp     eax, VK_SPACE
    jne     .nkEsc
.nk1J:
    mov     dword [kJump], 1
    jmp     .nkEsc
.nkArrowsP2:
    ; 2P: arrows control player 2
    cmp     eax, VK_LEFT
    jne     .nk2L
    mov     dword [kL2], 1
.nk2L:
    cmp     eax, VK_RIGHT
    jne     .nk2R
    mov     dword [kR2], 1
.nk2R:
    cmp     eax, VK_UP
    jne     .nkEsc
    mov     dword [kJump2], 1
.nkEsc:
    cmp     eax, VK_ESCAPE
    jne     .kdDone
    mov     dword [gameState], 0
.kdDone:
    xor     eax, eax
    jmp     .wRet

.wKeyUp:
    mov     eax, [ebp + 16]
    ; WASD always releases player 1
    cmp     eax, VK_A
    jne     .nuWA
    mov     dword [kL], 0
.nuWA:
    cmp     eax, VK_D
    jne     .nuWD
    mov     dword [kR], 0
.nuWD:
    cmp     eax, VK_W
    jne     .nuWW
    mov     dword [kJump], 0
.nuWW:
    ; Route arrow/space releases by player count
    cmp     dword [playerCount], 2
    je      .nuArrowsP2
    ; 1P: arrows + space release player 1
    cmp     eax, VK_LEFT
    jne     .nu1L
    mov     dword [kL], 0
.nu1L:
    cmp     eax, VK_RIGHT
    jne     .nu1R
    mov     dword [kR], 0
.nu1R:
    cmp     eax, VK_UP
    je      .nu1J
    cmp     eax, VK_SPACE
    jne     .nuDone
.nu1J:
    mov     dword [kJump], 0
    jmp     .nuDone
.nuArrowsP2:
    ; 2P: arrows release player 2
    cmp     eax, VK_LEFT
    jne     .nu2L
    mov     dword [kL2], 0
.nu2L:
    cmp     eax, VK_RIGHT
    jne     .nu2R
    mov     dword [kR2], 0
.nu2R:
    cmp     eax, VK_UP
    jne     .nuDone
    mov     dword [kJump2], 0
.nuDone:
    xor     eax, eax
    jmp     .wRet

.wDest:
    push    TIMER_ID
    push    dword [ebp + 8]
    call    _KillTimer@8
    call    StopAudio
    push    dword [hFontTitle]
    call    _DeleteObject@4
    ; Free background bitmap resources
    push    dword [hbmStars1]
    call    _DeleteObject@4
    push    dword [hbmStars2]
    call    _DeleteObject@4
    push    dword [hdcImg]
    call    _DeleteDC@4
    push    dword 0
    call    _PostQuitMessage@4
    xor     eax, eax
    jmp     .wRet

.wMciNotify:
    cmp     dword [pfnMci], 0
    je      .wmnDone
    push    dword [hWnd]
    push    dword 0
    push    dword 0
    push    mciPlayCmd
    call    [pfnMci]
.wmnDone:
    xor     eax, eax
    jmp     .wRet

.wDef:
    push    dword [ebp + 20]
    push    dword [ebp + 16]
    push    dword [ebp + 12]
    push    dword [ebp + 8]
    call    _DefWindowProcA@16
.wRet:
    pop     edi
    pop     esi
    pop     ebx
    pop     ebp
    ret     16

; ============================================================
StartGame:
    mov     dword [gameState], 1
    mov     dword [pScore], 0
    mov     dword [pLives], 3
    mov     dword [pScore2], 0
    mov     dword [pLives2], 3
    mov     dword [targIdx], 0
    mov     dword [lastSavedIdx],   -1
    mov     dword [lastSavedIdxP2], -1

    ; Reset player 1
    mov     dword [pX],        P1_SPAWNX
    mov     dword [pY],        SPAWN_Y
    mov     dword [pVY],       0
    mov     dword [pOnG],      0
    mov     dword [kL],        0
    mov     dword [kR],        0
    mov     dword [kJump],     0
    mov     dword [kJumpPrev], 0
    mov     dword [invT],      0
    ; pScore and pLives already reset above

    ; Reset player 2 (always, so toggling 2P->1P->2P is clean)
    mov     dword [pX2],        P2_SPAWNX
    mov     dword [pY2],        SPAWN_Y
    mov     dword [pVY2],       0
    mov     dword [pOnG2],      0
    mov     dword [kL2],        0
    mov     dword [kR2],        0
    mov     dword [kJump2],     0
    mov     dword [kJumpPrev2], 0
    mov     dword [invT2],      0
    ; pScore2 and pLives2 already reset above

    ; Set sequence by mode
    cmp     dword [gameMode], MODE_NUMBERS
    je      .mN
    cmp     dword [gameMode], MODE_SHAPES
    je      .mS
    ; default: letters
    mov     dword [seqPtr], letters
    mov     eax, [letLen]
    jmp     .mD
.mN:
    mov     dword [seqPtr], numbers
    mov     eax, [numLen]
    jmp     .mD
.mS:
    mov     dword [seqPtr], shapes
    mov     eax, [shpLen]
.mD:
    mov     [seqLen], eax

    ; Set collectible box dimensions based on mode
    cmp     dword [gameMode], MODE_SHAPES
    jne     .sgBoxLN
    mov     dword [boxW], BOX_W_SH
    mov     dword [boxH], BOX_H_SH
    jmp     .sgBoxDone
.sgBoxLN:
    mov     dword [boxW], BOX_W_LN
    mov     dword [boxH], BOX_H_LN
.sgBoxDone:

    ; Set initial target character
    mov     esi, [seqPtr]
    movzx   eax, byte [esi]
    mov     [targChar], al

    ; Apply difficulty: map [difficulty] to [collActive]
    cmp     dword [difficulty], DIFF_EASY
    jne     .sgNotE
    mov     dword [collActive], COLL_EASY
    jmp     .sgDiffDone
.sgNotE:
    cmp     dword [difficulty], DIFF_MED
    jne     .sgHard
    mov     dword [collActive], COLL_MED
    jmp     .sgDiffDone
.sgHard:
    mov     dword [collActive], COLL_HARD
.sgDiffDone:

    call    SetupCollectibles
    ret

; ============================================================
;  SetupCollectibles — single pass: sets position, char, flags
;  for each collectible atomically. No two-phase bugs.
;
;  Collectible format (20 bytes each):
;    +0  x position
;    +4  y position
;    +8  ASCII character code
;    +12 isCorrect (1 or 0)
;    +16 collected (0)
;
;  Invariants maintained:
;    targIdx ∈ [0, seqLen)
;    correct-box charCode == seqPtr[targIdx] == targChar (HUD)
;    wrong-box charCode  ∈ seqPtr[0..seqLen-1] \ {seqPtr[targIdx]}
;    No special chars or cross-mode chars appear because every
;    per-box char is drawn from the active seqPtr only.
; ============================================================
SetupCollectibles:
    push    ebp
    mov     ebp, esp
    push    ebx
    push    esi
    push    edi

    ; Local variable: char offsets for wrong items [+1, +2, +3, +5, +7]
    ; We'll hardcode these below per-collectible.

    mov     ecx, 0               ; i = collectible index (0..collActive-1)

.scLoop:
    cmp     ecx, [collActive]
    jge     .scInactive

    ; ---- 1. Compute platform index for this collectible ----
    ; platIdx = platOrder[(targIdx + i) % 10]
    push    ecx                  ; save i

    mov     eax, [targIdx]
    add     eax, ecx             ; targIdx + i
    xor     edx, edx
    mov     ebx, 10
    div     ebx                  ; edx = (targIdx + i) % 10

    lea     esi, [platOrder]
    mov     eax, [esi + edx * 4] ; platform index (1-10)

    ; ---- 2. Look up platform position ----
    mov     ebx, eax
    imul    ebx, 12              ; byte offset into platforms array
    lea     esi, [platforms]
    add     esi, ebx             ; esi -> platform entry

    mov     eax, [esi + 8]       ; plat.w
    sub     eax, [boxW]          ; plat.w - boxW
    sar     eax, 1               ; (plat.w - boxW) / 2
    add     eax, [esi]           ; plat.x + offset = centered x
    mov     ebx, [esi + 4]       ; plat.y
    sub     ebx, 30              ; sit above platform

    ; ---- 3. Compute dest pointer: &collectibles[i] ----
    pop     ecx                  ; restore i
    push    ecx                  ; save again

    mov     edx, ecx
    imul    edx, 20              ; byte offset
    lea     edi, [collectibles + edx]

    ; ---- 4. Write x, y ----
    mov     [edi + 0], eax       ; x
    mov     [edi + 4], ebx       ; y

    ; ---- 5. Write character + flags ----
    ; First collectible (i=0) is correct, rest are wrong.
    ; Char for i=0: seqPtr[targIdx]
    ; Char for i=N: seqPtr[(targIdx + offset_N) % seqLen]
    ;   offsets: i=1 -> +1, i=2 -> +2, i=3 -> +3, i=4 -> +5, i=5 -> +7

    mov     dword [edi + 16], 0  ; collected = 0

    cmp     ecx, 0
    jne     .scWrong

    ; ---- CORRECT item (i=0) ----
    mov     eax, [targIdx]
    mov     esi, [seqPtr]
    movzx   eax, byte [esi + eax]
    mov     [edi + 8], eax       ; charCode = target char
    mov     dword [edi + 12], 1  ; isCorrect = 1
    jmp     .scNext

.scWrong:
    ; ---- WRONG item (i=1..5) ----
    mov     dword [edi + 12], 0  ; isCorrect = 0

    ; Compute char offset based on i
    ; i=1->1, i=2->2, i=3->3, i=4->5, i=5->7
    mov     eax, ecx             ; eax = i
    cmp     eax, 4
    jl      .scOfsOk             ; i=1,2,3: offset = i itself
    je      .scOfs4
    ; i=5: offset=7
    mov     eax, 7
    jmp     .scOfsOk
.scOfs4:
    mov     eax, 5               ; i=4: offset=5
.scOfsOk:
    ; charIndex = (targIdx + offset) % seqLen
    add     eax, [targIdx]
    xor     edx, edx
    push    ecx
    mov     ecx, [seqLen]
    div     ecx                  ; edx = remainder
    pop     ecx

    mov     esi, [seqPtr]
    movzx   eax, byte [esi + edx]
    mov     [edi + 8], eax       ; charCode

.scNext:
    pop     ecx                  ; restore i
    inc     ecx
    jmp     .scLoop

; Mark remaining (inactive) slots as already-collected so Render and CheckCollect skip them
.scInactive:
    cmp     ecx, NCOLL
    jge     .scDone
    mov     edx, ecx
    imul    edx, 20
    lea     edi, [collectibles + edx]
    mov     dword [edi + 16], 1  ; collected = 1 (slot invisible and inert)
    inc     ecx
    jmp     .scInactive

.scDone:
    pop     edi
    pop     esi
    pop     ebx
    pop     ebp
    ret

; ============================================================
; GameUpdate — thin driver calling per-player helpers
; ============================================================
GameUpdate:
    mov     esi, player1
    call    PlayerPhysics
    mov     esi, player1
    call    CheckCollect
    cmp     dword [playerCount], 2
    jne     .gu_done
    mov     esi, player2
    call    PlayerPhysics
    mov     esi, player2
    call    CheckCollect
.gu_done:
    ret

; ============================================================
; PlayerPhysics — movement, gravity, platform collision, fall-off
; Input:  esi = player block pointer (player1 or player2)
; Effect: mutates [esi+PB_*]; decrements per-player [PB_LIVES] on fall-off;
;         sets gameState=2 (and optionally SaveScore) when lives hit 0
; ============================================================
PlayerPhysics:
    push    ebp
    mov     ebp, esp
    push    ebx
    push    esi
    push    edi

    ; Skip physics entirely for dead players
    cmp     dword [esi+PB_LIVES], 0
    je      .pp_ret

    ; --- Horizontal movement ---
    cmp     dword [esi+PB_KL], 1
    jne     .pp_nL
    sub     dword [esi+PB_X], SPEED
.pp_nL:
    cmp     dword [esi+PB_KR], 1
    jne     .pp_nR
    add     dword [esi+PB_X], SPEED
.pp_nR:

    ; --- Edge-triggered jump ---
    mov     eax, [esi+PB_KJ]
    cmp     eax, [esi+PB_KJP]
    je      .pp_nJ
    cmp     eax, 1
    jne     .pp_nJ
    cmp     dword [esi+PB_ONG], 1
    jne     .pp_nJ
    mov     dword [esi+PB_VY], JUMPF
    mov     dword [esi+PB_ONG], 0
.pp_nJ:
    mov     eax, [esi+PB_KJ]
    mov     [esi+PB_KJP], eax

    ; --- Gravity ---
    mov     eax, [esi+PB_VY]
    add     eax, GRAV
    cmp     eax, 12
    jle     .pp_vOk
    mov     eax, 12
.pp_vOk:
    mov     [esi+PB_VY], eax
    add     [esi+PB_Y], eax

    ; --- Bounds clamp X ---
    cmp     dword [esi+PB_X], 0
    jge     .pp_xL
    mov     dword [esi+PB_X], 0
.pp_xL:
    cmp     dword [esi+PB_X], SW - PW
    jle     .pp_xR
    mov     dword [esi+PB_X], SW - PW
.pp_xR:

    ; --- Platform collision (edi iterates platforms; esi stays player block) ---
    mov     dword [esi+PB_ONG], 0
    mov     ecx, NPLAT
    lea     edi, [platforms]
.pp_pLp:
    push    ecx
    mov     eax, [esi+PB_X]
    add     eax, PW
    cmp     eax, [edi]
    jle     .pp_pNx
    mov     eax, [esi+PB_X]
    mov     ebx, [edi]
    add     ebx, [edi + 8]
    cmp     eax, ebx
    jge     .pp_pNx
    cmp     dword [esi+PB_VY], 0
    jl      .pp_pNx
    mov     eax, [esi+PB_Y]
    add     eax, PH
    mov     ebx, [edi + 4]
    cmp     eax, ebx
    jl      .pp_pNx
    mov     ecx, ebx
    add     ecx, 16
    cmp     eax, ecx
    jg      .pp_pNx
    mov     eax, [edi + 4]
    sub     eax, PH
    mov     [esi+PB_Y], eax
    mov     dword [esi+PB_VY], 0
    mov     dword [esi+PB_ONG], 1
.pp_pNx:
    add     edi, 12
    pop     ecx
    dec     ecx
    jnz     .pp_pLp

    ; --- Fall off bottom ---
    cmp     dword [esi+PB_Y], SH + 20
    jl      .pp_nFall
    cmp     dword [esi+PB_INV], 0
    jg      .pp_fallRespawn     ; invincible: just respawn, no life loss
    dec     dword [esi+PB_LIVES]
    mov     dword [esi+PB_INV], 60
    cmp     dword [esi+PB_LIVES], 0
    jle     .pp_playerDied      ; out of lives — don't respawn
.pp_fallRespawn:
    cmp     esi, player1
    je      .pp_sp1
    mov     dword [esi+PB_X], P2_SPAWNX
    jmp     .pp_spd
.pp_sp1:
    mov     dword [esi+PB_X], P1_SPAWNX
.pp_spd:
    mov     dword [esi+PB_Y], SPAWN_Y
    mov     dword [esi+PB_VY], 0
    jmp     .pp_nFall
.pp_playerDied:
    call    CheckBothDead
.pp_nFall:

.pp_ret:
    pop     edi
    pop     esi
    pop     ebx
    pop     ebp
    ret

; ============================================================
; CheckCollect — collectible AABB, correct/wrong hit logic
; Input:  esi = player block pointer (player1 or player2)
; Effect: advances shared target/score on correct hit (respawns player);
;         decrements shared lives on wrong hit (per-player invT);
;         sets gameState=2 when lives reach 0
; ============================================================
CheckCollect:
    push    ebp
    mov     ebp, esp
    push    ebx
    push    esi
    push    edi

    ; Skip for dead players
    cmp     dword [esi+PB_LIVES], 0
    je      .cc_cEnd

    mov     ecx, NCOLL
    lea     edi, [collectibles]
.cc_cLp:
    push    ecx
    push    edi                     ; save collectible ptr across potential calls
    cmp     dword [edi + 16], 1
    je      .cc_cNx
    ; AABB overlap
    mov     eax, [esi+PB_X]
    add     eax, PW
    cmp     eax, [edi]
    jle     .cc_cNx
    mov     eax, [esi+PB_X]
    mov     ebx, [edi]
    add     ebx, [boxW]
    cmp     eax, ebx
    jge     .cc_cNx
    mov     eax, [esi+PB_Y]
    add     eax, PH
    cmp     eax, [edi + 4]
    jle     .cc_cNx
    mov     eax, [esi+PB_Y]
    mov     ebx, [edi + 4]
    add     ebx, [boxH]
    cmp     eax, ebx
    jge     .cc_cNx
    ; Hit — mark as collected
    mov     dword [edi + 16], 1
    cmp     dword [edi + 12], 1
    jne     .cc_wrong
    ; Correct item!
    mov     eax, wavPathOk
    call    PlaySFX
    add     dword [esi+PB_SCORE], 10
    inc     dword [targIdx]
    mov     eax, [targIdx]
    cmp     eax, [seqLen]
    jl      .cc_tOk
    mov     dword [targIdx], 0
.cc_tOk:
    mov     eax, [targIdx]
    mov     ebx, [seqPtr]
    movzx   eax, byte [ebx + eax]
    mov     [targChar], al
    call    SetupCollectibles       ; preserves esi and edi
    ; Respawn only the grabbing player to their own spawn point
    cmp     esi, player1
    je      .cc_sp1
    mov     dword [esi+PB_X], P2_SPAWNX
    jmp     .cc_spd
.cc_sp1:
    mov     dword [esi+PB_X], P1_SPAWNX
.cc_spd:
    mov     dword [esi+PB_Y], SPAWN_Y
    mov     dword [esi+PB_VY], 0
    pop     edi                     ; balance the push at loop top
    pop     ecx
    jmp     .cc_cEnd
.cc_wrong:
    dec     dword [esi+PB_LIVES]
    mov     dword [esi+PB_INV], 60
    mov     eax, wavPathErr
    call    PlaySFX
    cmp     dword [esi+PB_LIVES], 0
    jg      .cc_cNx
    ; Player died from wrong box
    call    CheckBothDead
.cc_cNx:
    pop     edi
    add     edi, 20
    pop     ecx
    dec     ecx
    jnz     .cc_cLp
.cc_cEnd:
    ; Decrement this player's invincibility timer
    cmp     dword [esi+PB_INV], 0
    jle     .cc_nInv
    dec     dword [esi+PB_INV]
.cc_nInv:
    pop     edi
    pop     esi
    pop     ebx
    pop     ebp
    ret

; ============================================================
; CheckBothDead — called when a player's lives reach 0.
; 1P: saves P1 score and sets gameState=2 immediately.
; 2P: waits until BOTH players' lives are 0 before saving scores
;     and ending the round.
; Preserves all registers (uses pushad/popad).
; ============================================================
CheckBothDead:
    pushad
    cmp     dword [playerCount], 2
    jne     .cbd_1p
    ; 2P: both must be out of lives before ending
    cmp     dword [pLives], 0
    jg      .cbd_done
    cmp     dword [pLives2], 0
    jg      .cbd_done
    ; Both dead — save both scores then end round
    call    SaveScore
    call    SaveScoreP2
    jmp     .cbd_go
.cbd_1p:
    cmp     dword [pLives], 0
    jg      .cbd_done
    call    SaveScore
.cbd_go:
    mov     dword [gameState], 2
.cbd_done:
    popad
    ret

; ============================================================
; DrawPlayerRect — blink-aware player rectangle draw
; Input: esi = player block pointer, edi = brush handle
; ============================================================
DrawPlayerRect:
    push    ebx
    ; Skip drawing dead players entirely
    cmp     dword [esi+PB_LIVES], 0
    je      .dpr_skip
    ; Skip drawing every other 4-frame window while invincible
    mov     eax, [esi+PB_INV]
    test    eax, eax
    jz      .dpr_draw
    and     eax, 4
    jnz     .dpr_skip
.dpr_draw:
    mov     eax, [esi+PB_X]
    mov     ebx, [esi+PB_Y]
    mov     ecx, eax
    add     ecx, PW
    mov     edx, ebx
    add     edx, PH
    call    FillBox
.dpr_skip:
    pop     ebx
    ret

; ============================================================
;  DrawBgBitmap — stretch a background HBITMAP to fill (0,0)-(SW,SH).
;  Input: eax = HBITMAP to display (must be non-zero).
;  Clobbers: eax. All other callee-save regs preserved by Win32 calls.
; ============================================================
DrawBgBitmap:
    ; Select bitmap into hdcImg, save old bitmap
    push    eax
    push    dword [hdcImg]
    call    _SelectObject@8
    mov     [hbmImgOld], eax

    ; Use HALFTONE mode for smooth stretching
    push    HALFTONE
    push    dword [hdcMem]
    call    _SetStretchBltMode@8

    ; StretchBlt(hdcMem, 0, 0, SW, SH, hdcImg, 0, 0, BMP_W, BMP_H, SRCCOPY)
    push    SRCCOPY
    push    BMP_H
    push    BMP_W
    push    dword 0
    push    dword 0
    push    dword [hdcImg]
    push    SH
    push    SW
    push    dword 0
    push    dword 0
    push    dword [hdcMem]
    call    _StretchBlt@44

    ; Restore old bitmap in hdcImg
    push    dword [hbmImgOld]
    push    dword [hdcImg]
    call    _SelectObject@8
    ret

; ============================================================
FillBox:  ; eax=L, ebx=T, ecx=R, edx=B, edi=brush
    sub     esp, 16
    mov     [esp + 0],  eax
    mov     [esp + 4],  ebx
    mov     [esp + 8],  ecx
    mov     [esp + 12], edx
    push    edi
    lea     eax, [esp + 4]
    push    eax
    push    dword [hdcMem]
    call    _FillRect@12
    add     esp, 16
    ret

; ============================================================
TextAt:  ; eax=x, ebx=y, esi=string, ecx=len
    push    ecx
    push    esi
    push    ebx
    push    eax
    push    dword [hdcMem]
    call    _TextOutA@20
    ret

; ============================================================
;  StrCopy — copy null-terminated string; edi advances past null
;  Input:  esi = source, edi = destination
;  Output: edi points at the null terminator just written
;  Preserves: esi, ebx
; ============================================================
StrCopy:
    push    eax
.sc_lp:
    mov     al, [esi]
    mov     [edi], al
    inc     esi
    inc     edi
    test    al, al
    jnz     .sc_lp
    dec     edi             ; leave edi pointing at the null byte
    pop     eax
    ret

; ============================================================
;  InitAudio — build full WAV paths from exe directory,
;  open BG music with MCI, start looping.
;  Preserves all registers (uses pushad/popad).
; ============================================================
InitAudio:
    pushad

    ; --- Load winmm.dll at runtime and resolve function pointers ---
    push    dllWinmm
    call    _LoadLibraryA@4
    test    eax, eax
    jz      .ia_done            ; winmm not loadable: skip audio entirely
    mov     [hWinmm], eax

    push    procPlay
    push    eax
    call    _GetProcAddress@8
    mov     [pfnPlay], eax

    push    procMci
    push    dword [hWinmm]
    call    _GetProcAddress@8
    mov     [pfnMci], eax

    ; --- Get full path of running exe ---
    push    dword 260
    push    exeDir
    push    dword 0
    call    _GetModuleFileNameA@12

    ; --- Trim to directory (find last backslash, null there+1) ---
    lea     esi, [exeDir]
    xor     ecx, ecx
.ia_scan:
    mov     al, [esi + ecx]
    test    al, al
    jz      .ia_trim
    inc     ecx
    jmp     .ia_scan
.ia_trim:
    ; ecx = length of full path; walk backwards to find last '\'
    dec     ecx
.ia_bs:
    cmp     byte [esi + ecx], '\'
    je      .ia_found_bs
    dec     ecx
    jnz     .ia_bs
.ia_found_bs:
    ; null-terminate one byte after the backslash (keep trailing '\')
    inc     ecx
    mov     byte [esi + ecx], 0

    ; --- Build wavPathBg = exeDir + wavBgName ---
    lea     esi, [exeDir]
    lea     edi, [wavPathBg]
    call    StrCopy          ; esi clobbered, edi at null
    lea     esi, [wavBgName]
    call    StrCopy

    ; --- Build wavPathErr = exeDir + wavErrName ---
    lea     esi, [exeDir]
    lea     edi, [wavPathErr]
    call    StrCopy
    lea     esi, [wavErrName]
    call    StrCopy

    ; --- Build wavPathOk = exeDir + wavOkName ---
    lea     esi, [exeDir]
    lea     edi, [wavPathOk]
    call    StrCopy
    lea     esi, [wavOkName]
    call    StrCopy

    ; --- Build sbPath = exeDir + sbFileName ---
    lea     esi, [exeDir]
    lea     edi, [sbPath]
    call    StrCopy
    lea     esi, [sbFileName]
    call    StrCopy

    ; --- Build mciOpenCmd = 'open "' + wavPathBg + '" type waveaudio alias bgmusic' ---
    lea     esi, [mciOpenPre]
    lea     edi, [mciOpenCmd]
    call    StrCopy
    lea     esi, [wavPathBg]
    call    StrCopy
    lea     esi, [mciOpenSuf]
    call    StrCopy

    ; --- Open the BG music device ---
    push    dword 0
    push    dword 0
    push    dword 0
    push    mciOpenCmd
    call    [pfnMci]

    ; --- Start playing, with notify so we can loop on completion ---
    push    dword [hWnd]
    push    dword 0
    push    dword 0
    push    mciPlayCmd
    call    [pfnMci]

.ia_done:
    popad
    ret

; ============================================================
;  StopAudio — stop and close the MCI BG music device.
;  Preserves all registers (uses pushad/popad).
; ============================================================
StopAudio:
    pushad
    cmp     dword [pfnMci], 0
    je      .stop_done
    push    dword 0
    push    dword 0
    push    dword 0
    push    mciStopCmd
    call    [pfnMci]
    push    dword 0
    push    dword 0
    push    dword 0
    push    mciCloseCmd
    call    [pfnMci]
.stop_done:
    popad
    ret

; ============================================================
;  InitBackgrounds — build full BMP paths from exe directory and
;  load both background bitmaps with LoadImageA.
;  exeDir must already be populated (call after InitAudio).
;  Preserves all registers (uses pushad/popad).
; ============================================================
InitBackgrounds:
    pushad

    ; --- Create reusable image DC once ---
    push    dword 0
    call    _CreateCompatibleDC@4
    mov     [hdcImg], eax

    ; --- Build bmp1Path = exeDir + bmp1Name ---
    lea     esi, [exeDir]
    lea     edi, [bmp1Path]
    call    StrCopy
    lea     esi, [bmp1Name]
    call    StrCopy

    ; --- Build bmp2Path = exeDir + bmp2Name ---
    lea     esi, [exeDir]
    lea     edi, [bmp2Path]
    call    StrCopy
    lea     esi, [bmp2Name]
    call    StrCopy

    ; --- Load stars1.bmp (in-game background) ---
    push    dword LR_LOADFROMFILE | LR_CREATEDIBSECTION
    push    dword 0             ; cy (0 = use actual size)
    push    dword 0             ; cx (0 = use actual size)
    push    dword IMAGE_BITMAP
    push    bmp1Path
    push    dword 0             ; hInstance NULL for LR_LOADFROMFILE
    call    _LoadImageA@24
    mov     [hbmStars1], eax

    ; --- Load stars2.bmp (menu/other-state background) ---
    push    dword LR_LOADFROMFILE | LR_CREATEDIBSECTION
    push    dword 0
    push    dword 0
    push    dword IMAGE_BITMAP
    push    bmp2Path
    push    dword 0
    call    _LoadImageA@24
    mov     [hbmStars2], eax

    popad
    ret

; ============================================================
;  PlaySFX — play a WAV file asynchronously (does not cut BG).
;  Input: eax = pointer to null-terminated WAV path string.
;  Preserves: ebx, esi, edi (Win32 convention + explicit save).
; ============================================================
%define SND_ASYNC     0x0001
%define SND_NODEFAULT 0x0002
%define SND_FILENAME  0x00020000

PlaySFX:
    cmp     dword [pfnPlay], 0
    je      .sfx_done
    push    ecx
    push    edx
    push    dword SND_ASYNC | SND_NODEFAULT | SND_FILENAME
    push    dword 0
    push    eax
    call    [pfnPlay]
    pop     edx
    pop     ecx
.sfx_done:
    ret

; ============================================================
;  DrawChar — draw the character stored directly in collectible
;  esi = pointer to collectible entry (charCode is at offset +8)
; ============================================================
DrawChar:
    push    ebx
    push    esi

    ; Get ASCII character code directly
    mov     eax, [esi + 8]
    cmp     eax, 32              ; printable range check
    jl      .dcEnd
    cmp     eax, 127
    jge     .dcEnd

    ; Put char on stack as null-terminated string
    sub     esp, 4
    mov     [esp], al
    mov     byte [esp + 1], 0

    ; Draw centered in 28x28 box
    mov     eax, [esi]
    add     eax, 8
    mov     ebx, [esi + 4]
    add     ebx, 5

    push    dword 1
    lea     ecx, [esp + 4]
    push    ecx
    push    ebx
    push    eax
    push    dword [hdcMem]
    call    _TextOutA@20
    add     esp, 4

.dcEnd:
    pop     esi
    pop     ebx
    ret

; ============================================================
;  DrawShapeName — draw centered shape name text inside a wide collectible box
;  Input: esi = collectible ptr (+0=x, +4=y, +8=shapeID)
;  Clobbers: eax, ebx, ecx, edx (caller must preserve esi around the call)
; ============================================================
DrawShapeName:
    push    ebp
    mov     ebp, esp
    push    ebx
    push    esi
    push    edi

    mov     eax, [esi + 8]          ; shape ID 0..7
    cmp     eax, 0
    jl      .dsnEnd
    cmp     eax, 8
    jge     .dsnEnd

    ; Look up name ptr and length
    mov     edi, [shapeNamePtrs + eax*4]   ; edi = string ptr (saved across Win32 calls)
    mov     ecx, [shapeNameLens + eax*4]   ; ecx = length

    ; Center-align inside box: x = box.x + boxW/2
    mov     eax, [esi]              ; box.x
    mov     edx, [boxW]
    sar     edx, 1                  ; boxW / 2
    add     eax, edx                ; center x

    mov     ebx, [esi + 4]          ; box.y
    add     ebx, 8                  ; vertical padding (box is 30px tall)

    ; Set center alignment, draw, restore left alignment
    push    ecx
    push    eax
    push    ebx                     ; save x/y/len across Win32 calls
    push    TA_CENTER
    push    dword [hdcMem]
    call    _SetTextAlign@8
    pop     ebx
    pop     eax
    pop     ecx

    mov     esi, edi                ; esi = string ptr for TextAt
    call    TextAt

    push    TA_LEFT
    push    dword [hdcMem]
    call    _SetTextAlign@8

.dsnEnd:
    pop     edi
    pop     esi
    pop     ebx
    mov     esp, ebp
    pop     ebp
    ret

; ============================================================
;  DrawShapeFigure — draw filled GDI shape in top-right corner
;  Input: eax = shape ID (0=circle, 1..7=polygon)
;  Anchor: center (745, 85), radius ~40, region x=700..790, y=40..130
; ============================================================
DrawShapeFigure:
    push    ebp
    mov     ebp, esp
    push    ebx
    push    esi
    push    edi
    push    eax                     ; save shape ID

    ; Select NULL pen (no outline) onto hdcMem, save old pen
    push    dword [hPenNull]
    push    dword [hdcMem]
    call    _SelectObject@8
    mov     [hPenOld], eax

    ; Select shape brush onto hdcMem, save old brush
    push    dword [brShape]
    push    dword [hdcMem]
    call    _SelectObject@8
    mov     [hBrShOld], eax

    pop     eax                     ; restore shape ID

    cmp     eax, SHAPE_CIRCLE
    jne     .dsfPoly

    ; Circle: Ellipse(hdc, left=705, top=45, right=785, bottom=125) — 80x80
    push    dword 125
    push    dword 785
    push    dword 45
    push    dword 705
    push    dword [hdcMem]
    call    _Ellipse@20
    jmp     .dsfRestore

.dsfPoly:
    ; Polygon(hdc, LPPOINT, nCount)
    mov     ebx, [shapeVcnt + eax*4]
    mov     esi, [shapeVerts + eax*4]
    push    ebx
    push    esi
    push    dword [hdcMem]
    call    _Polygon@12

.dsfRestore:
    ; Restore old brush
    push    dword [hBrShOld]
    push    dword [hdcMem]
    call    _SelectObject@8

    ; Restore old pen
    push    dword [hPenOld]
    push    dword [hdcMem]
    call    _SelectObject@8

    pop     edi
    pop     esi
    pop     ebx
    mov     esp, ebp
    pop     ebp
    ret

; ============================================================
Render:
    push    ebp
    mov     ebp, esp
    push    ebx
    push    esi
    push    edi

    ; Background — bitmap when available, solid C_BG fallback otherwise
    cmp     dword [gameState], 1
    jne     .bgMenuImg
    mov     eax, [hbmStars1]
    jmp     .bgDoImg
.bgMenuImg:
    mov     eax, [hbmStars2]
.bgDoImg:
    test    eax, eax
    jz      .bgSolid
    call    DrawBgBitmap
    jmp     .bgDone
.bgSolid:
    mov     eax, 0
    mov     ebx, 0
    mov     ecx, SW
    mov     edx, SH
    mov     edi, [brBg]
    call    FillBox
.bgDone:

    push    TRANSPARENT
    push    dword [hdcMem]
    call    _SetBkMode@8

    cmp     dword [gameState], 0
    je      .rMenu
    cmp     dword [gameState], 2
    je      .rGO
    cmp     dword [gameState], 3
    je      .rLogin
    cmp     dword [gameState], 4
    je      .rDiff
    cmp     dword [gameState], 5
    je      .rTeamLogin
    cmp     dword [gameState], 6
    je      .rScoreboard
    jmp     .rPlay

; =========== LOGIN ===========
.rLogin:
    push    TA_CENTER
    push    dword [hdcMem]
    call    _SetTextAlign@8

    ; Title
    push    C_TITLE
    push    dword [hdcMem]
    call    _SetTextColor@8
    mov     eax, 400
    mov     ebx, 200
    mov     esi, sLoginTitle
    mov     ecx, [sLoginTitleLen]
    call    TextAt

    ; Input field background (dark box)
    mov     eax, 250
    mov     ebx, 278
    mov     ecx, 550
    mov     edx, 318
    mov     edi, [brDark]
    call    FillBox

    ; Current typed name (bright yellow, centered in box)
    push    C_CORRECT
    push    dword [hdcMem]
    call    _SetTextColor@8
    mov     eax, 400
    mov     ebx, 285
    mov     esi, playerName
    mov     ecx, [nameLen]
    call    TextAt

    ; Hint at bottom
    push    C_GRAY
    push    dword [hdcMem]
    call    _SetTextColor@8
    mov     eax, 400
    mov     ebx, 400
    mov     esi, sLoginHint
    mov     ecx, [sLoginHintLen]
    call    TextAt

    push    TA_LEFT
    push    dword [hdcMem]
    call    _SetTextAlign@8
    jmp     .rEnd

; =========== PLAYER 2 NAME INPUT (state 5) ===========
.rTeamLogin:
    push    TA_CENTER
    push    dword [hdcMem]
    call    _SetTextAlign@8

    push    C_TITLE
    push    dword [hdcMem]
    call    _SetTextColor@8
    mov     eax, 400
    mov     ebx, 200
    mov     esi, sTeamTitle
    mov     ecx, [sTeamTitleLen]
    call    TextAt

    ; Input field background
    mov     eax, 250
    mov     ebx, 278
    mov     ecx, 550
    mov     edx, 318
    mov     edi, [brDark]
    call    FillBox

    ; Current typed player 2 name
    push    C_CORRECT
    push    dword [hdcMem]
    call    _SetTextColor@8
    mov     eax, 400
    mov     ebx, 285
    mov     esi, player2Name
    mov     ecx, [player2NameLen]
    call    TextAt

    ; Hint
    push    C_GRAY
    push    dword [hdcMem]
    call    _SetTextColor@8
    mov     eax, 400
    mov     ebx, 400
    mov     esi, sLoginHint
    mov     ecx, [sLoginHintLen]
    call    TextAt

    push    TA_LEFT
    push    dword [hdcMem]
    call    _SetTextAlign@8
    jmp     .rEnd

; =========== DIFFICULTY SELECT ===========
.rDiff:
    push    TA_CENTER
    push    dword [hdcMem]
    call    _SetTextAlign@8

    push    C_TITLE
    push    dword [hdcMem]
    call    _SetTextColor@8
    mov     eax, 400
    mov     ebx, 200
    mov     esi, sDiffTitle
    mov     ecx, [sDiffTitleLen]
    call    TextAt

    push    C_HUD
    push    dword [hdcMem]
    call    _SetTextColor@8
    mov     eax, 400
    mov     ebx, 290
    mov     esi, sDiffEasy
    mov     ecx, [sDiffEasyLen]
    call    TextAt
    mov     eax, 400
    mov     ebx, 340
    mov     esi, sDiffMed
    mov     ecx, [sDiffMedLen]
    call    TextAt
    mov     eax, 400
    mov     ebx, 390
    mov     esi, sDiffHard
    mov     ecx, [sDiffHardLen]
    call    TextAt

    ; Hint — switch back to TA_CENTER
    push    TA_CENTER
    push    dword [hdcMem]
    call    _SetTextAlign@8
    push    C_GRAY
    push    dword [hdcMem]
    call    _SetTextColor@8
    mov     eax, 400
    mov     ebx, 470
    mov     esi, sDiffBack
    mov     ecx, [sDiffBackLen]
    call    TextAt
    jmp     .rEnd

; =========== SCOREBOARD SCREEN (state 6) ===========
.rScoreboard:
    push    TA_CENTER
    push    dword [hdcMem]
    call    _SetTextAlign@8

    push    C_TITLE
    push    dword [hdcMem]
    call    _SetTextColor@8
    mov     eax, 400
    mov     ebx, 90
    mov     esi, sHiTitleS
    mov     ecx, [sHiTitleSLen]
    call    TextAt

    push    TA_LEFT
    push    dword [hdcMem]
    call    _SetTextAlign@8

    mov     eax, [sbCount]
    mov     [sbActiveCount], eax
    mov     dword [sbActiveBase], scoreboard
    mov     ebx, 150
    mov     ecx, 10
    mov     edx, 0
    mov     edi, -1
    call    RenderScoreboard

    push    TA_CENTER
    push    dword [hdcMem]
    call    _SetTextAlign@8
    push    C_GRAY
    push    dword [hdcMem]
    call    _SetTextColor@8
    mov     eax, 400
    mov     ebx, 535
    mov     esi, sDiffBack
    mov     ecx, [sDiffBackLen]
    call    TextAt

    push    TA_LEFT
    push    dword [hdcMem]
    call    _SetTextAlign@8
    jmp     .rEnd

; =========== MENU ===========
.rMenu:
    ; Set center alignment — x=400 is screen center
    push    TA_CENTER
    push    dword [hdcMem]
    call    _SetTextAlign@8

    ; --- Switch to large bold title font ---
    push    dword [hFontTitle]
    push    dword [hdcMem]
    call    _SelectObject@8
    mov     [hFontOld], eax

    push    C_TITLE
    push    dword [hdcMem]
    call    _SetTextColor@8
    mov     eax, 400
    mov     ebx, 70
    mov     esi, sTitle
    mov     ecx, [sTitleLen]
    call    TextAt

    push    C_WHITE
    push    dword [hdcMem]
    call    _SetTextColor@8
    mov     eax, 400
    mov     ebx, 130
    mov     esi, sTitle2
    mov     ecx, [sTitle2Len]
    call    TextAt

    ; --- Restore default font for the rest of the menu ---
    push    dword [hFontOld]
    push    dword [hdcMem]
    call    _SelectObject@8

    push    C_HUD
    push    dword [hdcMem]
    call    _SetTextColor@8
    mov     eax, 400
    mov     ebx, 275
    mov     esi, sMenu1
    mov     ecx, [sMenu1Len]
    call    TextAt
    mov     eax, 400
    mov     ebx, 305
    mov     esi, sMenu2
    mov     ecx, [sMenu2Len]
    call    TextAt
    mov     eax, 400
    mov     ebx, 335
    mov     esi, sMenu3Game
    mov     ecx, [sMenu3GameLen]
    call    TextAt
    push    C_GRAY
    push    dword [hdcMem]
    call    _SetTextColor@8
    mov     eax, 400
    mov     ebx, 370
    mov     esi, sMenu4
    mov     ecx, [sMenu4Len]
    call    TextAt

    ; [5] player-count toggle row — pick string by current mode
    push    C_HUD
    push    dword [hdcMem]
    call    _SetTextColor@8
    mov     eax, 400
    mov     ebx, 400
    cmp     dword [playerCount], 2
    je      .rM5_2P
    mov     esi, sMenu5_1P
    mov     ecx, [sMenu5_1PLen]
    jmp     .rM5_draw
.rM5_2P:
    mov     esi, sMenu5_2P
    mov     ecx, [sMenu5_2PLen]
.rM5_draw:
    call    TextAt

    ; [6] Change Player 2 Name — only in 2P mode
    cmp     dword [playerCount], 2
    jne     .rM6_skip
    push    C_GRAY
    push    dword [hdcMem]
    call    _SetTextColor@8
    mov     eax, 400
    mov     ebx, 435
    mov     esi, sMenu6
    mov     ecx, [sMenu6Len]
    call    TextAt
.rM6_skip:

    ; [0] Top Scores
    push    C_GRAY
    push    dword [hdcMem]
    call    _SetTextColor@8
    mov     eax, 400
    mov     ebx, 470
    mov     esi, sMenu0
    mov     ecx, [sMenu0Len]
    call    TextAt

    ; Prompt
    push    TA_CENTER
    push    dword [hdcMem]
    call    _SetTextAlign@8
    push    C_GRAY
    push    dword [hdcMem]
    call    _SetTextColor@8
    mov     eax, 400
    mov     ebx, 525
    mov     esi, sPrompt
    mov     ecx, [sPromptLen]
    call    TextAt

    jmp     .rEnd

; =========== GAME OVER ===========
.rGO:
    push    TA_CENTER
    push    dword [hdcMem]
    call    _SetTextAlign@8

    push    C_WRONG
    push    dword [hdcMem]
    call    _SetTextColor@8
    mov     eax, 400
    mov     ebx, 70
    mov     esi, sGameOver
    mov     ecx, [sGOLen]
    call    TextAt

    ; Branch on player count for different game-over layouts
    cmp     dword [playerCount], 2
    je      .rGO_2P

    ; ---- 1P game-over ----
    push    C_HUD
    push    dword [hdcMem]
    call    _SetTextColor@8
    mov     eax, 400
    mov     ebx, 110
    mov     esi, playerName
    mov     ecx, [nameLen]
    call    TextAt

    push    C_WHITE
    push    dword [hdcMem]
    call    _SetTextColor@8
    mov     eax, 400
    mov     ebx, 145
    mov     esi, sScoreLbl
    mov     ecx, [sScoreLblLen]
    call    TextAt

    mov     eax, [pScore]
    call    IntToStr
    xor     ecx, ecx
.rGO_sl:
    cmp     byte [digitBuf + ecx], 0
    je      .rGO_sld
    inc     ecx
    jmp     .rGO_sl
.rGO_sld:
    mov     eax, 400
    mov     ebx, 165
    mov     esi, digitBuf
    call    TextAt

    push    C_TITLE
    push    dword [hdcMem]
    call    _SetTextColor@8
    mov     eax, 400
    mov     ebx, 210
    mov     esi, sHiTitle
    mov     ecx, [sHiTitleLen]
    call    TextAt

    push    TA_LEFT
    push    dword [hdcMem]
    call    _SetTextAlign@8

    mov     eax, [sbCount]
    mov     [sbActiveCount], eax
    mov     dword [sbActiveBase], scoreboard
    mov     edi, [lastSavedIdx]
    mov     ebx, 240
    mov     ecx, 10
    mov     edx, 0
    call    RenderScoreboard

    jmp     .rGO_hint

    ; ---- 2P game-over ----
.rGO_2P:
    ; P1 name + score (yellow)
    push    C_PLAYER
    push    dword [hdcMem]
    call    _SetTextColor@8
    mov     eax, 400
    mov     ebx, 100
    mov     esi, playerName
    mov     ecx, [nameLen]
    call    TextAt

    push    C_WHITE
    push    dword [hdcMem]
    call    _SetTextColor@8
    mov     eax, [pScore]
    call    IntToStr
    xor     ecx, ecx
.rGO2_sl1:
    cmp     byte [digitBuf + ecx], 0
    je      .rGO2_sl1d
    inc     ecx
    jmp     .rGO2_sl1
.rGO2_sl1d:
    mov     eax, 400
    mov     ebx, 122
    mov     esi, digitBuf
    call    TextAt

    ; P2 name + score (magenta)
    push    C_PLAYER2
    push    dword [hdcMem]
    call    _SetTextColor@8
    mov     eax, 400
    mov     ebx, 148
    mov     esi, player2Name
    mov     ecx, [player2NameLen]
    call    TextAt

    push    C_WHITE
    push    dword [hdcMem]
    call    _SetTextColor@8
    mov     eax, [pScore2]
    call    IntToStr
    xor     ecx, ecx
.rGO2_sl2:
    cmp     byte [digitBuf + ecx], 0
    je      .rGO2_sl2d
    inc     ecx
    jmp     .rGO2_sl2
.rGO2_sl2d:
    mov     eax, 400
    mov     ebx, 170
    mov     esi, digitBuf
    call    TextAt

    ; "TOP SCORES" header
    push    C_TITLE
    push    dword [hdcMem]
    call    _SetTextColor@8
    mov     eax, 400
    mov     ebx, 200
    mov     esi, sHiTitleS
    mov     ecx, [sHiTitleSLen]
    call    TextAt

    push    TA_LEFT
    push    dword [hdcMem]
    call    _SetTextAlign@8

    ; Full 10-row unified scoreboard; P1 highlight via edi, P2 via global lastSavedIdxP2
    mov     eax, [sbCount]
    mov     [sbActiveCount], eax
    mov     dword [sbActiveBase], scoreboard
    mov     edi, [lastSavedIdx]
    mov     ebx, 230
    mov     ecx, 10
    mov     edx, 0
    call    RenderScoreboard

.rGO_hint:
    ; Restart hint (centered)
    push    TA_CENTER
    push    dword [hdcMem]
    call    _SetTextAlign@8
    push    C_GRAY
    push    dword [hdcMem]
    call    _SetTextColor@8
    mov     eax, 400
    mov     ebx, 515
    mov     esi, sRestart
    mov     ecx, [sRestartLen]
    call    TextAt

    push    TA_LEFT
    push    dword [hdcMem]
    call    _SetTextAlign@8
    jmp     .rEnd

; =========== PLAYING ===========
.rPlay:
    ; Ensure left-aligned text for all HUD and in-game draws
    push    TA_LEFT
    push    dword [hdcMem]
    call    _SetTextAlign@8

    ; Ground
    mov     eax, 0
    mov     ebx, 540
    mov     ecx, SW
    mov     edx, SH
    mov     edi, [brGround]
    call    FillBox

    ; Floating platforms (skip ground at index 0)
    mov     ecx, NPLAT - 1
    lea     esi, [platforms + 12]
.rPLp:
    push    ecx
    push    esi
    mov     eax, [esi]
    mov     ebx, [esi + 4]
    mov     ecx, eax
    add     ecx, [esi + 8]
    mov     edx, ebx
    add     edx, 14
    mov     edi, [brPlat]
    call    FillBox
    pop     esi
    add     esi, 12
    pop     ecx
    dec     ecx
    jnz     .rPLp

    ; Draw shape figure in top-right corner (shapes mode only)
    cmp     dword [gameMode], MODE_SHAPES
    jne     .rPlayPostFigure
    mov     ebx, [seqPtr]
    mov     ecx, [targIdx]
    movzx   eax, byte [ebx + ecx]   ; current shape ID
    call    DrawShapeFigure
.rPlayPostFigure:

    ; Collectibles
    mov     ecx, NCOLL
    lea     esi, [collectibles]
.rCLp:
    push    ecx
    push    esi
    cmp     dword [esi + 16], 1
    je      .rCSkip

    ; Draw colored box (dimensions from [boxW]/[boxH])
    mov     eax, [esi]
    mov     ebx, [esi + 4]
    mov     ecx, eax
    add     ecx, [boxW]
    mov     edx, ebx
    add     edx, [boxH]
    cmp     dword [esi + 12], 1
    jne     .rCW
    mov     edi, [brCorrect]
    jmp     .rCDo
.rCW:
    mov     edi, [brWrong]
.rCDo:
    call    FillBox

    ; Refresh correct-box charCode to guarantee FIND/box parity
    cmp     dword [esi + 12], 1     ; isCorrect?
    jne     .rC_charOk
    mov     eax, [seqPtr]
    add     eax, [targIdx]
    movzx   eax, byte [eax]
    mov     [esi + 8], eax          ; refresh charCode == seqPtr[targIdx]
.rC_charOk:

    ; Draw box content: shape name text (shapes mode) or single char (L/N mode)
    push    C_BG
    push    dword [hdcMem]
    call    _SetTextColor@8
    cmp     dword [gameMode], MODE_SHAPES
    je      .rCDrawShName
    call    DrawChar
    jmp     .rCNext
.rCDrawShName:
    call    DrawShapeName
.rCNext:

.rCSkip:
    pop     esi
    add     esi, 20
    pop     ecx
    dec     ecx
    jnz     .rCLp

    ; Draw player(s) — blink handled inside DrawPlayerRect
    mov     esi, player1
    mov     edi, [brPlayer]
    call    DrawPlayerRect
    cmp     dword [playerCount], 2
    jne     .rPSkip
    mov     esi, player2
    mov     edi, [brPlayer2]
    call    DrawPlayerRect
.rPSkip:

    ; ---- HUD bar at top ----
    mov     eax, 0
    mov     ebx, 0
    mov     ecx, SW
    mov     edx, 24
    mov     edi, [brDark]
    call    FillBox

    ; Branch on player count for HUD layout
    cmp     dword [playerCount], 2
    je      .rHUD2P

    ; ---- 1P HUD ----
    push    C_HUD
    push    dword [hdcMem]
    call    _SetTextColor@8

    ; "STARS: "
    mov     eax, 10
    mov     ebx, 4
    mov     esi, sStars
    mov     ecx, 7
    call    TextAt

    ; Score value
    mov     eax, [pScore]
    call    IntToStr
    mov     eax, 80
    mov     ebx, 4
    mov     esi, digitBuf
    mov     ecx, 3
    call    TextAt

    ; "DIFF: " + single char (E/M/H)
    push    C_HUD
    push    dword [hdcMem]
    call    _SetTextColor@8
    mov     eax, 180
    mov     ebx, 4
    mov     esi, sDiffHud
    mov     ecx, [sDiffHudLen]
    call    TextAt

    ; Set diff color FIRST (before resolving string) so _SetTextColor@8 can't clobber ecx
    push    C_CORRECT
    push    dword [hdcMem]
    call    _SetTextColor@8

    ; Resolve [difficulty] -> full word string
    mov     eax, [difficulty]
    cmp     eax, DIFF_EASY
    jne     .hudDiffNotE
    mov     esi, sDiffEasyW
    mov     ecx, [sDiffEasyWLen]
    jmp     .hudDiffDraw
.hudDiffNotE:
    cmp     eax, DIFF_MED
    jne     .hudDiffH
    mov     esi, sDiffMedW
    mov     ecx, [sDiffMedWLen]
    jmp     .hudDiffDraw
.hudDiffH:
    mov     esi, sDiffHardW
    mov     ecx, [sDiffHardWLen]
.hudDiffDraw:
    mov     eax, 232
    mov     ebx, 4
    call    TextAt

    ; "FIND: " + target character
    push    C_TITLE
    push    dword [hdcMem]
    call    _SetTextColor@8
    mov     eax, 340
    mov     ebx, 4
    mov     esi, sFind
    mov     ecx, 7
    call    TextAt

    ; Recompute targChar fresh from seqPtr[targIdx]
    mov     ebx, [seqPtr]
    mov     ecx, [targIdx]
    mov     al, byte [ebx + ecx]
    mov     [targChar], al

    ; Target: shape name (shapes mode) or single char (L/N mode)
    push    C_CORRECT
    push    dword [hdcMem]
    call    _SetTextColor@8
    cmp     dword [gameMode], MODE_SHAPES
    jne     .hudFindChar1P
    ; Shapes: draw full name text at x=410
    movzx   eax, byte [targChar]
    mov     esi, [shapeNamePtrs + eax*4]
    mov     ecx, [shapeNameLens + eax*4]
    mov     eax, 410
    mov     ebx, 4
    call    TextAt
    jmp     .hudFindDone1P
.hudFindChar1P:
    mov     eax, 410
    mov     ebx, 4
    push    dword 1
    push    targChar
    push    ebx
    push    eax
    push    dword [hdcMem]
    call    _TextOutA@20
.hudFindDone1P:

    ; "LIVES: "
    push    C_HUD
    push    dword [hdcMem]
    call    _SetTextColor@8
    mov     eax, 660
    mov     ebx, 4
    mov     esi, sLives
    mov     ecx, 7
    call    TextAt

    ; Lives value
    mov     eax, [pLives]
    call    IntToStr
    mov     eax, 730
    mov     ebx, 4
    mov     esi, digitBuf
    mov     ecx, 1
    call    TextAt

    jmp     .rEnd

    ; ---- 2P competitive HUD ----
.rHUD2P:
    ; P1 info (left, yellow)
    push    C_PLAYER
    push    dword [hdcMem]
    call    _SetTextColor@8
    mov     eax, 10
    mov     ebx, 4
    mov     esi, sP1Hud
    mov     ecx, [sP1HudLen]
    call    TextAt

    ; P1 score value
    mov     eax, [pScore]
    call    IntToStr
    xor     ecx, ecx
.rH2P_sl1:
    cmp     byte [digitBuf + ecx], 0
    je      .rH2P_sl1d
    inc     ecx
    jmp     .rH2P_sl1
.rH2P_sl1d:
    mov     eax, 60
    mov     ebx, 4
    mov     esi, digitBuf
    call    TextAt

    ; " L:" label
    push    C_HUD
    push    dword [hdcMem]
    call    _SetTextColor@8
    mov     eax, 100
    mov     ebx, 4
    mov     esi, sLHud
    mov     ecx, [sLHudLen]
    call    TextAt

    ; P1 lives value
    push    C_PLAYER
    push    dword [hdcMem]
    call    _SetTextColor@8
    mov     eax, [pLives]
    call    IntToStr
    mov     eax, 130
    mov     ebx, 4
    mov     esi, digitBuf
    mov     ecx, 1
    call    TextAt

    ; Center: recompute targChar
    mov     ebx, [seqPtr]
    mov     ecx, [targIdx]
    mov     al, byte [ebx + ecx]
    mov     [targChar], al

    ; "FIND: " (title color) — shifted to center for MEDIUM word
    push    C_TITLE
    push    dword [hdcMem]
    call    _SetTextColor@8
    mov     eax, 215
    mov     ebx, 4
    mov     esi, sFind
    mov     ecx, 7
    call    TextAt

    ; Target: shape name (shapes mode) or single char (L/N mode)
    push    C_CORRECT
    push    dword [hdcMem]
    call    _SetTextColor@8
    cmp     dword [gameMode], MODE_SHAPES
    jne     .hudFindChar2P
    ; Shapes: draw full name text at x=285
    movzx   eax, byte [targChar]
    mov     esi, [shapeNamePtrs + eax*4]
    mov     ecx, [shapeNameLens + eax*4]
    mov     eax, 285
    mov     ebx, 4
    call    TextAt
    jmp     .hudFindDone2P
.hudFindChar2P:
    mov     eax, 285
    mov     ebx, 4
    push    dword 1
    push    targChar
    push    ebx
    push    eax
    push    dword [hdcMem]
    call    _TextOutA@20
.hudFindDone2P:

    ; "DIFF: " label
    push    C_HUD
    push    dword [hdcMem]
    call    _SetTextColor@8
    mov     eax, 470
    mov     ebx, 4
    mov     esi, sDiffHud
    mov     ecx, [sDiffHudLen]
    call    TextAt

    ; Set diff color FIRST so _SetTextColor@8 can't clobber ecx before TextAt
    push    C_CORRECT
    push    dword [hdcMem]
    call    _SetTextColor@8

    ; Resolve [difficulty] -> full word string
    mov     eax, [difficulty]
    cmp     eax, DIFF_EASY
    jne     .rH2P_dNE
    mov     esi, sDiffEasyW
    mov     ecx, [sDiffEasyWLen]
    jmp     .rH2P_dDraw
.rH2P_dNE:
    cmp     eax, DIFF_MED
    jne     .rH2P_dH
    mov     esi, sDiffMedW
    mov     ecx, [sDiffMedWLen]
    jmp     .rH2P_dDraw
.rH2P_dH:
    mov     esi, sDiffHardW
    mov     ecx, [sDiffHardWLen]
.rH2P_dDraw:
    mov     eax, 522
    mov     ebx, 4
    call    TextAt

    ; P2 info (flush right, magenta)
    push    C_PLAYER2
    push    dword [hdcMem]
    call    _SetTextColor@8
    mov     eax, 650
    mov     ebx, 4
    mov     esi, sP2Hud
    mov     ecx, [sP2HudLen]
    call    TextAt

    ; P2 score value
    mov     eax, [pScore2]
    call    IntToStr
    xor     ecx, ecx
.rH2P_sl2:
    cmp     byte [digitBuf + ecx], 0
    je      .rH2P_sl2d
    inc     ecx
    jmp     .rH2P_sl2
.rH2P_sl2d:
    mov     eax, 700
    mov     ebx, 4
    mov     esi, digitBuf
    call    TextAt

    ; " L:" label
    push    C_HUD
    push    dword [hdcMem]
    call    _SetTextColor@8
    mov     eax, 740
    mov     ebx, 4
    mov     esi, sLHud
    mov     ecx, [sLHudLen]
    call    TextAt

    ; P2 lives value
    push    C_PLAYER2
    push    dword [hdcMem]
    call    _SetTextColor@8
    mov     eax, [pLives2]
    call    IntToStr
    mov     eax, 770
    mov     ebx, 4
    mov     esi, digitBuf
    mov     ecx, 1
    call    TextAt

.rEnd:
    pop     edi
    pop     esi
    pop     ebx
    pop     ebp
    ret

; ============================================================
IntToStr:  ; eax = number -> digitBuf
    push    ebx
    push    ecx
    push    edx
    push    edi
    ; Clear buffer
    lea     edi, [digitBuf]
    mov     byte [edi], '0'
    mov     byte [edi + 1], 0
    test    eax, eax
    jz      .isDone
    mov     ecx, 0
    mov     ebx, 10
.iDiv:
    xor     edx, edx
    div     ebx
    add     dl, '0'
    push    edx
    inc     ecx
    test    eax, eax
    jnz     .iDiv
    lea     edi, [digitBuf]
.iPop:
    pop     eax
    mov     [edi], al
    inc     edi
    dec     ecx
    jnz     .iPop
    mov     byte [edi], 0
.isDone:
    pop     edi
    pop     edx
    pop     ecx
    pop     ebx
    ret

; ============================================================
;  LoginInput — called from WM_KEYDOWN while gameState == 3
;  eax = VK code (already loaded by caller)
;  Appends A-Z letters, handles BACKSPACE, transitions to state 0 on ENTER.
; ============================================================
LoginInput:
    push    ebx

    ; ENTER: require at least 1 char then move to menu
    cmp     eax, VK_RETURN
    jne     .liNotEnter
    cmp     dword [nameLen], 1
    jl      .liDone
    mov     dword [gameState], 0
    jmp     .liDone

.liNotEnter:
    ; BACKSPACE: delete last character
    cmp     eax, VK_BACK
    jne     .liNotBack
    cmp     dword [nameLen], 0
    jle     .liDone
    dec     dword [nameLen]
    mov     ebx, [nameLen]
    mov     byte [playerName + ebx], 0
    jmp     .liDone

.liNotBack:
    ; A–Z: append if buffer not full (VK codes for letters == uppercase ASCII)
    cmp     eax, 0x41
    jl      .liDone
    cmp     eax, 0x5A
    jg      .liDone
    mov     ebx, [nameLen]
    cmp     ebx, NAME_MAX
    jge     .liDone
    mov     byte [playerName + ebx], al
    inc     dword [nameLen]

.liDone:
    pop     ebx
    ret

; ============================================================
;  Player2NameInput — handles key input for gameState 5 (P2 name)
;  Input: eax = virtual key code
;  Mirrors LoginInput but writes to player2Name/player2NameLen.
;  ENTER (with ≥1 char) → gameState = 0 (menu)
; ============================================================
Player2NameInput:
    push    ebx

    cmp     eax, VK_RETURN
    jne     .p2ni_notEnter
    cmp     dword [player2NameLen], 1
    jl      .p2ni_done
    mov     dword [gameState], 0
    jmp     .p2ni_done

.p2ni_notEnter:
    cmp     eax, VK_BACK
    jne     .p2ni_notBack
    cmp     dword [player2NameLen], 0
    jle     .p2ni_done
    dec     dword [player2NameLen]
    mov     ebx, [player2NameLen]
    mov     byte [player2Name + ebx], 0
    jmp     .p2ni_done

.p2ni_notBack:
    cmp     eax, 0x41
    jl      .p2ni_done
    cmp     eax, 0x5A
    jg      .p2ni_done
    mov     ebx, [player2NameLen]
    cmp     ebx, NAME_MAX
    jge     .p2ni_done
    mov     byte [player2Name + ebx], al
    inc     dword [player2NameLen]

.p2ni_done:
    pop     ebx
    ret

; ============================================================
;  NameMatch — compare two name buffers for byte-equality
;  Input:  esi = name1 ptr, ecx = len1
;          edi = name2 ptr, edx = len2
;  Output: eax = 1 if equal, 0 if not equal
;  Preserves: esi, edi, ecx, edx, ebx (all saved/restored)
; ============================================================
NameMatch:
    push    ebx
    xor     eax, eax            ; default: not equal
    cmp     ecx, edx
    jne     .nm_ret             ; different lengths → not equal
    test    ecx, ecx
    jz      .nm_match           ; both zero length → equal
    push    esi
    push    edi
    push    ecx
.nm_loop:
    movzx   ebx, byte [esi]
    cmp     bl, [edi]
    jne     .nm_ne
    inc     esi
    inc     edi
    dec     ecx
    jnz     .nm_loop
    pop     ecx
    pop     edi
    pop     esi
.nm_match:
    mov     eax, 1
    jmp     .nm_ret
.nm_ne:
    pop     ecx
    pop     edi
    pop     esi
.nm_ret:
    pop     ebx
    ret

; ============================================================
;  CopyNameToEntry — copy current playerName/score into entry
;  Input: edi = destination entry pointer (24-byte struct base)
;  Clobbers: eax, edi (modified during copy; caller need not use after)
; ============================================================
CopyNameToEntry:
    push    ebx
    push    esi
    push    ecx
    mov     ebx, edi            ; ebx = entry base (preserved throughout)
    ; Zero 16-byte name field
    xor     eax, eax
    mov     dword [ebx + 0],  eax
    mov     dword [ebx + 4],  eax
    mov     dword [ebx + 8],  eax
    mov     dword [ebx + 12], eax
    ; Copy playerName bytes into entry
    mov     esi, playerName
    mov     ecx, [nameLen]
    test    ecx, ecx
    jz      .cn_no_copy
.cn_loop:
    mov     al, [esi]
    mov     [edi], al
    inc     esi
    inc     edi
    dec     ecx
    jnz     .cn_loop
.cn_no_copy:
    ; Write nameLen and score at fixed offsets from entry base
    mov     eax, [nameLen]
    mov     [ebx + SB_OFS_LEN],   eax
    mov     eax, [pScore]
    mov     [ebx + SB_OFS_SCORE], eax
    pop     ecx
    pop     esi
    pop     ebx
    ret

; ============================================================
;  FindNameIdx — scan sorted scoreboard for current playerName
;  Sets lastSavedIdx to the found index, or -1 if not found
; ============================================================
FindNameIdx:
    push    ebx
    push    esi
    push    edi
    xor     ebx, ebx            ; i = 0
.fni_loop:
    cmp     ebx, [sbCount]
    jge     .fni_not_found
    mov     eax, ebx
    imul    eax, SB_ENTRY_SZ
    lea     edi, [scoreboard + eax]   ; edi = entry.name (OFS_NAME = 0)
    mov     esi, playerName
    mov     ecx, [nameLen]
    mov     edx, [edi + SB_OFS_LEN]
    call    NameMatch
    test    eax, eax
    jnz     .fni_found
    inc     ebx
    jmp     .fni_loop
.fni_found:
    mov     [lastSavedIdx], ebx
    jmp     .fni_ret
.fni_not_found:
    mov     dword [lastSavedIdx], -1
.fni_ret:
    pop     edi
    pop     esi
    pop     ebx
    ret

; ============================================================
;  SaveScore — record score under playerName (highest only).
;  Called just before gameState transitions to 2.
; ============================================================
SaveScore:
    push    ebp
    mov     ebp, esp
    push    ebx
    push    esi
    push    edi

    ; Skip if no name has been entered
    cmp     dword [nameLen], 0
    je      .sv_done

    ; --- Scan for existing entry with this name ---
    xor     ebx, ebx            ; i = 0
.sv_scan:
    cmp     ebx, [sbCount]
    jge     .sv_not_found

    mov     eax, ebx
    imul    eax, SB_ENTRY_SZ
    lea     edi, [scoreboard + eax]   ; edi = entry ptr

    push    ebx
    push    edi                 ; save entry ptr across NameMatch
    mov     esi, playerName
    mov     ecx, [nameLen]
    mov     edx, [edi + SB_OFS_LEN]
    call    NameMatch
    pop     edi                 ; restore entry ptr
    pop     ebx                 ; restore i

    test    eax, eax
    jz      .sv_next

    ; Found — update score only if new score is higher
    mov     eax, [pScore]
    cmp     eax, [edi + SB_OFS_SCORE]
    jle     .sv_found_keep
    mov     [edi + SB_OFS_SCORE], eax
.sv_found_keep:
    call    SortScoreboard
    call    FindNameIdx         ; updates lastSavedIdx to post-sort position
    jmp     .sv_done

.sv_next:
    inc     ebx
    jmp     .sv_scan

.sv_not_found:
    ; Board not full — append new entry
    mov     eax, [sbCount]
    cmp     eax, SB_MAX
    jge     .sv_full
    imul    eax, SB_ENTRY_SZ
    lea     edi, [scoreboard + eax]
    call    CopyNameToEntry
    inc     dword [sbCount]
    call    SortScoreboard
    call    FindNameIdx
    jmp     .sv_done

.sv_full:
    ; Board full — replace last-place entry if we scored higher
    mov     eax, (SB_MAX - 1) * SB_ENTRY_SZ
    lea     edi, [scoreboard + eax]
    mov     eax, [pScore]
    cmp     eax, [edi + SB_OFS_SCORE]
    jle     .sv_no_room
    call    CopyNameToEntry
    call    SortScoreboard
    call    FindNameIdx
    jmp     .sv_done

.sv_no_room:
    mov     dword [lastSavedIdx], -1

.sv_done:
    call    SaveScoreboardFile
    pop     edi
    pop     esi
    pop     ebx
    pop     ebp
    ret

; ============================================================
;  LoadScoreboard — read scoreboard.dat; populate scoreboard + sbCount
;  if the file exists and passes magic/bounds validation.
; ============================================================
LoadScoreboard:
    push    ebp
    mov     ebp, esp
    push    ebx
    push    esi
    push    edi
    ; [ebp-16] = file handle
    ; [ebp-20] = tmp read dword (magic / sbCount candidate)
    sub     esp, 8

    ; CreateFileA(sbPath, GENERIC_READ, 0, NULL, OPEN_EXISTING, FILE_ATTR_NORMAL, NULL)
    push    dword 0
    push    dword FILE_ATTR_NORMAL
    push    dword OPEN_EXISTING
    push    dword 0
    push    dword 0
    push    dword GENERIC_READ
    push    sbPath
    call    _CreateFileA@28
    cmp     eax, INVALID_HANDLE_VALUE
    je      .ls_done                    ; file missing -> keep empty defaults
    mov     [ebp-16], eax               ; save handle

    ; Read magic (4 bytes) into [ebp-20]
    push    dword 0
    push    ioBytes
    push    dword 4
    lea     eax, [ebp-20]
    push    eax
    push    dword [ebp-16]
    call    _ReadFile@20
    test    eax, eax
    jz      .ls_close
    mov     ebx, [ebp-20]
    cmp     ebx, SB_MAGIC
    jne     .ls_close                   ; bad magic -> ignore file

    ; Read sbCount candidate (4 bytes) into [ebp-20]
    push    dword 0
    push    ioBytes
    push    dword 4
    lea     eax, [ebp-20]
    push    eax
    push    dword [ebp-16]
    call    _ReadFile@20
    test    eax, eax
    jz      .ls_close
    mov     ebx, [ebp-20]               ; candidate sbCount
    cmp     ebx, 0
    jl      .ls_close
    cmp     ebx, SB_MAX
    jg      .ls_close

    ; Read scoreboard array (SB_MAX * SB_ENTRY_SZ bytes)
    push    dword 0
    push    ioBytes
    push    dword (SB_MAX * SB_ENTRY_SZ)
    push    scoreboard
    push    dword [ebp-16]
    call    _ReadFile@20
    test    eax, eax
    jz      .ls_close

    ; All checks passed — commit sbCount
    mov     [sbCount], ebx

.ls_close:
    push    dword [ebp-16]
    call    _CloseHandle@4
.ls_done:
    add     esp, 8
    pop     edi
    pop     esi
    pop     ebx
    pop     ebp
    ret

; ============================================================
;  SaveScoreboardFile — write magic + sbCount + scoreboard to sbPath
; ============================================================
SaveScoreboardFile:
    push    ebp
    mov     ebp, esp
    push    ebx
    push    esi
    push    edi
    ; [ebp-16] = file handle
    sub     esp, 4

    ; CreateFileA(sbPath, GENERIC_WRITE, 0, NULL, CREATE_ALWAYS, FILE_ATTR_NORMAL, NULL)
    push    dword 0
    push    dword FILE_ATTR_NORMAL
    push    dword CREATE_ALWAYS
    push    dword 0
    push    dword 0
    push    dword GENERIC_WRITE
    push    sbPath
    call    _CreateFileA@28
    cmp     eax, INVALID_HANDLE_VALUE
    je      .ssf_done                   ; can't write -> silently skip
    mov     [ebp-16], eax

    ; Write magic (4 bytes)
    push    dword 0
    push    ioBytes
    push    dword 4
    push    sbMagicMem
    push    dword [ebp-16]
    call    _WriteFile@20

    ; Write sbCount (4 bytes)
    push    dword 0
    push    ioBytes
    push    dword 4
    push    sbCount
    push    dword [ebp-16]
    call    _WriteFile@20

    ; Write scoreboard data (SB_MAX * SB_ENTRY_SZ bytes)
    push    dword 0
    push    ioBytes
    push    dword (SB_MAX * SB_ENTRY_SZ)
    push    scoreboard
    push    dword [ebp-16]
    call    _WriteFile@20

    push    dword [ebp-16]
    call    _CloseHandle@4
.ssf_done:
    add     esp, 4
    pop     edi
    pop     esi
    pop     ebx
    pop     ebp
    ret

; ============================================================
;  SortScoreboard — bubble sort entries descending by score
; ============================================================
SortScoreboard:
    push    ebp
    mov     ebp, esp
    push    ebx
    push    esi
    push    edi
    sub     esp, 8
    ; [ebp-4] = n (sbCount), [ebp-8] = outer i

    mov     eax, [sbCount]
    cmp     eax, 2
    jl      .srt_done
    mov     [ebp-4], eax
    mov     dword [ebp-8], 0    ; outer i = 0

.srt_outer:
    mov     eax, [ebp-4]
    dec     eax                 ; n-1
    cmp     dword [ebp-8], eax
    jge     .srt_done
    xor     ecx, ecx            ; inner j = 0
.srt_inner:
    mov     eax, [ebp-4]
    dec     eax
    sub     eax, dword [ebp-8]  ; inner limit = n-1-i
    cmp     ecx, eax
    jge     .srt_inner_done
    push    ecx                 ; save j
    mov     eax, ecx
    imul    eax, SB_ENTRY_SZ
    lea     esi, [scoreboard + eax]        ; entry[j]
    lea     edi, [esi + SB_ENTRY_SZ]       ; entry[j+1]
    mov     eax, [esi + SB_OFS_SCORE]
    cmp     eax, [edi + SB_OFS_SCORE]
    jge     .srt_no_swap        ; entry[j] >= entry[j+1]: in order
    ; swap all 6 dwords (24 bytes)
    mov     ebx, 6
.srt_swap:
    mov     eax, [esi]
    mov     ecx, [edi]
    mov     [esi], ecx
    mov     [edi], eax
    add     esi, 4
    add     edi, 4
    dec     ebx
    jnz     .srt_swap
.srt_no_swap:
    pop     ecx                 ; restore j (used as temp in swap loop)
    inc     ecx
    jmp     .srt_inner
.srt_inner_done:
    inc     dword [ebp-8]
    jmp     .srt_outer

.srt_done:
    add     esp, 8
    pop     edi
    pop     esi
    pop     ebx
    pop     ebp
    ret

; ============================================================
;  RenderScoreboard — draw leaderboard rows
;  Input: ebx = base y
;         ecx = max rows to draw (clamped to sbCount)
;         edx = compact flag (0 = full 800px layout, 1 = right-column compact)
;         edi = highlight index (-1 = no highlight)
;  esi and edi are preserved by Win32 across all internal calls.
;  Only push/pop esi around draws where esi must temporarily be digitBuf.
; ============================================================
RenderScoreboard:
    push    ebp
    mov     ebp, esp
    push    ebx
    push    esi
    push    edi
    sub     esp, 24
    ; [ebp-4]  = base_y
    ; [ebp-8]  = max_rows (clamped to sbCount)
    ; [ebp-12] = compact flag
    ; [ebp-16] = highlight_idx
    ; [ebp-20] = cur_i (current row)
    ; [ebp-24] = (scratch/alignment pad)

    mov     [ebp-4], ebx
    ; Clamp max_rows to sbActiveCount
    mov     eax, [sbActiveCount]
    cmp     ecx, eax
    jle     .rsb_clamp_ok
    mov     ecx, eax
.rsb_clamp_ok:
    mov     [ebp-8], ecx
    mov     [ebp-12], edx
    mov     [ebp-16], edi
    mov     dword [ebp-20], 0

    ; --- empty board check ---
    cmp     dword [ebp-8], 0
    jg      .rsb_loop_start
    push    C_GRAY
    push    dword [hdcMem]
    call    _SetTextColor@8
    cmp     dword [ebp-12], 0
    je      .rsb_ns_full_x
    cmp     dword [ebp-12], 2
    je      .rsb_ns_left_x
    mov     eax, 525            ; compact RIGHT
    jmp     .rsb_ns_draw
.rsb_ns_left_x:
    mov     eax, 125            ; compact LEFT
    jmp     .rsb_ns_draw
.rsb_ns_full_x:
    push    TA_CENTER
    push    dword [hdcMem]
    call    _SetTextAlign@8
    mov     eax, 400
    mov     ebx, [ebp-4]
    mov     esi, sNoScores
    mov     ecx, [sNoScoresLen]
    call    TextAt
    push    TA_LEFT
    push    dword [hdcMem]
    call    _SetTextAlign@8
    jmp     .rsb_end
.rsb_ns_draw:
    mov     ebx, [ebp-4]
    mov     esi, sNoScores
    mov     ecx, [sNoScoresLen]
    call    TextAt
    jmp     .rsb_end

    ; --- main row loop ---
.rsb_loop_start:
    mov     eax, [ebp-20]
    cmp     eax, [ebp-8]
    jge     .rsb_end

    ; compute edi = row_y  (Win32 preserves edi across all calls below)
    mov     eax, [ebp-20]
    cmp     dword [ebp-12], 0
    je      .rsb_fy
    imul    eax, 20             ; compact: 20px stride
    jmp     .rsb_yd
.rsb_fy:
    imul    eax, 22             ; full: 22px stride
.rsb_yd:
    add     eax, [ebp-4]
    mov     edi, eax            ; edi = row_y

    ; compute esi = entry ptr  (Win32 preserves esi across all calls)
    mov     eax, [ebp-20]
    imul    eax, SB_ENTRY_SZ
    mov     esi, [sbActiveBase]
    add     esi, eax

    ; --- pick text color ---
    ; Check P1 highlight first
    mov     eax, [ebp-16]       ; highlight_idx (P1)
    cmp     eax, -1
    je      .rsb_ck_p2hi
    cmp     dword [ebp-20], eax
    jne     .rsb_ck_p2hi
    push    C_CORRECT           ; P1 highlighted row (cyan)
    jmp     .rsb_do_color
.rsb_ck_p2hi:
    ; Check P2 highlight (only relevant in 2P mode)
    cmp     dword [playerCount], 2
    jne     .rsb_ck_rank
    mov     eax, [lastSavedIdxP2]
    cmp     eax, -1
    je      .rsb_ck_rank
    cmp     dword [ebp-20], eax
    jne     .rsb_ck_rank
    push    C_PLAYER2           ; P2 highlighted row (magenta)
    jmp     .rsb_do_color
.rsb_ck_rank:
    cmp     dword [ebp-20], 3
    jl      .rsb_color_white
    push    C_GRAY              ; rank 4+ : gray
    jmp     .rsb_do_color
.rsb_color_white:
    push    C_WHITE             ; rank 1-3: white
.rsb_do_color:
    push    dword [hdcMem]
    call    _SetTextColor@8
    ; esi = entry_ptr, edi = row_y — preserved by Win32

    ; --- draw rank number ---
    mov     eax, [ebp-20]
    inc     eax                 ; rank = i+1
    call    IntToStr            ; → digitBuf; IntToStr preserves esi/edi
    ; measure null-terminated digitBuf
    xor     ecx, ecx
.rsb_rlen:
    cmp     byte [digitBuf + ecx], 0
    je      .rsb_rlen_done
    inc     ecx
    jmp     .rsb_rlen
.rsb_rlen_done:
    cmp     dword [ebp-12], 0
    je      .rsb_rank_fx
    cmp     dword [ebp-12], 2
    je      .rsb_rank_left
    mov     eax, 525            ; compact RIGHT rank
    jmp     .rsb_rank_draw
.rsb_rank_left:
    mov     eax, 125            ; compact LEFT rank
    jmp     .rsb_rank_draw
.rsb_rank_fx:
    mov     eax, 280            ; full rank
.rsb_rank_draw:
    mov     ebx, edi            ; row_y
    push    esi                 ; save entry_ptr (esi must become digitBuf)
    mov     esi, digitBuf
    call    TextAt              ; Win32 preserves edi
    pop     esi                 ; restore entry_ptr

    ; --- draw name ---
    cmp     dword [ebp-12], 0
    je      .rsb_name_fx
    cmp     dword [ebp-12], 2
    je      .rsb_name_left
    mov     eax, 555            ; compact RIGHT name
    jmp     .rsb_name_draw
.rsb_name_left:
    mov     eax, 155            ; compact LEFT name
    jmp     .rsb_name_draw
.rsb_name_fx:
    mov     eax, 320            ; full name
.rsb_name_draw:
    mov     ebx, edi            ; row_y
    mov     ecx, [esi + SB_OFS_LEN]    ; nameLen from entry
    ; esi = entry base = name buffer (OFS_NAME = 0)
    call    TextAt              ; Win32 preserves esi, edi

    ; --- draw score ---
    mov     eax, [esi + SB_OFS_SCORE]
    call    IntToStr            ; → digitBuf; preserves esi/edi
    xor     ecx, ecx
.rsb_slen:
    cmp     byte [digitBuf + ecx], 0
    je      .rsb_slen_done
    inc     ecx
    jmp     .rsb_slen
.rsb_slen_done:
    cmp     dword [ebp-12], 0
    je      .rsb_score_fx
    cmp     dword [ebp-12], 2
    je      .rsb_score_left
    mov     eax, 670            ; compact RIGHT score
    jmp     .rsb_score_draw
.rsb_score_left:
    mov     eax, 275            ; compact LEFT score
    jmp     .rsb_score_draw
.rsb_score_fx:
    mov     eax, 470            ; full score
.rsb_score_draw:
    mov     ebx, edi            ; row_y
    push    esi                 ; save entry_ptr
    mov     esi, digitBuf
    call    TextAt
    pop     esi                 ; restore entry_ptr

    ; --- advance to next row ---
    inc     dword [ebp-20]
    jmp     .rsb_loop_start

.rsb_end:
    add     esp, 24
    pop     edi
    pop     esi
    pop     ebx
    pop     ebp
    ret

; ============================================================
;  CopyNameToEntryP2 — copy player2Name/player2NameLen + pScore2
;  into a unified scoreboard entry.
;  Input: edi = destination entry pointer (24-byte struct base)
; ============================================================
CopyNameToEntryP2:
    push    ebx
    push    esi
    push    ecx
    mov     ebx, edi
    xor     eax, eax
    mov     dword [ebx + 0],  eax
    mov     dword [ebx + 4],  eax
    mov     dword [ebx + 8],  eax
    mov     dword [ebx + 12], eax
    mov     esi, player2Name
    mov     ecx, [player2NameLen]
    test    ecx, ecx
    jz      .cnp2_no_copy
.cnp2_loop:
    mov     al, [esi]
    mov     [edi], al
    inc     esi
    inc     edi
    dec     ecx
    jnz     .cnp2_loop
.cnp2_no_copy:
    mov     eax, [player2NameLen]
    mov     [ebx + SB_OFS_LEN],   eax
    mov     eax, [pScore2]
    mov     [ebx + SB_OFS_SCORE], eax
    pop     ecx
    pop     esi
    pop     ebx
    ret

; ============================================================
;  FindNameIdxP2 — scan unified scoreboard for player2Name.
;  Sets lastSavedIdxP2 to found index, or -1 if not found.
; ============================================================
FindNameIdxP2:
    push    ebx
    push    esi
    push    edi
    xor     ebx, ebx
.fnip2_loop:
    cmp     ebx, [sbCount]
    jge     .fnip2_not_found
    mov     eax, ebx
    imul    eax, SB_ENTRY_SZ
    lea     edi, [scoreboard + eax]
    mov     esi, player2Name
    mov     ecx, [player2NameLen]
    mov     edx, [edi + SB_OFS_LEN]
    call    NameMatch
    test    eax, eax
    jnz     .fnip2_found
    inc     ebx
    jmp     .fnip2_loop
.fnip2_found:
    mov     [lastSavedIdxP2], ebx
    jmp     .fnip2_ret
.fnip2_not_found:
    mov     dword [lastSavedIdxP2], -1
.fnip2_ret:
    pop     edi
    pop     esi
    pop     ebx
    ret

; ============================================================
;  SaveScoreP2 — record P2 score under player2Name in the unified
;  scoreboard (highest only). Mirrors SaveScore for player 2.
; ============================================================
SaveScoreP2:
    push    ebp
    mov     ebp, esp
    push    ebx
    push    esi
    push    edi

    cmp     dword [player2NameLen], 0
    je      .svp2_done

    xor     ebx, ebx
.svp2_scan:
    cmp     ebx, [sbCount]
    jge     .svp2_not_found

    mov     eax, ebx
    imul    eax, SB_ENTRY_SZ
    lea     edi, [scoreboard + eax]

    push    ebx
    push    edi
    mov     esi, player2Name
    mov     ecx, [player2NameLen]
    mov     edx, [edi + SB_OFS_LEN]
    call    NameMatch
    pop     edi
    pop     ebx

    test    eax, eax
    jz      .svp2_next

    ; Found — update score only if new score is higher
    mov     eax, [pScore2]
    cmp     eax, [edi + SB_OFS_SCORE]
    jle     .svp2_found_keep
    mov     [edi + SB_OFS_SCORE], eax
.svp2_found_keep:
    call    SortScoreboard
    call    FindNameIdxP2
    jmp     .svp2_done

.svp2_next:
    inc     ebx
    jmp     .svp2_scan

.svp2_not_found:
    mov     eax, [sbCount]
    cmp     eax, SB_MAX
    jge     .svp2_full
    imul    eax, SB_ENTRY_SZ
    lea     edi, [scoreboard + eax]
    call    CopyNameToEntryP2
    inc     dword [sbCount]
    call    SortScoreboard
    call    FindNameIdxP2
    jmp     .svp2_done

.svp2_full:
    ; Board full — replace last-place if P2 scored higher
    mov     eax, (SB_MAX - 1) * SB_ENTRY_SZ
    lea     edi, [scoreboard + eax]
    mov     eax, [pScore2]
    cmp     eax, [edi + SB_OFS_SCORE]
    jle     .svp2_no_room
    call    CopyNameToEntryP2
    call    SortScoreboard
    call    FindNameIdxP2
    jmp     .svp2_done

.svp2_no_room:
    mov     dword [lastSavedIdxP2], -1

.svp2_done:
    call    SaveScoreboardFile
    pop     edi
    pop     esi
    pop     ebx
    pop     ebp
    ret