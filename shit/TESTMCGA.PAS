uses crt,mcga;

const
	aika=2;
	joo=round(aika*18.2);

var
	s:screen;
	c:chr;
	i:integer;
	f,p:palette;
	t:array[0..7]of longint;
	l:longint;

procedure speed;
begin
	setmode(19);
	clipon:=true;
	cls(vgas,0);
	fillchar(t,sizeof(t),0);

	l:=time;
	repeat
		inc(t[0]);
		pic(random(320),random(200),vgas,c.d^[random(50)]);
	until time-l>=joo;

	cls(vgas,0);

	l:=time;
	repeat
		inc(t[1]);
		picor(random(320),random(200),vgas,c.d^[random(50)]);
	until time-l>=joo;

	cls(vgas,0);

	l:=time;
	repeat
		inc(t[2]);
		picr(random(320),random(200),vgas,random(64),c.d^[random(50)]);
	until time-l>=joo;

	cls(vgas,0);

	l:=time;
	repeat
		inc(t[3]);
		picorr(random(320),random(200),vgas,random(64),c.d^[random(50)]);
	until time-l>=joo;

	cls(vgas,0);

	l:=time;
	repeat
		inc(t[4]);
		cls(vgas,random(256));
	until time-l>=joo;

	l:=time;
	repeat
		inc(t[5]);
		flip(s.a,vgas);
	until time-l>=joo;

	l:=time;
	repeat
		inc(t[6]);
		sprite(random(320),random(200),vgas,16,16,c.d^[random(20)]);
		{drawsprite(0,0,vgas,16,16,0,c.d^[random(20)]);}
	until time-l>=joo;

	setmode(3);
	writeln('Pic:    ',t[0]div aika,' times per second.');
	writeln('PicOr:  ',t[1]div aika,' times per second.');
	writeln('PicR:   ',t[2]div aika,' times per second.');
	writeln('PicOrR: ',t[3]div aika,' times per second.');
	writeln('Cls:    ',t[4]div aika,' times per second.');
	writeln('Flip:   ',t[5]div aika,' times per second.');
	writeln('Sprite: ',t[6]div aika,' times per second.');

	writeln(t[0]div 250 div aika);
	readkey;
end;

procedure testjotain;
begin
	setmode(19);
	picor(16,16,vgas,c.d^[0]);
	picr(20,20,vgas,0,c.d^[0]);
	readkey;
	setmode(3);
end;

begin
	randomize;
	s.init;
	c.init;
	initrot;
	c.load('jeps.chr');
	speed;
	{testjotain;}
	s.done;
	c.done;
end.