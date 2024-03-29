program hee;

uses crt,dos;

const
	blocksize=1024;
	maxsize:longint=1024;
	maxcount=5;
	nesting:longint=6;
	version='1.4';
	usagestr='Usage:  HEE [/F /Dx /Mx /A[rsha] /L[name] /E[name] /?]';
	filecol=10;
	dircol=11;
	deflog='HEE.LOG';

type
	block=array[1..blocksize]of byte;

var
	f:file of block;
	ff:file of byte;
	b:block;
	fl,dr,nest:longint;
	n,p,log,efile:string;
	x,y:integer;
	count,s,ws,i:longint;
	a:byte;
	df:boolean;
	wholesize:longint;
	ats:byte;
	lf:text;

procedure error(s:string);
begin
	writeln('ERROR: ',s);
	halt;
end;

function attr:byte;
var a:byte;
begin
	if ats=255 then begin
		a:=0;
		if random(10)<5 then a:=readonly;
		if random(10)<5 then a:=a+sysfile;
		if random(10)<5 then a:=a+hidden;
		if random(10)<5 then a:=a+archive;
		attr:=a;
	end else begin
		attr:=ats;
	end;
end;

function rn:string;
var n:string;
begin
	n:='';
	for i:=0 to random(8) do n:=n+chr(65+random(26));
	if random(10)<5 then begin
		n:=n+'.';
		for i:=0 to random(3) do n:=n+chr(65+random(26));
	end;
	rn:=n;
end;

function at(a:byte):string;
var s:string;
begin
	s:='';
	if a and readonly<>0 then s:=s+'R';
	if a and hidden<>0 then s:=s+'H';
	if a and sysfile<>0 then s:=s+'S';
	if a and archive<>0 then s:=s+'A';
	at:='('+s+')';
end;

procedure writename;
begin
	textcolor(15);
	write('HEE ');
	textcolor(7);
	writeln('v'+version+' - Copyright Mets�nEl�imet 1998');
end;

procedure usage;
begin
	writeln(usagestr);
	writeln;
	writeln('    /F       Disable (F)ile creating (default: create files)');
	writeln('    /Dx      (D)irectory nesting level x (0=no dirs)');
	writeln('    /Mx      (M)aximum size x kilobytes (default: 1024)');
	writeln('    /A[rsha] (A)ttributes of the files and directories:');
	writeln('             R(ead-only), S(ystem), H(idden), A(rchive)');
	writeln('             (default: random)');
	writeln('    /L[name] Create (L)og file [name]. If no name is specified,');
	writeln('             it will be "'+deflog+'".');
	writeln('    /E[name] (E)rase all files and directories listed in file [name].');
	writeln('             If no name is specified, "'+deflog+'" will be used.');
	writeln('    /?,/H    (H)elp');
	writeln;
	writeln('You can also use the switches like this:');
	writeln('  HEE -f');
end;

function tod(s:string):longint;
var i:integer;
	l:longint;
begin
	val(s,l,i);
	if i=0 then tod:=l else tod:=-1;
end;

function tos(i:longint):string;
var s:string;
begin
	str(i,s);
	tos:=s;
end;

procedure smallh;
begin
	writeln(usagestr);
	halt;
end;

procedure writeops;
const
	onoff:array[boolean]of string=('No','Yes');
begin
	writename;
	if efile='' then begin
		writeln('Create files:',onoff[df]:26);
		writeln('Directory nesting:',nesting:21);
		if df then writeln('Maximum size:',tos(maxsize*blocksize)+
			' bytes ('+tos(maxsize)+'K)':26);
		write('Attributes:');
		if ats=255 then writeln('Random':28)
			else writeln(at(ats):28);
		if log<>'' then writeln('Log file:',log:30);
	end else writeln('Erasing all files and directories listed in "'+efile+'".');
	writeln;
end;

function exist(name:string):boolean;
var f:file;
begin
{$i-}
	assign(f,name);
	filemode:=0;
	reset(f);
	close(f);
{$i+}
	exist:=(ioresult=0)and(name<>'');
end;

procedure parametrit;
var ps:string;
	apu:longint;
	f:file;
begin
	if paramcount<>0 then
		for i:=1 to paramcount do begin
			ps:=paramstr(i);
			if ps[1] in['/','-']then begin
				case ps[2] of
					'F','f':df:=false;
					'D','d':begin
						apu:=tod(copy(ps,3,length(ps)-2));
						if apu>-1 then nesting:=apu else smallh;
					end;
					'M','m':begin
						apu:=tod(copy(ps,3,length(ps)-2));
						if apu>-1 then maxsize:=apu else smallh;
					end;
					'A','a':begin
						apu:=0;
						for x:=3 to length(ps) do
							case ps[x] of
								'R','r':if apu and readonly=0 then inc(apu,readonly);
								'S','s':if apu and sysfile=0 then inc(apu,sysfile);
								'H','h':if apu and hidden=0 then inc(apu,hidden);
								'A','a':if apu and archive=0 then inc(apu,archive);
								else smallh;
							end;
						ats:=apu;
					end;
					'L','l':begin
						for x:=3 to length(ps) do log:=log+ps[x];
						if log='' then log:=deflog;
						if not(exist(log))then begin
							{$i-}
							assign(f,log);
							filemode:=0;
							rewrite(f);
							close(f);
							{$i+}
							if ioresult<>0 then error('"'+log+'" cannot be created!');
						end else error('"'+log+'" already exists!');
					end;
					'E','e':begin
						for x:=3 to length(ps) do efile:=efile+ps[x];
						if efile='' then efile:=deflog;
						if not(exist(efile))then error('"'+efile+'" cannot be found!');
					end;
					'?','H','h':begin
						usage;
						halt;
					end;
					else smallh;;
				end;
			end else smallh;
		end;
end;

procedure setup;
begin
	fl:=0;
	dr:=0;
	df:=true;
	log:='';
	efile:='';
	ats:=255;
	wholesize:=maxsize*blocksize;
	randomize;
	nest:=0;
	getdir(0,p);
	parametrit;
	if df then count:=random(maxcount) else count:=-1;
	if p[length(p)]<>'\' then p:=p+'\';
end;

procedure dirs;
begin
		if df then dec(count);
		if (count<0)then begin
			if df then count:=random(maxcount);
			if random(100)<50 then begin
				if nest>0 then begin
					if log<>'' then writeln(lf,'Dir  '+p);
					chdir('..');
					getdir(0,p);
					if p[length(p)]<>'\' then p:=p+'\';
					dec(nest);
				end;
			end else if nest<nesting then begin
				n:=rn;
				{$i-}
				mkdir(n);
				{$i+}
				if ioresult=0 then begin
					rmdir(n);
					a:=attr;
					inc(dr);
					textcolor(7);
					write('Creating dir (',dr,') ');
					textcolor(dircol);
					write(p+n+'\ ');
					textcolor(7);
					writeln(at(a));
					mkdir(n);
					assign(f,n);
					setfattr(f,directory);
					setfattr(f,a);
					inc(nest);
					chdir(n);
					getdir(0,p);
					if p[length(p)]<>'\' then p:=p+'\';
				end;
			end;
		end;
end;

procedure files;
begin
		n:=rn;
		if not exist(n) then begin
			a:=attr;
			inc(fl);
			textcolor(7);
			write('Creating file (',fl,') ');
			textcolor(filecol);
			write(p+n);
			if log<>'' then writeln(lf,'File '+p+n);
			textcolor(7);
			write(' '+at(a));
			assign(f,n);
			setfattr(f,archive);
			rewrite(f);
			s:=0;
			if maxsize>0 then for i:=1 to random(maxsize+1) do begin
				if (diskfree(0)<wholesize)or(keypressed) then break;
				for x:=0 to blocksize do b[x]:=random(256);
				write(f,b);
				inc(s);
			end;
			while keypressed do readkey;
			writeln(' ',s*blocksize,' bytes');
			inc(ws,s);
			close(f);
			setfattr(f,a);
		end;
end;

procedure havesomefun;
begin
	if log<>'' then assign(lf,log);
	rewrite(lf);
	repeat
		if nesting>0 then dirs;
		if df then files;
	until (port[$60]=1)or(diskfree(0)<wholesize);
	for i:=1 to nest do begin
		getdir(0,p);
		if p[length(p)]<>'\' then p:=p+'\';
		if log<>'' then writeln(lf,'Dir  '+p);
		chdir('..');
	end;
	close(lf);
end;

procedure eraseall;
var
	s,n:string;
	ef:text;
	f:file;
	c:char;
begin
	assign(ef,efile);
	reset(ef);
	repeat
		readln(ef,s);
		case s[1] of
			'D':begin
				{$i-}
				n:=copy(s,6,length(s)-6);
				textcolor(7);
				write('Removing dir (',dr+1,') ');
				textcolor(dircol);
				write(n+'\');
				rmdir(n);
				textcolor(7);
				{$i+}
				if ioresult<>0 then writeln(' Not found!') else begin
					inc(dr);
					writeln;
				end;
			end;
			'F':begin
				{$i-}
				n:=copy(s,6,length(s)-5);
				textcolor(7);
				write('Erasing file (',fl+1,') ');
				textcolor(filecol);
				write(n);
				assign(f,n);
				setfattr(f,archive);
				erase(f);
				textcolor(7);
				{$i+}
				if ioresult<>0 then writeln(' Not found!') else begin
					inc(fl);
					writeln;
				end;
			end;
		end;
	until (eof(ef))or(port[$60]=1);
	close(ef);
	textcolor(7);
	write('Do you want to erase the log file [Y/N]? ');
	repeat
		c:=readkey;
		c:=upcase(c);
	until c in ['Y','N'];
	if c='Y' then begin
		writeln('Y');
		write('Erasing file (',fl+1,') ');
		textcolor(filecol);
		write(efile);
		inc(fl);
		erase(ef);
	end else writeln('N');
end;

begin
	setup;
	writeops;
	write('Press ''Y'' to continue, any other key to quit...');
	if not(readkey in ['y','Y']) then begin
		writeln;
		halt;
	end;
	while keypressed do readkey;
	writeln;
	if efile='' then begin
		ws:=0;
		havesomefun;
		textcolor(7);
		writeln;
		writename;
		writeln('Directories created:',dr:19);
		writeln('Files created:',fl:25);
		if log<>'' then begin
			assign(ff,log);
			reset(ff);
			writeln('Log file size: ',tos(filesize(ff))+' bytes ('+tos(filesize(ff) div 1024)+'K)':24);
		end;
		writeln('Total size:',tos(ws*blocksize+filesize(ff))+
			' bytes ('+tos((ws*blocksize+filesize(ff))div 1024)+'K)':28);
		if log<>'' then close(ff);
	end else begin
		eraseall;
		writeln;
		writename;
		writeln('Directories removed:',dr:19);
		writeln('Files erased:',fl:26);
	end;
end.