program hiiridemo;
uses hiiri1,crt;

var s:array[0..24,0..79,0..1]of byte absolute $b800:0;
	joo:boolean;
procedure handleri;
begin
	lue;
	if h.n[vasen].nyt then s[h.y div 8,h.x div 8,0]:=2;
	port[$20]:=$20;
end;

begin
	if tarkista>0 then begin
		writeln(h.nappeja,'-nappinen hiiri l”ytyi!');
		handler(16,@handleri);
		nakyviin;
		repeat
		lue;
		gotoxy(1,1);
		write(h.x,',',h.y);
		until h.n[oikea].nyt;
		piiloon;
	end else writeln('Hiirt„ ei l”ytynyt!');
end.