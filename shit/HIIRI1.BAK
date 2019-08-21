unit hiiri1;


interface


type
	napit=(vasen,oikea,keski);

	muutos=record
		kpl,x,y:word;
	end;

	nappi=record
		nyt:boolean;
		m:array[boolean]of muutos;
	end;

	hiiri=record
		nappeja:byte;
		x,y:word;
		dx,dy:integer;
		n:array[napit]of nappi;
	end;

const
	maski:array[napit]of byte=(1,2,4);

var
	h:hiiri;


function tarkista:integer;
procedure nakyviin;
procedure piiloon;
procedure lue;
procedure liikuta(x,y:word);
function alas(n:napit):boolean;
function ylos(n:napit):boolean;
procedure rajat(xmin,ymin,xmax,ymax:word);
procedure siirros;
procedure handler(ehto:word;mousehandler:pointer);


implementation


uses dos;

var
	r:registers;


function tarkista:integer;
begin
	r.ax:=0;
	intr($33,r);
	if r.ax=0 then h.nappeja:=0;
	if r.bx=3 then h.nappeja:=3
	else if r.bx=0 then h.nappeja:=1
	else h.nappeja:=2;
	tarkista:=h.nappeja;
end;

procedure nakyviin;
begin
	r.ax:=1;
	intr($33,r);
end;

procedure piiloon;
begin
	r.ax:=2;
	intr($33,r);
end;

procedure lue;
begin
	r.ax:=3;
	intr($33,r);
	h.n[vasen].nyt:=(r.bl and maski[vasen])<>0;
	h.n[oikea].nyt:=(r.bl and maski[oikea])<>0;
	h.n[keski].nyt:=(r.bl and maski[keski])<>0;
	h.x:=r.cx;
	h.y:=r.dx;
end;

procedure liikuta(x,y:word);
begin
	r.ax:=4;
	r.cx:=x;
	r.dx:=y;
	intr($33,r);
	lue;
end;

function alas(n:napit):boolean;
begin
	r.ax:=5;
	r.bx:=ord(n);
	intr($33,r);
	h.n[n].nyt:=(r.al and maski[n])<>0;
	h.n[n].m[true].kpl:=r.bx;
	h.n[n].m[true].x:=r.cx;
	h.n[n].m[true].y:=r.dx;
	alas:=h.n[n].nyt;
end;

function ylos(n:napit):boolean;
begin
	r.ax:=6;
	r.bx:=ord(n);
	intr($33,r);
	h.n[n].nyt:=(r.al and maski[n])<>0;
	h.n[n].m[false].kpl:=r.bx;
	h.n[n].m[false].x:=r.cx;
	h.n[n].m[false].y:=r.dx;
	ylos:=h.n[n].nyt;
end;

procedure rajat(xmin,ymin,xmax,ymax:word);
begin
	r.ax:=7;
	r.cx:=xmin;
	r.dx:=ymin;
	intr($33,r);
	r.ax:=8;
	r.cx:=xmax;
	r.dx:=ymax;
	intr($33,r);
end;

procedure siirros;
begin
	r.ax:=$b;
	intr($33,r);
	h.dx:=r.cx;
	h.dy:=r.dx;
end;

procedure handler(ehto:word;mousehandler:pointer);
begin
	r.es:=seg(mousehandler^);
	r.dx:=ofs(mousehandler^);
	r.ax:=$c;
	r.cx:=ehto;
	intr($33,r)
end;


end.