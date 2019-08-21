uses crt,mcga,keyboard,pit;

const
	accel=4000;
	contr=$cccc;
	divider=16;
	resist=64500 div divider;
	aika:array[0..3,boolean]of integer=((200,100),(0,0),(80,200),(80,200));
	clear=true;
	numobjs=9;
	autom=true;
	ohjattava=1;
	ohjkuva=20;
	delaytime=0;
	bump=true;
	kuva=22;
	kierros=64*$10000;
	enc:array[0..3]of byte=(47,44,44,40);
	teho=4000;

type
	pos=record
		a,x,y:fixed;
		xb,yb:longint;
		t:array[0..3]of boolean;
		ti:array[0..3]of longint;
		torm:array[1..numobjs]of boolean;
	end;
	tulosrec=record
		nimi:string[10];
		pist:longint;
	end;
	lista=array[0..9]of tulosrec;

var
	v,v2:screen;
	d:chr;
	i,j,fadepal:integer;
	p,p2:palette;
	o:array[1..numobjs]of pos;
	xx,yy:longint;
	k,l:fixed;
	putr:procedure;
	imp,imp2,decby:integer;
	top10:lista;
	oma:tulosrec;

procedure pisteet;
var
	f:file of lista;
	ennatys:boolean;
	i,a:integer;
begin
	ennatys:=false;
	assign(f,'topten.jez');
	if exist('topten.jez')then
	begin
		reset(f);
		read(f,top10);
		close(f);
	end else
	begin
		rewrite(f);
		write(f,top10);
		close(f);
	end;
	i:=0;
	repeat
		if top10[i].pist<oma.pist then ennatys:=true;
		inc(i);
	until (ennatys)or(i>9);
	if ennatys then begin
		writeln('Anna nimesi TopTen-listalle:');
		dec(i);
		if i<9 then
			for a:=8 downto i do top10[i+1]:=top10[i];
		top10[i]:=oma;
	end else
	begin
		writeln('10 parasta v„istelij„„:');
		gotoxy(1,13);
		writeln('Sinun pisteesi t„ll„ kertaa: ',oma.pist);
	end;
	gotoxy(1,2);
	for a:=0 to 9 do
	begin
		write(a+1:2,'. ',top10[a].nimi);
		gotoxy(16,wherey);
		writeln(top10[a].pist:5);
	end;
	if ennatys then begin
		gotoxy(5,i+2);
		readln(top10[i].nimi);
	end;
	gotoxy(1,14);
	rewrite(f);
	write(f,top10);
	close(f);
end;

begin
	write('Initializing...');
	oma.pist:=0;
	imp:=320;
	imp2:=320;
	fadepal:=32;
	for i:=1 to numobjs do for j:=1 to numobjs do o[i].torm[j]:=true;
	fillchar(top10,sizeof(top10),0);
	fillchar(oma,sizeof(oma),0);
	randomize;
	initrot;
	v.init;
	v2.init;
	cls(v2.a,31);
	for xx:=1 to 318 do for yy:=1 to 198 do v2.s^[yy,xx]:=random(13)+18;
	for i:=1 to 3 do for xx:=1 to 318 do for yy:=1 to 198 do v2.s^[yy,xx]:=
		(v2.s^[yy-1,xx]+v2.s^[yy+1,xx]+v2.s^[yy,xx-1]+v2.s^[yy,xx+1])div 4;

	{for xx:=0 to 319 do for yy:=0 to 199 do dec(v2.s^[yy,xx]);}
	d.init;
	d.load('jeps.chr');
	keyinit;
	writeln('OK');
	delay(200);
	setmode(19);
	loadpal(p,'jeps.pal');
	fillpal(p2,63,63,63);
	restpal(p2);
	for i:=1 to numobjs do with o[i] do
	begin
		x.i:=(random(298)+11);
		y.i:=(random(180)+11);
		a.i:=random(64);
		xb:=0;
		yb:=0;
		for j:=0 to 3 do begin
			t[j]:=false;
			ti[j]:=random(aika[j,t[j]]);
		end;
	end;
	flip(v2.a,v.a);
	repeat
		inc(oma.pist);
		for i:=1 to numobjs do with o[i] do
		begin
			if((ohjattava<>i)and(autom)and((t[0]))or((ohjattava=i)and(key[kbup])))then
			begin
				inc(xb,c[a.i]*accel div divd);
				inc(yb,s[a.i]*accel div divd);
				k.l:=c[a.i] shl 3;
				l.l:=s[a.i] shl 3;
				xx:=-k.i;
				yy:=-l.i;
				if ohjattava=i then
					picorr(x.i+xx,y.i+yy,v.a,a.i,0,d.d^[13+random(2)])
				else
					picorr(x.i+xx,y.i+yy,v.a,a.i,0,d.d^[15+random(2)]);
			end;

			if((ohjattava<>i)and(autom)and((t[2]))or((ohjattava=i)and(key[kbleft])))then
				dec(a.l,contr);

			if((ohjattava<>i)and(autom)and((t[3]))or((ohjattava=i)and(key[kbright])))then
				inc(a.l,contr);

			if a.l<0 then inc(a.l,kierros);
			if a.l>kierros-1 then dec(a.l,kierros);

			xb:=xb*resist div (divd div divider);
			yb:=yb*resist div (divd div divider);

			if (x.i<7)or(x.i>(312)) then
			begin
				if x.i<160 then x.i:=7 else x.i:=312;
				xb:=-xb;
				if i=ohjattava then dec(imp,(abs(xb)+abs(yb))div teho);
			end;

			if (y.i<7)or(y.i>(192)) then
			begin
				if y.i<100 then y.i:=7 else y.i:=192;
				yb:=-yb;
				if i=ohjattava then dec(imp,(abs(xb)+abs(yb))div teho);
			end;

			if i=ohjattava then
				picorr(x.i,y.i,v.a,a.i,0,d.d^[ohjkuva])
			else
				picorr(x.i,y.i,v.a,a.i,0,d.d^[kuva]);

			inc(x.l,xb);
			inc(y.l,yb);

			if bump then for j:=1 to numobjs do
				if(i<>j)then
				begin
					if(x.i>o[j].x.i-11)and(x.i<o[j].x.i+11)and
						(y.i>o[j].y.i-11)and(y.i<o[j].y.i+11)then
					begin
						if (torm[j])and(o[j].torm[i])then
						begin
							if (i=ohjattava)or(j=ohjattava)then
								dec(imp,(abs(xb-o[j].xb)+
								abs(yb-o[j].yb))div teho);
							torm[j]:=false;
							o[j].torm[i]:=false;
							xx:=xb;
							yy:=yb;
							xb:=o[j].xb;
							yb:=o[j].yb;
							o[j].xb:=xx;
							o[j].yb:=yy;
						end;
					end else begin
						torm[j]:=true;
						o[j].torm[i]:=true;
					end;
				end;
			for j:=0 to 3 do
			begin
				dec(ti[j]);
				if ti[j]<0 then
				begin

					ti[j]:=random(aika[j,t[j]]);
					t[j]:=not(t[j]);
				end;
			end;
		end;
		if imp2>imp then begin
			inc(decby);
			dec(imp2,decby);
		end else decby:=0;
		if (ohjattava>0)and(imp2>-1) then for i:=0 to 3 do
			hline(0,imp2,196+i,enc[i],v.a);
		sync;
		if fadepal>0 then begin
			dec(fadepal);
			fade(p2,p);
			fade(p2,p);
			restpal(p2);
		end;
		flip(v.a,vgas);
		if clear then flip(v2.a,v.a);
		for i:=1 to numobjs do with o[i] do
		delay(delaytime);
	until (imp2<=0)or(key[kbesc]);
	grabpal(p);
	fillpal(p2,63,63,63);
	for i:=0 to 31 do begin
		fade(p,p2);
		fade(p,p2);
		sync;
		restpal(p);
	end;
	fillpal(p,0,0,0);
	for i:=0 to 63 do begin
		fade(p2,p);
		fade(p2,p);
		sync;
		restpal(p2);
	end;
	setmode(3);
	keydone;
	d.done;
	v.done;
	v2.done;
	pisteet;
end.