uses crt,mcga;

const
	kesto=5;
	secs=round(18.2*kesto);

var
	st,l:longint;
	d:array[0..5000]of byte;

begin
	setmode($13);
	l:=0;
	st:=time;
	if loaddata('jeps.chr',@d,16*16+4)>0then
	begin
		sprite(0,0,vgas,16,10,0,d[3]);
	end;
	repeat
		inc(l);
		{line2(random(320),random(200),random(320),random(200),random(256),vgas);}
		line(0,0,319,199,random(256),vgas);
	until time-st>=secs;
	setmode($3);
	writeln('Lines Drawn in 1 Second: ',l div kesto);
	readkey;
end.