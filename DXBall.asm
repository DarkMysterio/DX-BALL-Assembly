.386
.model flat, stdcall
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;includem biblioteci, si declaram ce functii vrem sa importam
includelib msvcrt.lib
extern exit: proc
extern malloc: proc
extern memset: proc
extern printf: proc

includelib canvas.lib
extern BeginDrawing: proc
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;declaram simbolul start ca public - de acolo incepe executia
public start
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;sectiunile programului, date, respectiv cod
.data
;aici declaram date
window_title DB "Exemplu proiect desenare",0
area_width EQU 640
area_height EQU 480
area DD 0

counter DD 0 ; numara evenimentele de tip timer

arg1 EQU 8
arg2 EQU 12
arg3 EQU 16
arg4 EQU 20

button_x EQU 220
button_y EQU 280

inceput DD 0

cont dd 0

schimb dd 0

x_paleta dd 260
y_paleta dd 440
lungime_paleta dd 120
viteza_paleta  dd 10

x_margine_dreapta EQU 10
x_margine_stanga EQU 630
y_margine_sus EQU 10
y_margine_jos EQU 440

x_bila dd 320
y_bila dd 300

x_directie_bila dd 0	
y_directie_bila dd 0

final_joc dd 0

numar_caramizi dd 30

lungime_caramida dd 40

clr dd 0FF0000H

pozitii_caramizi_x dd 200,250,300,350,400,450,500,50,100,150,200,250,300,350,400,450,50,100,150,500,200,250,300,350,400,450,50,100,150,500
pozitii_caramizi_y dd 200,200,200,200,200,200,200,200,200,200,100,100,100,100,100,100,100,100,100,100,150,150,150,150,150,150,150,150,150,150

caramizi_active dd 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1

debug_coliziune  db "Verificare coliziune dintre bila de pe pozitia (%d, %d) si caramida de pe pozitia %d cu colturile (%d, %d) si (%d, %d) -> %d", 13, 10, 0

symbol_width EQU 10
symbol_height EQU 20
include digits.inc
include letters.inc	

.code
; procedura make_text afiseaza o litera sau o cifra la coordonatele date
; arg1 - simbolul de afisat (litera sau cifra)
; arg2 - pointer la vectorul de pixeli
; arg3 - pos_x
; arg4 - pos_y
make_text proc
	push ebp
	mov ebp, esp
	pusha
	
	mov eax, [ebp+arg1] ; citim simbolul de afisat
	cmp eax, 'A'
	jl make_digit
	cmp eax, 'Z'
	jg make_digit
	sub eax, 'A'
	lea esi, letters
	jmp draw_text

make_digit:
	cmp eax, '0'
	jl make_space
	cmp eax, '9'
	jg make_space
	sub eax, '0'
	lea esi, digits
	jmp draw_text
make_space:	
	mov eax, 26 ; de la 0 pana la 25 sunt litere, 26 e space
	lea esi, letters
	
draw_text:
	mov ebx, symbol_width
	mul ebx
	mov ebx, symbol_height
	mul ebx
	add esi, eax
	mov ecx, symbol_height
bucla_simbol_linii:
	mov edi, [ebp+arg2] ; pointer la matricea de pixeli
	mov eax, [ebp+arg4] ; pointer la coord y
	add eax, symbol_height
	sub eax, ecx
	mov ebx, area_width
	mul ebx
	add eax, [ebp+arg3] ; pointer la coord x
	shl eax, 2 ; inmultim cu 4, avem un DWORD per pixel
	add edi, eax
	push ecx
	mov ecx, symbol_width
bucla_simbol_coloane:
	cmp byte ptr [esi], 0
	je simbol_pixel_alb
	mov dword ptr [edi], 0
	jmp simbol_pixel_next
simbol_pixel_alb:
	mov dword ptr [edi], 0FFFFFFh
simbol_pixel_next:
	inc esi
	add edi, 4
	loop bucla_simbol_coloane
	pop ecx
	loop bucla_simbol_linii
	popa
	mov esp, ebp
	pop ebp
	ret
make_text endp

; un macro ca sa apelam mai usor desenarea simbolului
make_text_macro macro symbol, drawArea, x, y
	push y
	push x
	push drawArea
	push symbol
	call make_text
	add esp, 16
endm

Linie_Orizontala macro x, y, len, color
local linie 
	pusha
	mov eax,y
	mov ebx,area_width
	mul ebx
	add eax,x
	shl eax,2
	add eax,area
	mov ecx,len
linie:
	mov dword  ptr[eax], color
	mov dword  ptr[eax-area_width*4], color
	mov dword  ptr[eax+area_width*4], color
	mov dword  ptr[eax-2*area_width*4], color
	mov dword  ptr[eax+2*area_width*4], color
	add eax,4
	loop linie
	popa
endm

Linie_Verticala macro x, y, len, color
local linie 
	pusha
	mov eax,y
	mov ebx,area_width
	mul ebx
	add eax,x
	shl eax,2
	add eax,area
	mov ecx,len
linie:
	mov dword  ptr[eax], color
	mov dword  ptr[eax+4], color
	mov dword  ptr[eax-4], color
	mov dword  ptr[eax+8], color
	mov dword  ptr[eax-8], color
	add eax,area_width*4
	loop linie
	popa
endm

Linie_Orizontala_Bila macro x, y, len, color
local linie 
	pusha
	mov eax,y
	mov ebx,area_width
	mul ebx
	add eax,x
	shl eax,2
	add eax,area
	mov ecx,len
linie:
	mov dword  ptr[eax], color
	add eax,4
	loop linie
	popa
endm

minge macro x, y, color
	pusha
	mov eax,y
	mov ebx,area_width
	mul ebx
	add eax,x
	shl eax,2
	add eax,area
	
	mov ecx,y 
	mov edi,x
	inc edi
	Linie_Orizontala_Bila edi,ecx,8,color
	dec ecx
	
	Linie_Orizontala_Bila edi,ecx,8,color
	dec ecx
	inc edi
	Linie_Orizontala_Bila edi,ecx,6,color
	dec ecx
	inc edi
	Linie_Orizontala_Bila edi,ecx,4,color
	
	mov ecx,y 
	mov edi,x
	inc edi
	inc ecx
	Linie_Orizontala_Bila edi,ecx,8,color
	inc edi
	inc ecx
	Linie_Orizontala_Bila edi,ecx,6,color
	inc edi
	inc ecx
	Linie_Orizontala_Bila edi,ecx,4,color


	popa
endm


Caramida macro x, y, len, color
local linie 
	pusha
	mov eax,y
	mov ebx,area_width
	mul ebx
	add eax,x
	shl eax,2
	add eax,area
	mov ecx,len
linie:
	mov dword  ptr[eax], color
	mov dword  ptr[eax+area_width*4], color
	mov dword  ptr[eax+2*area_width*4], color
	mov dword  ptr[eax+3*area_width*4], color
	mov dword  ptr[eax+4*area_width*4], color
	mov dword  ptr[eax+5*area_width*4], color
	mov dword  ptr[eax+6*area_width*4], color
	mov dword  ptr[eax+7*area_width*4], color
	mov dword  ptr[eax+8*area_width*4], color
	mov dword  ptr[eax+9*area_width*4], color
	mov dword  ptr[eax+10*area_width*4], color
	mov dword  ptr[eax+11*area_width*4], color

	add eax,4
	loop linie
	popa
endm


; functia de desenare - se apeleaza la fiecare click
; sau la fiecare interval de 200ms in care nu s-a dat click
; arg1 - evt (0 - initializare, 1 - click, 2 - s-a scurs intervalul fara click, 3 - s-a apasat o tasta)
; arg2 - x (in cazul apasarii unei taste, x contine codul ascii al tastei care a fost apasata)
; arg3 - y
draw proc
	cmp final_joc,1
	jge sfarsit_joc
	push ebp
	mov ebp, esp
	pusha
	mov eax, [ebp+arg1]
	; cmp eax, 1
	; jz evt_click
	;cmp eax, 2
	;jz evt_timer ; nu s-a efectuat click pe nimic
	;mai jos e codul care intializeaza fereastra cu pixeli albi
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	push 255
	push area
	call memset
	add esp, 12 

	
	

evt_click:

	
	mov eax,[ebp+arg1]
	
	cmp eax,2
	jne peste
	cmp eax,3
	je peste

	
	cmp caramizi_active[5],0
	jne caramida_speciala ; caramida speciala care mareste viteza
	mov viteza_paleta,20
	
	caramida_speciala :
	cmp caramizi_active[5],0
	jne verificare_final_joc ; caramida speciala care mareste viteza
	mov lungime_caramida,35
	
	verificare_final_joc : 
	mov esi,-4
	mov ecx,numar_caramizi
	mov eax,0
	bcl :
	add esi,4
	cmp caramizi_active[esi],1
	jne repet
	mov eax,1
	repet:
	loop bcl
	cmp eax,0
	je sfarsit_joc
	
	
	
	cmp schimb,1
	je ai
	mov schimb,1
	jmp aia
	ai:
	mov schimb,0
	
	aia :
	mov esi,-4
	mov edi,numar_caramizi
	
	
	
	verificare_coliziune_caramizi :
	add esi,4
	dec edi
	
	cmp edi,-1
	je abc
	

	
	mov eax,pozitii_caramizi_x[esi]
	mov ebx,pozitii_caramizi_y[esi]
	mov ecx,x_bila
	mov edx,y_bila
	
	cmp caramizi_active[esi],0
	je next2
	; Coliziune x_bila,y_bila,pozitii_caramizi_x[esi],pozitii_caramizi_y[esi],lungime_caramida,12
	; cmp edx,1
	; jne next2
	 
	
	
	cmp ecx,pozitii_caramizi_x[esi]
	jl verificare_coliziune_caramizi
	sub ecx,40
	cmp ecx,pozitii_caramizi_x[esi]
	jg verificare_coliziune_caramizi
	
	cmp edx,pozitii_caramizi_y[esi]
	jl verificare_coliziune_caramizi
	sub edx,12
	cmp edx,pozitii_caramizi_y[esi]
	jg verificare_coliziune_caramizi
	mov caramizi_active[esi],0
	
	

	
	
	; cmp x_directie_bila,10
	; je opus
	; mov x_directie_bila,10
	; jmp next
	; opus :
	; mov x_directie_bila,-10
	
	 next :
	add counter,10   ;; marire scor la fiecare caramida atinsa
	cmp y_directie_bila,10
	je opus2
	mov y_directie_bila,10
	jmp next2
	opus2 :
	mov y_directie_bila,-10
	
	next2 :
	
	jmp verificare_coliziune_caramizi
	
	abc :

	mov eax,x_bila
	add eax,x_directie_bila
	cmp eax,12
	jle schimbare_directie_pozitiva_x
	cmp eax,623
	jge schimbare_directie_negativa_x
	
	mov [x_bila],eax
	mov eax,y_bila
	add eax,y_directie_bila
	
	cmp eax,12
	jle schimbare_directie_pozitiva_y
	cmp eax,437
	jge schimbare_directie_negativa_y
	mov [y_bila],eax
	jmp peste
	
	schimbare_directie_pozitiva_x:
	;add x_directie_bila,16
	mov x_directie_bila,10
	jmp peste
	
	schimbare_directie_negativa_x:
	;sub x_directie_bila,16
	mov x_directie_bila,-10
	jmp peste
	
	
	
	schimbare_directie_pozitiva_y:
	;add y_directie_bila,16
	mov y_directie_bila,10
	jmp peste
	
	
	schimbare_directie_negativa_y:
	mov eax,x_paleta
	cmp eax,x_bila
	jge sfarsit_joc
	
	add eax,lungime_paleta
	cmp eax,x_bila
	jle sfarsit_joc
	
	mov eax,x_bila
	sub eax,40
	cmp eax,x_paleta
	jge dreapta

	mov y_directie_bila,-10
	mov x_directie_bila,-10
	jmp peste
	
	dreapta :
	
	mov eax,x_paleta
	add eax,80
	mov ebx,x_bila
	
	cmp eax,ebx
	jge mijloc
	
	mov y_directie_bila,-10
	mov x_directie_bila,10
	jmp peste
	
	mijloc :
	mov y_directie_bila,-10
	mov x_directie_bila,0
	peste :
	
	
	mov eax, [ebp+arg2]
	cmp eax,"'"
	je laDreapta
	cmp eax,"%"
	je laStanga	
	
    cmp eax, button_x
	jl peLanga
	cmp eax,button_x+180
	jg peLanga
	mov eax,[ebp+arg3]
	cmp	eax, button_y
	jl peLanga
	cmp eax,button_y+80
	jg peLanga
	
	
	push area_height*area_width*4
	push 255
	push area
	call memset
	add esp, 12
	mov inceput,1
	mov x_directie_bila,10
	mov y_directie_bila,10
	jmp final_draw
	

	laDreapta :
	mov edx,viteza_paleta
	mov eax,x_paleta
	cmp eax,508
	jge peLanga
	
	add x_paleta,edx
	mov inceput,1
	jmp peLanga
	
	laStanga :
	mov edx,viteza_paleta
	mov eax,x_paleta
	cmp eax,14
	jle peLanga
	sub x_paleta,edx
	mov inceput,1
	peLanga:
	
	
; evt_score:
	; mov esi,-4
	
	; mov edi,numar_caramizi
	
	; verific_score :
	; add esi,4
	; cmp caramizi_active[esi],0
	; jne pess
	; inc counter
	; pess:
	; dec edi
	; cmp edi,0
	
	; jg verific_score
	
	
cmp inceput,1	
je final_draw

afisare_litere:

	
	
	;scriem un mesaj
	make_text_macro 'P', area, 270, 100
	make_text_macro 'R', area, 280, 100
	make_text_macro 'O', area, 290, 100
	make_text_macro 'I', area, 300, 100
	make_text_macro 'E', area, 310, 100
	make_text_macro 'C', area, 320, 100
	
	make_text_macro 'T', area, 330, 100
	
	make_text_macro 'L', area, 300, 120
	make_text_macro 'A', area, 310, 120
	
	make_text_macro 'A', area, 260, 140
	make_text_macro 'S', area, 270, 140
	make_text_macro 'A', area, 280, 140
	make_text_macro 'M', area, 290, 140
	make_text_macro 'B', area, 300, 140
	make_text_macro 'L', area, 310, 140
	make_text_macro 'A', area, 320, 140
	make_text_macro 'R', area, 330, 140
	make_text_macro 'E', area, 340, 140
	
	Linie_Orizontala [button_x],[button_y],180,0 
	Linie_Orizontala [button_x],[button_y+80],180,0
	Linie_Verticala  [button_x],[button_y],80,0
	Linie_Verticala  [button_x+180],[button_y],80,0
	
	make_text_macro 'S', area, button_x+180/2-20, 310
	make_text_macro 'T', area, button_x+180/2-10, 310
	make_text_macro 'A', area, button_x+180/2, 	  310
	make_text_macro 'R', area, button_x+180/2+10, 310
	make_text_macro 'T', area, button_x+180/2+20, 310
	
	

jmp final_draw

sfarsit_joc :

	add final_joc,1


final_draw:
	cmp inceput,0	
	je afara
	
	cmp final_joc,1
	jl afisare_paleta_pereti
	
	make_text_macro 'F', area, button_x+180/2-20, 310
	make_text_macro 'I', area, button_x+180/2-10, 310
	make_text_macro 'N', area, button_x+180/2, 	  310
	make_text_macro 'A', area, button_x+180/2+10, 310
	make_text_macro 'L', area, button_x+180/2+20, 310
	
	jmp afara
	
	afisare_paleta_pereti:
	

		Linie_Orizontala x_paleta,y_paleta,lungime_paleta,0A7AFB8H
		Linie_Orizontala x_paleta,y_paleta,lungime_paleta,0A7AFB8H
		Linie_Orizontala x_paleta,y_paleta,lungime_paleta,0A7AFB8H
		Linie_Verticala 6,10,470,0A7AFB8H
		Linie_Verticala 633,10,470,0A7AFB8H
		Linie_Verticala 2,10,470,858A94H
		Linie_Verticala 629,10,470,858A94H
		Linie_Verticala 10,10,470,858A94H
		Linie_Verticala 637,10,470,858A94H
		
		Linie_Orizontala 0,6,640,0A7AFB8H
		
		Linie_Orizontala 0,2,640,858A94H
		Linie_Orizontala 0,10,640,858A94H
		
		minge x_bila,y_bila,858A94H
		
		make_text_macro 'S', area, 30, 30
		make_text_macro 'C', area, 40, 30
		make_text_macro 'O', area, 50,30
		make_text_macro 'R', area, 60, 30
		
			; afisam valoarea counter-ului curent (sute, zeci si unitati)
		mov ebx, 10
		mov eax, counter
		; cifra unitatilor
		mov edx, 0
		div ebx
		add edx, '0'
		make_text_macro edx, area, 100, 30
		; cifra zecilor
		mov edx, 0
		div ebx
		add edx, '0'
		make_text_macro edx, area, 90, 30
		; cifra sutelor
		mov edx, 0
		div ebx
		add edx, '0'
		make_text_macro edx, area, 80, 30
	

	
	mov esi,0
	
	mov edi,numar_caramizi
	
	afisare_caramizi :
	cmp caramizi_active[esi],0
	je p
	cmp schimb,0
	je alta 
	Caramida pozitii_caramizi_x[esi], pozitii_caramizi_y[esi], lungime_caramida, 0FF0000H
	jmp p
	alta:
	Caramida pozitii_caramizi_x[esi], pozitii_caramizi_y[esi], lungime_caramida, 0FF00FFH
	p :
	add esi,4
	dec edi
	cmp edi,0
	jg afisare_caramizi
	
	
	afara:
	popa
	mov esp, ebp
	pop ebp
	ret

draw endp


start:
	;alocam memorie pentru zona de desenat
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	call malloc
	add esp, 4
	mov area, eax
	;apelam functia de desenare a ferestrei
	; typedef void (*DrawFunc)(int evt, int x, int y);
	; void __cdecl BeginDrawing(const char *title, int width, int height, unsigned int *area, DrawFunc draw);
	push offset draw
	push area
	push area_height
	push area_width
	push offset window_title
	call BeginDrawing
	add esp, 20
	
	;terminarea programului
	push 0
	call exit
end start
	