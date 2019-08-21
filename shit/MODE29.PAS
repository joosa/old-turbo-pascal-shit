uses crt,mcga;

type
	block=array[0..99,0..639]of byte;

var
	s1:block absolute $a000:0;
	s2:block absolute $afa0:0;
	s3:block absolute $afa0+$0fa0:0;
	s4:block absolute $a000+$0fa0+$fa0:0;

procedure pset(x,y:integer;c:byte);
begin
	case y of
		0..99:s1[y,x]:=c;
		100..199:s2[y-100,x]:=c;
		200..299:s3[y-200,x]:=c;
		300..399:s4[y-300,x]:=c;
	end;
end;

begin
	setvesa($100);
	pset(639,99,15);
	pset(639,100,15);
	pset(639,101,15);
	readkey;
	setmode(3);
end.