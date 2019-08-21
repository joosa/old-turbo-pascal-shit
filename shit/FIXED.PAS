type
	fixed=record case boolean of
		true:(l:longint);
		false:(w:word;i:integer);
	end;

var
	x,y:fixed;

begin
	x.l:=-$00005678;
	writeln(21*2111);
end.