unit keyboard;
interface

const
		 kbesc=1;
		 kb1=2;
		 kb2=3;
		 kb3=4;
		 kb4=5;
		 kb5=6;
		 kb6=7;
		 kb7=8;
		 kb8=9;
		 kb9=10;
		 kb0=11;
		 kbplus=12;
		 kbheitto=13;
		 kbbksp=14;
		 kbtab=15;
		 kbq=16;
		 kbw=17;
		 kbe=18;
		 kbr=19;
		 kbt=20;
		 kby=21;
		 kbu=22;
		 kbi=23;
		 kbo=24;
		 kbp=25;
		 kbro=26;
		 kbtilde=27;
		 kbenter=28;
		 kblctrl=29;
		 kba=30;
		 kbs=31;
		 kbd=32;
		 kbf=33;
		 kbg=34;
		 kbh=35;
		 kbj=36;
		 kbk=37;
		 kbl=38;
		 kboe=39;
		 kbae=40;
		 kbasterisk=41;
		 kblshift=42;
		 kblarger=43;
		 kbz=44;
		 kbx=45;
		 kbc=46;
		 kbv=47;
		 kbb=48;
		 kbn=49;
		 kbm=50;
		 kbcomma=51;
		 kbpoint=52;
		 kb_=53;
		 kbrshift=54;
		 kbkasterisk=55;
		 kblalt=56;
		 kbspace=57;
		 kbcapslock=58;
		 kbf1=59;
		 kbf2=60;
		 kbf3=61;
		 kbf4=62;
		 kbf5=63;
		 kbf6=64;
		 kbf7=65;
		 kbf8=66;
		 kbf9=67;
		 kbf10=68;
		 kbknumlock=69;
		 kbscrolllock=70;
		 kbkhome=71;
		 kbkup=72;
		 kbkpgup=73;
		 kbkminus=74;
		 kbkleft=75;
		 kbk5=76;
		 kbkright=77;
		 kbkplus=78;
		 kbkend=79;
		 kbkdown=80;
		 kbkpgdn=81;
		 kbkinsert=82;
		 kbkdelete=83;
		 kbf11=87;
		 kbf12=88;

		 kbkenter=88+28;
		 kbrctrl=88+29;
		 kbkper=88+53;
		 kbralt=88+56;
		 kbhome=88+71;
		 kbup=88+72;
		 kbpgup=88+73;
		 kbleft=88+75;
		 kbright=88+77;
		 kbend=88+79;
		 kbdown=88+80;
		 kbpgdn=88+81;
		 kbinsert=88+82;
		 kbdelete=88+83;

		 {knames:array[1..171]of string=
		 ('Esc','1','2','3','4','5','6','7','8','9','0','+','Ô','Backspace','Tab','Q',
		 'W','E','R','T','Y','U','I','O','P','è','˘','Enter','Left Crtl','A','S',
		 'D','F','G','H','J','K','L','ô','é','''','Left Shift','<','Z','X','C','V',
		 'B','N','M',',','.','_','Right Shift','Numpad *','Left Alt','Caps Lock',
		 'F1','F2','F3','F4','F5','F6','F7','F8','F9','F10','Num Lock',
		 'Scroll Lock','Home (Num)',#24' (Num)','Page Up (Num)','- (Num)',
		 #27' (Num)','5 (Num)',#26' (Num)','+ (Num)','End (Num)','','','','','','','','',
		 '','','','','','','','','','','','','','',}
var key:array[1..171]of boolean;

procedure keyinit;
procedure keydone;
function pressed:boolean;

implementation
uses dos;
var bioshandler:pointer;
		ex:boolean;

procedure handler;interrupt;
var k,kk:byte;
begin
		asm pushf end;
		if ex then
		begin
			k:=port[$60];
			Kk := k and $7F ;
			key[kk+88]:=(k and $80)=0;
			ex:=false;
		end else
		begin
			k:=port[$60];
			if k=224 then ex:=true
			else begin
				Kk := k and $7F ;
				key[kk]:=(k and $80)=0;
				ex:=false;
			end;
		end;
		asm popf end;
		port[$20]:=$20;
end;

procedure keyinit;
begin
		 ex:=false;
		 fillchar(key,sizeof(key),0);
		 getintvec(9,bioshandler);
		 setintvec(9,@handler);
end;

procedure keydone;
begin
		 setintvec(9,bioshandler);
end;

function pressed;
var i:byte;
begin
	for i:=171 downto 1 do if key[i] then begin
		pressed:=true;
		exit;
	end;
	pressed:=false;
end;

end.