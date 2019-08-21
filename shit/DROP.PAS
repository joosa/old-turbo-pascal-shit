{$m $800,0,0}
program tip;

uses crt,dos;

const lukum=2000;
      default=10;
      m:set of byte=[1..31,33..254];

var
   ok,o:integer;
   ss:string;
   l:integer;
   orig:pointer;
   vapaa:array[1..lukum]of boolean;
   i:integer;
   s:byte;
   x,y:array[1..lukum]of integer;
   t:array[1..5]of boolean;
   scr:array[1..25,1..80,1..2]of byte absolute $b800:0;

function r:integer;
begin
     if random(100)>50 then r:=1 else r:=-1;
end;

procedure tiputa(p:integer);
var jo:boolean;
    c:byte;
    yy,xx:integer;
begin
     for s:=1 to 5 do t[s]:=false;
     jo:=false;
     if scr[y[p],x[p]-1,1]  in m then t[1]:=true;
     if scr[y[p]+1,x[p]-1,1]in m then t[2]:=true;
     if scr[y[p]+1,x[p],1]  in m then t[3]:=true;
     if scr[y[p]+1,x[p]+1,1]in m then t[4]:=true;
     if scr[y[p],x[p]+1,1]  in m then t[5]:=true;
     yy:=y[p];
     xx:=x[p];
     if not jo then
     if (y[p]<25)and(not(t[3])) then begin
        inc(y[p]);
        jo:=true;
     end;
     if not jo then
     if(y[p]<25)and(((t[1])and(t[3]))or((t[2])and(t[3])))and
     ((not(t[4]))and(not(t[5]))and(x[p]<80))then begin
        inc(x[p]);
        inc(y[p]);
        jo:=true;
     end;
     if not jo then
     if(y[p]<25)and(((t[5])and(t[3]))or((t[4])and(t[3])))and
     ((not(t[1]))and(not(t[2]))and(x[p]>1))then begin
        dec(x[p]);
        inc(y[p]);
        jo:=true;
     end;
     if not jo then
     if(y[p]<25)and(t[3])and((not(t[1]))and(not(t[2])))and
     ((not(t[5]))and(not(t[4]))) then begin
        if x[p] in[2..79] then inc(x[p],r) else begin
           if x[p]=1 then inc(x[p]);
           if x[p]=80 then dec(x[p]);
        end;
        inc(y[p]);
        jo:=true;
     end;

     if not jo then vapaa[p]:=true;

     if (yy<>y[p]) then begin
        c:=scr[yy,xx,1];
        scr[yy,xx,1]:=32;
        scr[y[p],x[p],1]:=c;
     end;
end;

procedure oma;interrupt;
begin
     for i:=1 to l do begin
     if vapaa[i] then begin
        x[i]:=1+random(80);
        y[i]:=1+random(25);
        if scr[y[i],x[i],1]in m then
           vapaa[i]:=false;
     end else tiputa(i);
     end;
     asm
        pushf
        call orig
     end;
end;

procedure inhvo;
begin
     writeln('DROP k„ynnistetty.');
     writeln;
     if paramcount=1 then begin
        val(paramstr(1),o,ok);
        if ok=0 then begin
           if (o>0)and(o<2001) then l:=o else l:=default;
        end else l:=default;
     end else begin
     writeln('Montako merkki„ enint„„n tippuu yht„aikaa [1..2000]?');
     writeln('(Huom! voit antaa luvun my”s k„ynnist„ess„ n„in:');
     writeln('       DROP xx');
     writeln('miss„ xx on enimm„ism„„r„.)');
     writeln('Pelkk„ Enter asettaa oletusarvon (10).');
     repeat
     write('?');
     readln(ss);
     if ss='' then begin
        ok:=0;
        o:=default;
     end else val(ss,o,ok);
     until (ok=0)and((o>0)and(o<2001));
     l:=o;
     end;
     writeln('Merkkej„ tippuu yht„aikaa enint„„n: ',l);
     writeln('Paina jotain...');
     readkey;
     while keypressed do readkey;
end;

begin
     inhvo;
     for i:=1 to l do vapaa[i]:=true;
     randomize;
     getintvec(8,orig);
     setintvec(8,@oma);
     keep(0);
     setintvec(8,orig);
end.