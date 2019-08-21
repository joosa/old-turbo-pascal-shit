unit area;

interface

const
	maxheight=16382;

type
	pArea=^tArea;
	tline=array[0..65520]of byte;
	tArea=array[0..maxheight]of ^tline;

function init(var a:parea;w,h:word):boolean;
function done(var a:parea):boolean;
function load(var a:parea;n:string;pos:word):boolean;
procedure show(var a;mw,w,h:word;var dest);
function loadpcx(var m:parea;name:string):boolean;

implementation
uses grap;

var
	width,height:word;

function init;
var i:word;
begin
	init:=false;
	width:=w;
	height:=h;
	{if memavail<width*height then exit;}
	new(a);
	for i:=0 to height-1 do begin
		if maxavail<width then exit;
		getmem(a^[i],width);
	end;
	init:=true;
end;

function done;
var i:word;
begin
	{i:=0;
	while a^[i]<>nil do begin
		freemem(a^[i],width);
		inc(i);
	end;}
	for i:=0 to height-1 do if a^[i]<>nil then freemem(a^[i],width);
	dispose(a);
	done:=true;
end;

function load;
var
	f:file;
	i,r:word;
begin
	load:=false;
	if not exist(n) then exit;
	assign(f,n);
	reset(f,1);
	seek(f,pos);
	for i:=0 to height-1 do begin
		blockread(f,a^[i]^,width,r);
		if r<width then break;
	end;
	close(f);
	load:=true;
end;

{procedure show;
var s:array[0..199,0..319]of byte absolute dest;
var i:integer;
begin
	dec(h);
	for i:=y to y+h do begin
		move(a^[i]^[x],s[sy,sx],w);
		inc(sy);
	end;
end;}

procedure show;assembler;
asm
	cli
	push ds
	lds si,a
	les di,dest
	mov bx,320
	sub bx,w
	mov ax,mw
	sub ax,w
	shr w,1
	jnc @io
	mov dx,h
	xor cx,cx
@loop:
	add cx,w
	movsb
	rep movsw
	add di,bx
	add si,ax
	dec dx
	jnz @loop
	pop ds
jmp @exit
@io:
	mov dx,h
	xor cx,cx
@loop2:
	add cx,w
	rep movsw
	add di,bx
	add si,ax
	dec dx
	jnz @loop2
	pop ds
@exit:
	sti
end;

function loadpcx;
var
	w,h:integer;
	p,s:longint;
	a,b:byte;
	f:file;
begin
	loadpcx:=false;
	if exist(name)then begin
		assign(f,name);
		reset(f,1);
		seek(f,8);
		blockread(f,w,2);
		blockread(f,h,2);
		inc(w);
		inc(h);
		if init(m,w,h)then begin
			seek(f,128);
			s:=w*h;
			p:=0;
			repeat
				blockread(f,a,1);
				if a>192 then begin
					blockread(f,b,1);
					for a:=a to 191 do begin
						m^[p div w]^[p mod w]:=b;
						inc(p);
					end;
				end else begin
					m^[p div w]^[p mod w]:=a;
					inc(p);
				end;
			until p=w*h;
		end;
		close(f);
	end;
end;

end.