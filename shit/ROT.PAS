uses crt,mcga;

var
	a,i:byte;
	c:chr;
	s:screen;


begin
	write('Precalculating rotations..');
	initrot;
	writeln('OK');
	c.init;
	c.load('jeps.chr');
	s.init;
	setmode($13);
	repeat
		cls(s.a,0);
			picorr(3,10,10,c.a,s.a,a);
		{sync;}
		flip(s.a,vgas);
		{picr(3,15,15,c.a,vgas,a);}
		inc(a);
		if a>63 then a:=0;
		{readkey;}
	until port[$60]=1;
	c.done;
	s.done;
	setmode(3);
end.