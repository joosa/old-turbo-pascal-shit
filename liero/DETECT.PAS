{       SMIX is Copyright 1995 by Ethan Brodsky.  All rights reserved.       }
unit Detect;
  interface
    function GetSettings
     (
      var BaseIO : word;
      var IRQ    : byte;
      var DMA    : byte;
      var DMA16  : byte
     ): boolean;
      {Gets sound card settings from BLASTER environment variable            }
      {Parameters:                                                           }
      {  BaseIO:  Sound card base IO address                                 }
      {  IRQ:     Sound card IRQ                                             }
      {  DMA:     Sound card 8-bit DMA channel                               }
      {  DMA16:   Sound card 16-bit DMA channel (0 if none)                  }
      {Returns:                                                              }
      {  TRUE:    Sound card settings found successfully                     }
      {  FALSE:   Sound card settings could not be found                     }

  implementation
    uses
      DOS;
    function UpcaseStr(Str: string): string;
      var
        i: byte;
        Temp: string;
      begin
        Temp[0] := Str[0];
        for i := 1 to Length(Str) do
          Temp[i] := Upcase(Str[i]);
        UpcaseStr := Temp;
      end;
    function GetSetting(Str: string; ID: char; Hex: boolean): word;
      var
        Temp : string;
        Num  : word;
        Code : integer;
      begin
        Temp := Str;
        if Pos(ID, Temp) <> 0
          then
            begin
              Delete(Temp, 1, Pos(ID, Temp));
              Delete(Temp, Pos(' ', Temp), 255);
              if Hex then Insert('$', Temp, 1);
              Val(Temp, Num, Code);
              if Code = 0
                then GetSetting := Num
                else GetSetting := $FF;
            end
          else
            GetSetting := $FF;

      end;
    function GetSettings
     (
      var BaseIO: word;
      var IRQ: byte;
      var DMA: byte;
      var DMA16: byte
     ): boolean;
      var
        BLASTER: string;
      begin
        BLASTER := UpcaseStr(GetEnv('BLASTER'));
        BaseIO := GetSetting(BLASTER, 'A', true);  {Hex}
        IRQ    := GetSetting(BLASTER, 'I', false); {Decimal}
        DMA    := GetSetting(BLASTER, 'D', false); {Decimal}
        DMA16  := GetSetting(BLASTER, 'H', false); {Decimal}

        GetSettings := true;
        if BLASTER = ''  then GetSettings := false;
        if BaseIO  = $FF then GetSettings := false;
        if IRQ     = $FF then GetSettings := false;
        if DMA     = $FF then GetSettings := false;
        {We can survive if there isn't a DMA16 channel}
      end;
  end.