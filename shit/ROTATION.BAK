program rotation_test;

uses crt,dos;

const
	divd:word=128;
	rot:word=10;
	index=0;
	filename='jeps.chr';
	waitstate=5;
	vga:word=$a000;
	alue:byte=6;

type
	rotarray=array[0..127,byte]of byte;
	chrarray=array[0..200,byte]of byte;

var
	r:rotarray;
	f:file;
	s:array[0..199,0..319]of byte absolute $a000:0;
	chr:^chrarray;
	chradd,rotadd:word;

procedure initrotarray;
var
	i,x,y,nx,ny,n:integer;
	c,s:real;
begin
	write('Doing some calculations');
	for i:=0 to 127 do
	begin
		if i mod 5=0 then write('.');
		s:=-sin((i+32)*pi/64);
		c:=cos((i+32)*pi/64);
		for x:=-alue to alue do for y:=-alue to alue do
		begin
			nx:=round(s*x-c*y);
			ny:=round(c*x+s*y);
			n:=(ny+7)shl 4+nx+7;
			if n in[0..255]then
				r[i,(y+7) shl 4+x+7]:=n
			else
				r[i,(y+7) shl 4+x+7]:=255;
		end;
	end;
	rotadd:=seg(r);
	writeln('OK');
	readkey;
end;

procedure picorr(i,x,y,d:word);
var p,a,b,c:word;
begin
	dec(y,7);
	dec(x,8);
	p:=0;
	b:=0;
	for a:=0 to 255 do
	begin
		c:=r[d,b shl 4+15-p];
		if chr^[i,c]>0 then
			s[y+b,x+p]:=chr^[i,c];
		inc(p);
		if p>15 then
		begin
			p:=0;
			inc(b);
		end;
	end;
end;

procedure picr(i,x,y,d:word);
var p,a,b,c:word;
begin
	dec(y,7);
	dec(x,8);
	p:=0;
	b:=0;
	for a:=0 to 255 do
	begin
		c:=r[d,b shl 4+15-p];
		s[y+b,x+p]:=chr^[i,c];
		inc(p);
		if p>15 then
		begin
			p:=0;
			inc(b);
		end;
	end;
end;


var
	w:word;
	x,y:integer;
	ss,cc:real;

begin
	new(chr);
	chradd:=seg(chr^);
	initrotarray;
	asm mov ax,13h;int 10h;end;
	assign(f,filename);
	reset(f,1);
	seek(f,4);
	blockread(f,chr^,sizeof(chr^));
	close(f);
	repeat
		for x:=-7 to 7 do for y:=-7 to 7 do
		begin
			ss:=sin((rot+32)*pi/64);
			cc:=cos((rot+32)*pi/64);
			s[y+7,x+7]:=chr^[index,(round(ss*x-cc*y)+7)shl 4+round(cc*x+ss*y)+7];
		end;
		inc(rot);
		if rot>127 then rot:=0;
	until keypressed;
	readkey;
	readkey;
	repeat
		picr(index,0,0,rot);
		inc(rot);
		if rot>127 then rot:=0;
	until keypressed;
	readkey;
	readkey;
	asm mov ax,3h;int 10h;end;
	dispose(chr);
end.