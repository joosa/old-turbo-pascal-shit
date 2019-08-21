unit grap;

interface

const
	viewx=158;
	viewy=158;
	cx1=0;
	cx2=319;
	cy1=0;
	cy2=199;

type
	screen=^tscreen;
	tscreen=array[0..190,0..319]of byte;
	color=array[0..2]of byte;
	palette=array[0..255]of color;

var
	fontheight:byte;

function exist(name:string):boolean;
procedure setpal(c,r,g,b:byte);
procedure setin(p:palette;i:integer);
procedure picor1(x,y:integer;var dest,source);
procedure picor2(x,y:integer;var dest,source);
{procedure picorb1(x,y:integer;var dest,source);
procedure picorb2(x,y:integer;var dest,source);}
procedure hline1(x,len,y:integer;c:byte;var dest);
procedure picor(x,y:integer;var dest,source);
procedure picor8c(x,y:integer;var dest,source;col:byte);
procedure setmode(mode:word);
procedure flip(var source,dest);
procedure sync;
procedure cls(var dest);
procedure writef(x,y:integer;text:string;col:byte;var dest,source);
function loadpal(var p:palette;name:string):boolean;
function loaddata(name:string;var p;pos,size:word):word;
procedure getpal(var c,r,g,b:byte);
procedure restpal(p:palette);
procedure cyclepal(b,e:byte);

implementation

procedure setpal(c,r,g,b:byte);assembler;
asm
	mov dx,3c8h
	mov al,[c]
	out dx,al
	inc dx
	mov al,[r]
	out dx,al
	mov al,[g]
	out dx,al
	mov al,[b]
	out dx,al
end;

procedure setin(p:palette;i:integer);
var c:byte;
begin
	for c:=0 to 255 do begin
		setpal(c,p[c,0]*i shr 5,p[c,1]*i shr 5,p[c,2]*i shr 5);
	end;
end;

procedure picor1(x,y:integer;var dest,source);assembler;
const
	cx1=0;
	cx2=viewx-1;
	cy1=0;
	cy2=viewy-1;
asm
	mov dx,[x]
	mov cx,[y]
	add dx,16
	add cx,16

	cmp dx,cx1+1
	jb @exit
	cmp dx,cx2+16
	ja @exit

	cmp cx,cy1+1
	jb @exit
	cmp cx,cy2+16
	ja @exit

	cmp dx,cx1+16
	jb @clip
	cmp dx,cx2
	ja @clip

	cmp cx,cy1+16
	jb @clip
	cmp cx,cy2
	ja @clip


	push ds

	les di,[dest]
	cld
	mov ax,[y]
	shl ax,6
	add di,ax
	shl ax,2
	add di,ax
	add di,[x]

	lds si,[source]

	xor cx,cx
	add cl,16
 @ll1:
	add ch,16
 @ll2:
	lodsb
	or al,0
	jz @hyp
	mov es:[di],al
 @hyp:
	inc di
	dec ch
	jnz @ll2
	add di,304
	dec cl
	jnz @ll1
	pop ds

	jmp @exit
 @clip:

	push ds

	les di,[dest]
	{cld}
	mov ax,[y]
	mov cl,al
	shl ax,6
	add di,ax
	shl ax,2
	add di,ax
	mov dx,[x]
	add di,dx

	lds si,[source]

	xor bx,bx
	add bh,16
 @l:
	add bl,16
 @l2:
	lodsb
	cmp dl,cx1
	jb @s
	cmp dx,cx2
	ja @s
	cmp cl,cy1
	jb @s
	cmp cl,cy2
	ja @s
 @sc:
	or al,0
	jz @s
	mov es:[di],al
 @s:
	inc di
	inc dx
	dec bl
	jnz @l2
	add di,304
	sub dx,16
	inc cl
	dec bh
	jnz @l

	pop ds

 @exit:
end;


procedure picor2(x,y:integer;var dest,source);assembler;
const
	cx1=160;
	cx2=160+viewx-1;
	cy1=0;
	cy2=viewy-1;
asm
	mov dx,[x]
	mov cx,[y]
	add dx,16
	add cx,16

	cmp dx,cx1+1
	jb @exit
	cmp dx,cx2+16
	ja @exit

	cmp cx,cy1+1
	jb @exit
	cmp cx,cy2+16
	ja @exit

	cmp dx,cx1+16
	jb @clip
	cmp dx,cx2
	ja @clip

	cmp cx,cy1+16
	jb @clip
	cmp cx,cy2
	ja @clip


	push ds

	les di,[dest]
	cld
	mov ax,[y]
	shl ax,6
	add di,ax
	shl ax,2
	add di,ax
	add di,[x]

	lds si,[source]

	xor cx,cx
	add cl,16
 @ll1:
	add ch,16
 @ll2:
	lodsb
	or al,0
	jz @hyp
	mov es:[di],al
 @hyp:
	inc di
	dec ch
	jnz @ll2
	add di,304
	dec cl
	jnz @ll1
	pop ds

	jmp @exit
 @clip:

	push ds

	les di,[dest]
	{cld}
	mov ax,[y]
	mov cl,al
	shl ax,6
	add di,ax
	shl ax,2
	add di,ax
	mov dx,[x]
	add di,dx

	lds si,[source]

	xor bx,bx
	add bh,16
 @l:
	add bl,16
 @l2:
	lodsb
	cmp dx,cx1
	jb @s
	cmp dx,cx2
	ja @s
	cmp cl,cy1
	jb @s
	cmp cl,cy2
	ja @s
 @sc:
	or al,0
	jz @s
	mov es:[di],al
 @s:
	inc di
	inc dx
	dec bl
	jnz @l2
	add di,304
	sub dx,16
	inc cl
	dec bh
	jnz @l

	pop ds

 @exit:
end;

{procedure picorb1(x,y:integer;var dest,source);assembler;
const
	cx1=0;
	cx2=viewx-1;
	cy1=0;
	cy2=viewy-1;
asm
	mov dx,[x]
	mov cx,[y]
	add dx,16
	add cx,16

	cmp dx,cx1+1
	jb @exit
	cmp dx,cx2+16
	ja @exit

	cmp cx,cy1+1
	jb @exit
	cmp cx,cy2+16
	ja @exit

	cmp dx,cx1+16
	jb @clip
	cmp dx,cx2
	ja @clip

	cmp cx,cy1+16
	jb @clip
	cmp cx,cy2
	ja @clip


	push ds

	les di,[dest]
	cld
	mov ax,[y]
	shl ax,6
	add di,ax
	shl ax,2
	add di,ax
	add di,[x]

	lds si,[source]

	xor cx,cx
	add cl,16
 @ll1:
	add ch,16
 @ll2:
	lodsb
	or es:[di],al
	inc di
	dec ch
	jnz @ll2
	add di,304
	dec cl
	jnz @ll1
	pop ds

	jmp @exit
 @clip:

	push ds

	les di,[dest]
	mov ax,[y]
	mov cl,al
	shl ax,6
	add di,ax
	shl ax,2
	add di,ax
	mov dx,[x]
	add di,dx

	lds si,[source]

	xor bx,bx
	add bh,16
 @l:
	add bl,16
 @l2:
	lodsb
	cmp dl,cx1
	jb @s
	cmp dx,cx2
	ja @s
	cmp cl,cy1
	jb @s
	cmp cl,cy2
	ja @s
	or es:[di],al
 @s:
	inc di
	inc dx
	dec bl
	jnz @l2
	add di,304
	sub dx,16
	inc cl
	dec bh
	jnz @l

	pop ds

 @exit:
end;


procedure picorb2(x,y:integer;var dest,source);assembler;
const
	cx1=160;
	cx2=160+viewx-1;
	cy1=0;
	cy2=viewy-1;
asm
	mov dx,[x]
	mov cx,[y]
	add dx,16
	add cx,16

	cmp dx,cx1+1
	jb @exit
	cmp dx,cx2+16
	ja @exit

	cmp cx,cy1+1
	jb @exit
	cmp cx,cy2+16
	ja @exit

	cmp dx,cx1+16
	jb @clip
	cmp dx,cx2
	ja @clip

	cmp cx,cy1+16
	jb @clip
	cmp cx,cy2
	ja @clip


	push ds

	les di,[dest]
	cld
	mov ax,[y]
	shl ax,6
	add di,ax
	shl ax,2
	add di,ax
	add di,[x]

	lds si,[source]

	xor cx,cx
	add cl,16
 @ll1:
	add ch,16
 @ll2:
	lodsb
	or es:[di],al
	inc di
	dec ch
	jnz @ll2
	add di,304
	dec cl
	jnz @ll1
	pop ds

	jmp @exit
 @clip:

	push ds

	les di,[dest]
	mov ax,[y]
	mov cl,al
	shl ax,6
	add di,ax
	shl ax,2
	add di,ax
	mov dx,[x]
	add di,dx

	lds si,[source]

	xor bx,bx
	add bh,16
 @l:
	add bl,16
 @l2:
	lodsb
	cmp dx,cx1
	jb @s
	cmp dx,cx2
	ja @s
	cmp cl,cy1
	jb @s
	cmp cl,cy2
	ja @s
	or es:[di],al
 @s:
	inc di
	inc dx
	dec bl
	jnz @l2
	add di,304
	sub dx,16
	inc cl
	dec bh
	jnz @l

	pop ds

 @exit:
end;}


procedure hline1(x,len,y:integer;c:byte;var dest);assembler;
asm
	les di,dest
	mov bx,y
	shl bx,6
	add di,bx
	shl bx,2
	add di,bx
	add di,x
	mov cx,len
	mov al,c
	mov ah,al
	shr cx,1
	jnc @nc
	stosb
	@nc:
	rep stosw
	add di,320
	add cx,len
	sub di,cx
	shr cx,1
	jnc @nc2
	stosb
	@nc2:
	rep stosw
end;
procedure picor(x,y:integer;var dest,source);assembler;
asm
	mov dx,[x]
	mov cx,[y]
	add dx,16
	add cx,16

	cmp dx,cx1+1
	jb @exit
	cmp dx,cx2+16
	ja @exit

	cmp cx,cy1+1
	jb @exit
	cmp cx,cy2+16
	ja @exit

	cmp dx,cx1+16
	jb @clip
	cmp dx,cx2
	ja @clip

	cmp cx,cy1+16
	jb @clip
	cmp cx,cy2
	ja @clip


	push ds

	les di,[dest]
	cld
	mov ax,[y]
	shl ax,6
	add di,ax
	shl ax,2
	add di,ax
	add di,[x]

	lds si,[source]

	xor cx,cx
	add cl,16
 @ll1:
	add ch,16
 @ll2:
	lodsb
	or al,0
	jz @hyp
	mov es:[di],al
 @hyp:
	inc di
	dec ch
	jnz @ll2
	add di,304
	dec cl
	jnz @ll1
	pop ds

	jmp @exit
 @clip:

	push ds

	les di,[dest]
	{cld}
	mov ax,[y]
	mov cl,al
	shl ax,6
	add di,ax
	shl ax,2
	add di,ax
	mov dx,[x]
	add di,dx

	lds si,[source]

	xor bx,bx
	add bh,16
 @l:
	add bl,16
 @l2:
	lodsb
	cmp dl,cx1
	jb @s
	cmp dx,cx2
	ja @s
	cmp cl,cy1
	jb @s
	cmp cl,cy2
	ja @s
 @sc:
	or al,0
	jz @s
	mov es:[di],al
 @s:
	inc di
	inc dx
	dec bl
	jnz @l2
	add di,304
	sub dx,16
	inc cl
	dec bh
	jnz @l

	pop ds

 @exit:
end;

procedure picor8c(x,y:integer;var dest,source;col:byte);assembler;
asm
	mov dx,[x]
	mov cx,[y]
	add dx,8
	add cx,7

	cmp dx,cx1+1
	jb @exit
	cmp dx,cx2+8
	ja @exit

	cmp cx,cy1+1
	jb @exit
	cmp cx,cy2+7
	ja @exit

	cmp dx,cx1+8
	jb @clip
	cmp dx,cx2
	ja @clip

	cmp cx,cy1+7
	jb @clip
	cmp cx,cy2
	ja @clip

	push ds

	les di,[dest]
	cld
	mov ax,[y]
	shl ax,6
	add di,ax
	shl ax,2
	add di,ax
	add di,[x]

	lds si,[source]

	xor bx,bx
	add bl,7
	mov cl,[col]
 @ll1:
	add bh,8
 @ll2:
	lodsb
	or al,0
	jz @hyp
	mov es:[di],cl
 @hyp:
	inc di
	dec bh
	jnz @ll2
	add di,312
	dec bl
	jnz @ll1
	pop ds
	jmp @exit

 @clip:

	push ds

	les di,[dest]
	{cld}
	xor cx,cx
	mov ax,[y]
	add cl,al
	shl ax,6
	add di,ax
	shl ax,2
	add di,ax
	mov dx,[x]
	add di,dx

	lds si,[source]

	xor bx,bx
	add bh,7
	add ch,[col]
 @l:
	add bl,8
 @l2:
	lodsb
	cmp dl,cx1
	jb @s
	cmp dx,cx2
	ja @s
	cmp cl,cy1
	jb @s
	cmp cl,cy2
	ja @s
 @sc:
	or al,0
	jz @s
	mov es:[di],ch
 @s:
	inc di
	inc dl
	dec bl
	jnz @l2
	add di,312
	sub dl,8
	inc cl
	dec bh
	jnz @l

	pop ds
 @exit:
end;
procedure setmode(mode:word);
begin
	asm
		mov ax,[mode]
		int 10h
	end;
end;

procedure flip(var source,dest); assembler;
asm
	push ds
	lds si,source
	les di,dest
	mov cx,14640
	db 66h; rep movsw
	pop ds
end;

procedure sync;assembler;
asm
	mov dx,3dah
@l1:
	in al,dx
	and al,08h
	jnz @l1
@l2:
	in al,dx
	and al,08h
	jz  @l2
end;

procedure cls(var dest); assembler;
asm
	les di,dest
	xor ax,ax
	db 66h; shl ax,16
	mov cx,14640
	db 66h; rep stosw
end;

procedure writef(x,y:integer;text:string;col:byte;var dest,source);
var
	i:integer;
	b,lev:byte;
	vx:integer;
	p:array[0..259,0..7,0..7]of byte absolute source;
begin
	fontheight:=p[156,7,7];
	vx:=x;
	for i:=1 to length(text) do
	begin
		b:=ord(text[i]);
		if b>0 then begin
			dec(b,2);
			lev:=p[b,7,7];
			if x<=cx2-lev then
				picor8c(x,y,dest,p[b],col)
			else begin
				inc(y,fontheight);
				x:=vx;
				picor8c(x,y,dest,p[b],col);
			end;
			inc(x,lev);
		end else begin
			inc(y,fontheight);
			x:=vx;
		end;
	end;
end;

function exist(name:string):boolean;
var f:file;
begin
	{$i-}
	assign(f,name);
	filemode:=0;
	reset(f);
	close(f);
	{$i+}
	exist:=(ioresult=0)and(name<>'')
end;

function loadpal(var p:palette;name:string):boolean;
var f:file of palette;
begin
	loadpal:=false;
	if exist(name)then
	begin
		assign(f,name);
		reset(f);
		read(f,p);
		close(f);
		loadpal:=true;
	end;
end;
function loaddata(name:string;var p;pos,size:word):word;
var f:file;
	r:word;
begin
	r:=0;
	if exist(name)then
	begin
		assign(f,name);
		reset(f,1);
		seek(f,pos);
		blockread(f,p,size,r);
		close(f);
	end;
	loaddata:=r;
end;

procedure getpal(var c,r,g,b:byte);
begin
	 port[$3c7]:=c;
	 r:=port[$3c9];
	 g:=port[$3c9];
	 b:=port[$3c9];
end;

procedure restpal(p:palette);
var i:byte;
begin
	for i:=0 to 255 do setpal(i,p[i,0],p[i,1],p[i,2]);
end;

procedure cyclepal;
var c,r1,g1,b1,r2,g2,b2:byte;
begin
	getpal(e,r1,g1,b1);
	dec(e);
	for c:=e downto b do begin
		getpal(c,r2,g2,b2);
		setpal(c+1,r2,g2,b2);
	end;
	setpal(b,r1,g1,b1);
end;
end.