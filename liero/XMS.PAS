{       SMIX is Copyright 1995 by Ethan Brodsky.  All rights reserved.       }
unit XMS;
  interface
   {Initialization}
    function XMSInstalled: boolean;
    procedure XMSInit;

   {Informational}
    function XMSGetVersion: word;
    function XMSGetFreeMem: word;

   {Allocation and deallocation}
    function XMSAllocate(var Handle: word; Size: word): boolean;
    function XMSReallocate(Handle: word; NewSize: word): boolean;
		function XMSFree(Handle: word): boolean;

	 {Memory moves}
		type
			PMoveParams = ^TMoveParams;
			TMoveParams =
				record
					Length       : LongInt;  {Length must be a multiple of two}
					SourceHandle : word;
					SourceOffset : LongInt;
					DestHandle   : word;
					DestOffset   : LongInt;
				end;
		function XMSMove(Params: PMoveParams): boolean;

	implementation  {����������������������������������������������������������}
		var
			XMSDriver: pointer;

{����������������������������������������������������������������������������}

		function XMSInstalled: boolean; assembler;
			asm
				mov    ax, 4300h
				int    2Fh
				cmp    al, 80h
				jne    @NoXMSDriver
				mov    al, TRUE
				jmp    @Done
			 @NoXMSDriver:
				mov    al, FALSE
			 @Done:
			end;

{����������������������������������������������������������������������������}

		procedure XMSInit; assembler;
			asm
				mov    ax, 4310h
				int    2Fh
				mov    word ptr [XMSDriver], bx
				mov    word ptr [XMSDriver+2], es
			end;

{����������������������������������������������������������������������������}

		function XMSGetVersion: word; assembler;
			asm
				mov    ah, 00h
				call   XMSDriver
			end;

{����������������������������������������������������������������������������}

		function XMSGetFreeMem: word; assembler;
			asm
				mov    ah, 08h
				call   XMSDriver
				mov    ax, dx
			end;

{����������������������������������������������������������������������������}

		function XMSAllocate(var Handle: word; Size: word): boolean; assembler;
			asm
				mov    ah, 09h
				mov    dx, Size
				call   XMSDriver
				les    di, Handle
				mov    es:[di], dx
			end;

{����������������������������������������������������������������������������}

		function XMSReallocate(Handle: word; NewSize: word): boolean; assembler;
			asm
				mov    ah, 0Fh
				mov    bx, NewSize
				mov    dx, Handle
				call   XMSDriver
			end;

{����������������������������������������������������������������������������}

		function XMSFree(Handle: word): boolean; assembler;
			asm
				mov    ah, 0Ah
				mov    dx, Handle
				call   XMSDriver
			end;

{����������������������������������������������������������������������������}
		function XMSMove(Params: PMoveParams): boolean; assembler;
			asm
				push   ds
				mov    ah, 0Bh
				lds    si, Params
				call   XMSDriver
				pop    ds
			end;
	end.  {��������������������������������������������������������������������}