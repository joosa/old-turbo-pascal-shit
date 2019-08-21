{       SMIX is Copyright 1995 by Ethan Brodsky.  All rights reserved.       }

unit SMix; {Version 1.27}
 {$X+} {$G+} {$R-}
  interface
    const
      BlockLength   = 512;      {Size of digitized sound block               }
      LoadChunkSize = 2048;     {Chunk size used for loading sounds from disk}
      Voices        = 8;        {Number of available voices                  }
			SamplingRate  = 22025;    {Sampling rate for output                    }
		type
			PSound = ^TSound;
			TSound =
				record
					XMSHandle: word;
					StartOfs:  LongInt;
					SoundSize: LongInt;
				end;
		function InitSB(BaseIO: word; IRQ: byte; DMA, DMA16: byte): boolean;
			{Initializes control parameters, resets DSP, and installs int. handler }
			{ Parameters: (Can be found using GetSettings procedure in Detect)     }
			{  BaseIO:   Sound card base IO address                                }
			{  IRQ:      Sound card IRQ setting                                    }
			{  DMA:      Sound card 8-bit DMA channel                              }
			{  DMA16:    Sound card 16-bit DMA channel (0 if not supported)        }
			{ Returns:                                                             }
			{  TRUE:     Sound card successfully initialized (Maybe)               }
			{  FALSE:    Sound card could not be initialized                       }
		procedure ShutdownSB;
			{Removes interrupt handler and resets DSP                              }

		procedure InitMixing;
			{Allocates internal buffers and starts digitized sound output          }
		procedure ShutdownMixing;
			{Deallocates internal buffers and stops digitized sound output         }

		function  InitXMS: boolean;
			{Attempts to intialize extended memory                                 }
			{ Returns:                                                             }
			{  TRUE:     Extended memory successfully initialized                  }
			{  FALSE:    Extended memory could not be initialized                  }
		function  GetFreeXMS: word;
			{Returns amount of free XMS memory (In kilobytes)                      }

		procedure InitSharing;
			{Allocates an EMB that all sounds are stored in.  This preserves EMB   }
			{handles, which are a scarce resource.  Call this on initialization and}
			{all sounds will automatically be stored in one EMB.  Call LoadSound as}
			{usual to allocate a sound, but FreeSound only deallocates the sound   }
			{data structure.  Call ShutdownSharing before program termination to   }
			{free allocated extended memory.                                       }
		procedure ShutdownSharing;
			{Shuts down EMB sharing and frees all allocated extended memory        }

		procedure OpenSoundResourceFile(FileName: string);
			{Call this to open a resource file for loading sounds.  After this has }
			{been called, the Key parameter in the LoadSound function is used as a }
			{resource key to locate the sound data in this file.                   }
			{ Parameters:                                                          }
			{  FileName: File name of resource file                                }
		procedure CloseSoundResourceFile;
			{Close sound resource file.  If you have called this, the Key parameter}
			{will act as a filename instead of a resource key.                     }

		procedure LoadSound(var Sound: PSound; Key: string);
			{Allocates an extended memory block and loads a sound from a file      }
			{ Parameters:                                                          }
			{  Sound:    Unallocated pointer to sound data structure               }
			{  Key:      If a resource file has been opened then key is a resource }
			{            identifier.  Use the same ID as you used for SNDLIB.      }
			{            If a resource file has not been opened, then key is the   }
			{            filename to load the sound data from.                     }
		procedure FreeSound(var Sound: PSound);
			{Deallocates extended memory and destroys sound data structure         }
			{ Parameters:                                                          }
			{  Sound:    Unallocated pointer to sound data structure               }

		procedure StartSound(Sound: PSound; Index: byte; Loop: boolean);
			{Starts playing a sound                                                }
			{ Parameters:                                                          }
			{  Sound:    Pointer to sound data structure                           }
			{  Index:    A number to keep track of the sound with (Used to stop it)}
			{  Loop:     Indicates whether the sound should be continuously looped }
		procedure StopSound(Index: byte);
			{Stops playing sound                                                   }
			{ Parameters:                                                          }
			{  Index:    Index of sound to stop (All with given index are stopped) }
		function SoundPlaying(Index: byte): boolean;
			{Checks if a sound is still playing                                    }
			{ Parameters:                                                          }
			{  Index:    Index used when the sound was started                     }
			{ Returns:                                                             }
			{  TRUE      At least oen sound with the specified index is playing    }
			{  FALSE     No sounds with the specified index are playing            }

		var
			IntCount   : LongInt;  {Number of sound interrupts that have occured   }
			DSPVersion : real;     {Contains the version of the installed DSP chip }
			AutoInit   : boolean;  {Tells Auto-initialized DMA transfers are in use}
			SixteenBit : boolean;  {Tells whether 16-bit sound output is occuring  }
			VoiceCount : byte;     {Number of voices currently in use              }

	implementation
		uses
			CRT,
			DOS,
			XMS;
		const
			BufferLength = BlockLength * 2;
		var
			ResetPort        : word;
			ReadPort         : word;
			WritePort        : word;
			PollPort         : word;
			AckPort          : word;

			PICRotatePort    : word;
			PICMaskPort      : word;

			DMAMaskPort      : word;
			DMAClrPtrPort    : word;
			DMAModePort      : word;
			DMABaseAddrPort  : word;
			DMACountPort     : word;
			DMAPagePort      : word;

			IRQStartMask     : byte;
			IRQStopMask      : byte;
			IRQIntVector     : byte;

			DMAStartMask     : byte;
			DMAStopMask      : byte;
			DMAMode          : byte;
			DMALength        : word;

			OldIntVector     : pointer;
			OldExitProc      : pointer;

			HandlerInstalled : boolean;

		procedure WriteDSP(Value: byte);
			begin
				repeat until (Port[WritePort] and $80) = 0;
				Port[WritePort] := Value;
			end;

		function ReadDSP: byte;
			begin
				repeat until (Port[PollPort] and $80) <> 0;
				ReadDSP := Port[ReadPort];
			end;

		function ResetDSP: boolean;
			var
				i: byte;
			begin
				Port[ResetPort] := 1;
				Delay(1);                              {One millisecond}
				Port[ResetPort] := 0;
				i := 100;
				while (ReadDSP <> $AA) and (i > 0) do Dec(i);
				if i > 0
					then ResetDSP := true
					else ResetDSP := false;
			end;

		procedure InstallHandler; forward;
		procedure UninstallHandler; forward;

		procedure MixExitProc; far; forward;

		function InitSB(BaseIO: word; IRQ: byte; DMA, DMA16: byte): boolean;
			begin
			 {Sound card IO ports}
				ResetPort  := BaseIO + $6;
				ReadPort   := BaseIO + $A;
				WritePort  := BaseIO + $C;
				PollPort   := BaseIO + $E;

			 {Reset DSP, get version, and pick output mode}
				if not(ResetDSP)
					then
						begin
							InitSB := false;
							Exit;
						end;
				WriteDSP($E1);  {Get DSP version number}
				DSPVersion := ReadDSP;  DSPVersion := DSPVersion + ReadDSP/100;
				AutoInit := DSPVersion > 2.0;
				SixteenBit := (DSPVersion > 4.0) and (DMA16 <> $FF) and (DMA16 > 3);

			 {Compute interrupt ports and parameters}
				if IRQ <= 7
					then
						begin
							IRQIntVector  := $08+IRQ;
							PICMaskPort   := $21;
						end
					else
						begin
							IRQIntVector  := $70+IRQ-8;
							PICMaskPort   := $A1;
						end;
				IRQStopMask  := 1 shl (IRQ mod 8);
				IRQStartMask := not(IRQStopMask);

			 {Compute DMA ports and parameters}
				if SixteenBit
					then {Sixteen bit}
						begin
							DMAMaskPort     := $D4;
							DMAClrPtrPort   := $D8;
							DMAModePort     := $D6;
							DMABaseAddrPort := $C0 + 4*(DMA16-4);
							DMACountPort    := $C2 + 4*(DMA16-4);
							case DMA16
								of
									5:  DMAPagePort := $8B;
									6:  DMAPagePort := $89;
									7:  DMAPagePort := $8A;
								end;
							DMAStopMask  := DMA16-4 + $04;   {000001xx}
							DMAStartMask := DMA16-4 + $00;   {000000xx}
							DMAMode      := DMA16-4 + $58;   {010110xx}
							AckPort := BaseIO + $F;
						end
					else {Eight bit}
						begin
							DMAMaskPort     := $0A;
							DMAClrPtrPort   := $0C;
							DMAModePort     := $0B;
							DMABaseAddrPort := $00 + 2*DMA;
							DMACountPort    := $01 + 2*DMA;
							case DMA
								of
									0:  DMAPagePort := $87;
									1:  DMAPagePort := $83;
									2:  DMAPagePort := $81;
									3:  DMAPagePort := $82;
								end;
							DMAStopMask  := DMA + $04;       {000001xx}
							DMAStartMask := DMA + $00;       {000000xx}
							if AutoInit
								then DMAMode := DMA + $58      {010110xx}
								else DMAMode := DMA + $48;     {010010xx}
							AckPort := BaseIO + $E;
						end;
					if AutoInit
						then DMALength := BufferLength
						else DMALength := BlockLength;
					InstallHandler;

					OldExitProc := ExitProc;
					ExitProc    := @MixExitProc;
					InitSB := true;
			end;

		procedure ShutdownSB;
			begin
				if HandlerInstalled
					then UninstallHandler;
				ResetDSP;
			end;

		function InitXMS: boolean;
			begin
				InitXMS := true;
				if not(XMSInstalled)
					then InitXMS := false
					else XMSInit;
			end;
		function GetFreeXMS: word;
			begin
				GetFreeXMS := XMSGetFreeMem;
			end;

	 {Voice control}
		type
			PVoice = ^TVoice;
			TVoice =
				record
					Sound:     PSound;
					Index:     byte;
					CurPos:    LongInt;
					Loop:      boolean;
				end;
		var
			VoiceInUse: array[0..Voices-1] of boolean;
			Voice:      array[0..Voices-1] of TVoice;
			CurBlock:   byte;
	 {Sound buffer}
		var
			SoundBlock: array[1..BlockLength+1] of ShortInt;
				{The length of XMS copies under HIMEM.SYS must be a mutiple  }
				{of two.  If the sound data ends in mid-block, it may not be }
				{possible to round up without corrupting memory.  Therefore, }
				{the copy buffer has been extended by one byte to eliminate  }
				{this problem.                                               }

	 {Mixing buffers}
		type
			PMixingBlock = ^TMixingBlock;
			TMixingBlock = array[1..BlockLength] of integer;
		var
			MixingBlock  : TMixingBlock;

	 {Output buffers}
		type {8-bit}
			POut8Block   = ^TOut8Block;
			TOut8Block   = array[1..BlockLength] of byte;
			POut8Buffer  = ^TOut8Buffer;
			TOut8Buffer  = array[1..2] of TOut8Block;
		type {16-bit}
			POut16Block  = ^TOut16Block;
			TOut16Block  = array[1..BlockLength] of integer;
			POut16Buffer = ^TOut16Buffer;
			TOut16Buffer = array[1..2] of TOut16Block;
		var
			OutMemArea  : pointer;
			Out8Buffer  : POut8Buffer;
			Out16Buffer : POut16Buffer;
		var
			BlockPtr    : array[1..2] of pointer;
			CurBlockPtr : pointer;
		var
		 {For auto-initialized transfers (Whole buffer)}
			BufferAddr : LongInt;
			BufferPage : byte;
			BufferOfs  : word;
		 {For single-cycle transfers (One block at a time)}
			BlockAddr  : array[1..2] of LongInt;
			BlockPage  : array[1..2] of byte;
			BlockOfs   : array[1..2] of word;

	 {Clipping for 8-bit output}
		var
			 Clip8 : array[-128*Voices..128*Voices] of byte;

		function TimeConstant(Rate: word): byte;
			begin
				TimeConstant := 256 - (1000000 div Rate);
			end;

		procedure StartDAC;
			begin
				Port[DMAMaskPort]     := DMAStopMask;
				Port[DMAClrPtrPort]   := $00;
				Port[DMAModePort]     := DMAMode;
				Port[DMABaseAddrPort] := Lo(BufferOfs);
				Port[DMABaseAddrPort] := Hi(BufferOfs);
				Port[DMACountPort]    := Lo(DMALength-1);
				Port[DMACountPort]    := Hi(DMALength-1);
				Port[DMAPagePort]     := BufferPage;
				Port[DMAMaskPort]     := DMAStartMask;

				if SixteenBit
					then {Sixteen bit: SB16 and up (DSP 4.xx)}
						begin
							WriteDSP($41);        {Set digitized sound output sampling rate}
							WriteDSP(Hi(SamplingRate));
							WriteDSP(Lo(SamplingRate));
							WriteDSP($B6);        {16-bit DMA command: D/A, Auto-Init, FIFO}
							WriteDSP($10);        {16-bit DMA mode:    Signed Mono         }
							WriteDSP(Lo(BlockLength - 1));
							WriteDSP(Hi(BlockLength - 1));
						end
					else {Eight bit}
						begin
							WriteDSP($D1);        {Turn on speaker                         }
							WriteDSP($40);        {Set digitized sound time constant       }
							WriteDSP(TimeConstant(SamplingRate));
							if AutoInit
								then {Eight bit auto-initialized: SBPro and up (DSP 2.00+)}
									begin
										WriteDSP($48);  {Set DSP block transfer size             }
										WriteDSP(Lo(BlockLength - 1));
										WriteDSP(Hi(BlockLength - 1));
										WriteDSP($1C);  {8-bit auto-init DMA mono sound output   }
									end
								else {Eight bit single-cycle: Sound Blaster (DSP 1.xx+)}
									begin
										WriteDSP($14);  {8-bit single-cycle DMA sound output     }
										WriteDSP(Lo(BlockLength - 1));
										WriteDSP(Hi(BlockLength - 1));
									end;
						end;
			end;

		procedure StopDAC;
			begin
				if SixteenBit
					then {Sixteen bit}
						begin
							WriteDSP($D5);        {Pause 16-bit DMA sound I/O              }
						end
					else {Eight bit}
						begin
							WriteDSP($D0);        {Pause 8-bit DMA mode sound I/O          }
							WriteDSP($D3);        {Turn off speaker                        }
						end;
				Port[DMAMaskPort] := DMAStopMask;
			end;

	 {Setup for storing all sounds in one extended memory block (Saves handles)}
		var
			SharedEMB    : boolean;
			SharedHandle : word;
			SharedSize   : LongInt;
		procedure InitSharing;
			begin
				SharedEMB  := true;
				SharedSize := 0;
				XMSAllocate(SharedHandle, SharedSize);
			end;
		procedure ShutdownSharing;
			begin
				if SharedEMB then XMSFree(SharedHandle);
				SharedEMB := false;
			end;

	 {Setup for sound resource files}
		var
			ResourceFile     : boolean;
			ResourceFilename : string;

		procedure OpenSoundResourceFile(FileName: string);
			begin
				ResourceFile     := true;
				ResourceFilename := FileName;
			end;

		procedure CloseSoundResourceFile;
			begin
				ResourceFile     := false;
				ResourceFilename := '';
			end;

		type
			TKey = array[1..8] of char;

		var
			SoundFile : file;
			SoundSize : LongInt;

		function MatchingKeys(a, b: TKey): boolean;
			var
				i: integer;
			begin
				MatchingKeys := true;

				for i := 1 to 8 do
					if a <> b
						then
							MatchingKeys := false;
			end;

		procedure GetSoundFile(Key: string);
			type
				Resource =
					record
						Key:   TKey;
						Start: LongInt;
						Size:  LongInt;
					end;
			var
				NumSounds: integer;
				ResKey:    TKey;
				ResHeader: Resource;
				Index:     integer;
				i:         integer;
				Found:     boolean;
			begin
				if ResourceFile
					then
						begin
							for i := 1 to 8 do
								if i <= Length(Key)
									then ResKey[i] := Key[i]
									else ResKey[i] := #0;

							Assign(SoundFile, ResourceFilename);  Reset(SoundFile, 1);
							BlockRead(SoundFile, NumSounds, SizeOf(NumSounds));

							Found := false;
							Index := 0;

							while not(Found) and (Index < NumSounds) do
								begin
									Index := Index + 1;
									BlockRead(SoundFile, ResHeader, SizeOf(ResHeader));

									if MatchingKeys(ResHeader.Key, ResKey)
										then
											Found := true;
								end;

							if Found
								then
									begin
										Seek(SoundFile, ResHeader.Start);
										SoundSize := ResHeader.Size;
									end
								else
									Halt(255);
						end
					else
						begin
							Assign(SoundFile, Key);  Reset(SoundFile, 1);
							SoundSize := FileSize(SoundFile);
						end;
			end;

		function Min(a, b: LongInt): LongInt;
			begin
				if a < b
					then Min := a
					else Min := b;
			end;

	 {Loading and freeing sounds}
		var
			MoveParams: TMoveParams; {The XMS driver doesn't like this on the stack}
		procedure LoadSound(var Sound: PSound; Key: string);
			var
				Size: LongInt;
				InBuffer: array[1..LoadChunkSize] of byte;
				Remaining: LongInt;
			begin
				GetSoundFile(Key);

				New(Sound);
				Sound^.SoundSize := SoundSize;

				if not(SharedEMB)
					then
						begin
							Sound^.StartOfs := 0;
							XMSAllocate(Sound^.XMSHandle, (SoundSize + 1023) div 1024);
						end
					else
						begin
							Sound^.StartOfs := SharedSize;
							Sound^.XMSHandle := SharedHandle;
							SharedSize := SharedSize + SoundSize;
							XMSReallocate(SharedHandle, (SharedSize + 1023) div 1024);
						end;
				MoveParams.SourceHandle := 0;
				MoveParams.SourceOffset := LongInt(Addr(InBuffer));
				MoveParams.DestHandle   := Sound^.XMSHandle;
				MoveParams.DestOffset   := Sound^.StartOfs;

				Remaining := Sound^.SoundSize;

				repeat
					MoveParams.Length := Min(Remaining, LoadChunkSize);
					BlockRead(SoundFile, InBuffer, MoveParams.Length);
					MoveParams.Length := ((MoveParams.Length+1) div 2) * 2;
						{XMS copy lengths must be a multiple of two}
					XMSMove(@MoveParams);
					Inc(MoveParams.DestOffset, MoveParams.Length);
					Dec(Remaining, MoveParams.Length);
				until not(Remaining > 0);

				Close(SoundFile);
			end;

		procedure FreeSound(var Sound: PSound);
			begin
				if not(SharedEMB) then XMSFree(Sound^.XMSHandle);
				Dispose(Sound); Sound := nil;
			end;

	 {Voice maintainance}
		procedure DeallocateVoice(VoiceNum: byte);
			begin
				VoiceInUse[VoiceNum] := false;
				with Voice[VoiceNum] do
					begin
						Sound    := nil;
						Index    := 0;
						CurPos   := 0;
						Loop     := false;
					end;
			end;

		procedure StartSound(Sound: PSound; Index: byte; Loop: boolean);
			var
				i, Slot: byte;
			begin
				Slot := $FF; i := 0;
				repeat
					if not(VoiceInUse[i])
						then Slot := i;
					Inc(i);
				until ((Slot <> $FF) or (i=Voices));
				if Slot <> $FF
					then
						begin
							Inc(VoiceCount);
							Voice[Slot].Sound    := Sound;
							Voice[Slot].Index    := Index;
							Voice[Slot].CurPos   := 0;
							Voice[Slot].Loop     := Loop;

							VoiceInUse[Slot] := true;
						end;
			end;

		procedure StopSound(Index: byte);
			var
				i: byte;
			begin
				for i := 0 to Voices-1 do
					if Voice[i].Index = Index
						then
							begin
								DeallocateVoice(i);
								Dec(VoiceCount);
							end;
			end;

		function SoundPlaying(Index: byte): boolean;
			var
				i: byte;
			begin
				SoundPlaying := False;

				for i := 0 to Voices-1 do
					if Voice[i].Index = Index
						then SoundPlaying := True;
			end;

		procedure UpdateVoices;
			var
				VoiceNum: byte;
			begin
				for VoiceNum := 0 to Voices-1 do
					begin
						if VoiceInUse[VoiceNum]
							then
								if Voice[VoiceNum].CurPos >= Voice[VoiceNum].Sound^.SoundSize
									then
										begin
											DeallocateVoice(VoiceNum);
											Dec(VoiceCount);
										end;
					end;
			end;


	 {Utility functions}
		procedure SetCurBlock(BlockNum: byte);
			begin
				CurBlock := BlockNum;
				CurBlockPtr := pointer(BlockPtr[BlockNum]);
			end;

		procedure ToggleBlock;
			begin
				if CurBlock = 1
					then SetCurBlock(2)
					else SetCurBlock(1);
			end;

		procedure SilenceBlock;
			begin
				FillChar(MixingBlock, BlockLength*2, 0);  {FillChar uses REP STOSW}
			end;

		function GetLinearAddr(Ptr: pointer): LongInt;
			begin
				GetLinearAddr := LongInt(Seg(Ptr^))*16 + LongInt(Ofs(Ptr^));
			end;

		function NormalizePtr(p: pointer): pointer;
			var
				LinearAddr: LongInt;
			begin
				LinearAddr := GetLinearAddr(p);
				NormalizePtr := Ptr(LinearAddr div 16, LinearAddr mod 16);
			end;


		procedure InitClip8;
			var
				i, Value: integer;
			begin
				for i := -128*Voices to 128*Voices do
					begin
						Value := i;
						if (Value < -128) then Value := -128;
						if (Value > +127) then Value := +127;

						Clip8[i] := Value + 128;
					end;
			end;

		procedure InitMixing;
			var
				i: integer;
			begin
				for i := 0 to Voices-1 do DeallocateVoice(i);
				VoiceCount := 0;

				if SixteenBit
					then
						begin
						 {Find a block of memory that does not cross a page boundary}
							GetMem(OutMemArea, 4*BufferLength);
							if ((GetLinearAddr(OutMemArea) div 2) mod 65536)+BufferLength < 65536
								then Out16Buffer := OutMemArea
								else Out16Buffer := NormalizePtr(Ptr(Seg(OutMemArea^), Ofs(OutMemArea^)+2*BufferLength));
							for i := 1 to 2 do
								BlockPtr[i] := NormalizePtr(Addr(Out16Buffer^[i]));
						 {DMA parameters}
							BufferAddr := GetLinearAddr(pointer(Out16Buffer));
							BufferPage := BufferAddr div 65536;
							BufferOfs  := (BufferAddr div 2) mod 65536;
							for i := 1 to 2 do
								BlockAddr[i] := GetLinearAddr(pointer(BlockPtr[i]));
							for i := 1 to 2 do
								BlockPage[i] := BlockAddr[i] div 65536;
							for i := 1 to 2 do
								BlockOfs[i]  := (BlockAddr[i] div 2) mod 65536;
							FillChar(Out16Buffer^, BufferLength*2, $00);   {Signed   16-bit}
						end
					else
						begin
						 {Find a block of memory that does not cross a page boundary}
							GetMem(OutMemArea, 2*BufferLength);
							if (GetLinearAddr(OutMemArea) mod 65536)+BufferLength < 65536
								then Out8Buffer := OutMemArea
								else Out8Buffer := NormalizePtr(Ptr(Seg(OutMemArea^), Ofs(OutMemArea^)+BufferLength));
							for i := 1 to 2 do
								BlockPtr[i] := NormalizePtr(Addr(Out8Buffer^[i]));
						 {DMA parameters}
							BufferAddr := GetLinearAddr(pointer(Out8Buffer));
							BufferPage := BufferAddr div 65536;
							BufferOfs  := BufferAddr mod 65536;
							for i := 1 to 2 do
								BlockAddr[i] := GetLinearAddr(pointer(BlockPtr[i]));
							for i := 1 to 2 do
								BlockPage[i] := BlockAddr[i] div 65536;
							for i := 1 to 2 do
								BlockOfs[i]  := BlockAddr[i] mod 65536;
							FillChar(Out8Buffer^, BufferLength, $80);      {Unsigned  8-bit}

							InitClip8;
						end;

				FillChar(MixingBlock, BlockLength*2, $00);

				SetCurBlock(1);
				IntCount := 0;
				StartDAC;
			end;

		procedure ShutdownMixing;
			begin
				StopDAC;

				if SixteenBit
					then FreeMem(OutMemArea, 4*BufferLength)
					else FreeMem(OutMemArea, 2*BufferLength);
			end;



		var {The XMS driver doesn't like parameter blocks in the stack}
			IntMoveParams: TMoveParams;  {In case LoadSound is interrupted}
		procedure CopySound(Sound: PSound; var CurPos: LongInt; CopyLength: word; Loop: boolean);
			var
				SoundSize: LongInt;
				DestPtr: pointer;
			begin
				SoundSize := Sound^.SoundSize;
				DestPtr := pointer(@SoundBlock);
				IntMoveParams.SourceHandle := Sound^.XMSHandle;
				IntMoveParams.DestHandle   := 0;
				while CopyLength > 0 do
					begin
					 {Compute max transfer size}
						if CopyLength < SoundSize-CurPos
							then IntMoveParams.Length := CopyLength
							else IntMoveParams.Length := SoundSize-CurPos;

					 {Compute starting dest. offset and update offset for next block}
						IntMoveParams.SourceOffset := Sound^.StartOfs + CurPos;
						CurPos := CurPos + IntMoveParams.Length;
						if Loop then CurPos := CurPos mod SoundSize;

					 {Compute starting source offset and update offset for next block}
						IntMoveParams.DestOffset := LongInt(DestPtr);
						DestPtr := NormalizePtr(Ptr(Seg(DestPtr^), Ofs(DestPtr^)+IntMoveParams.Length));

					 {Update remaining count for next iteration}
						CopyLength := CopyLength - IntMoveParams.Length;

					 {Move block}
						IntMoveParams.Length := ((IntMoveParams.Length+1) div 2) * 2;
							{XMS copy lengths must be a multiple of two}
						XMSMove(@IntMoveParams);  {Luckily, the XMS driver is re-entrant}
					end;
			end;

		procedure MixVoice(VoiceNum: byte);
			var
				MixLength: word;
			begin
				with Voice[VoiceNum] do
					if Loop
						then
							MixLength := BlockLength
						else
							if BlockLength < Sound^.SoundSize-CurPos
								then MixLength := BlockLength
								else MixLength := Sound^.SoundSize-CurPos;
				CopySound(Voice[VoiceNum].Sound, Voice[VoiceNum].CurPos, MixLength, Voice[VoiceNum].Loop);
				asm
					lea  si, SoundBlock         {DS:SI -> Sound data (Source)          }
					mov  ax, ds                 {ES:DI -> Mixing block (Destination)   }
					mov  es, ax
					lea  di, MixingBlock
					mov  cx, MixLength          {CX = Number of samples to copy        }

				 @MixSample:
					mov  al, [si]               {Load a sample from the sound block    }
					inc  si                     { increment pointer                    }
					cbw                         {Convert it to a 16-bit signed sample  }
					add  es:[di], ax            {Add it into the mixing buffer         }
					add  di, 2                  {Next word in mixing buffer            }
					dec  cx                     {Loop for next sample                  }
					jnz  @MixSample
				end;
			end;

		procedure MixVoices;
			var
				i: word;
			begin
				SilenceBlock;
				for i := 0 to Voices-1 do
					if VoiceInUse[i]
						then
							MixVoice(i);
			end;

		procedure CopyData16; assembler;
			asm
				lea   si, MixingBlock         {DS:SI -> 16-bit input block           }
				les   di, [CurBlockPtr]       {ES:DI -> 16-bit output block          }
				mov   cx, BlockLength         {CX = Number of samples to copy        }

			 @CopySample:
				mov   ax, [si]                {Load a sample from the mixing block   }
				add   di, 2                   {Increment destination pointer         }
				sal   ax, 5                   {Shift sample left to fill 16-bit range}
				add   si, 2                   {Increment source pointer              }
				mov   es:[di-2], ax           {Store sample in output block          }
				dec   cx                      {Process the next sample               }
				jnz   @CopySample
			end;

		procedure CopyData8; assembler;
			asm
				push  bp
				mov   dx, ss                  {Preserve SS in DX                     }
				pushf
				cli                           {Disable interrupts                    }
				mov   ax, ds                  {Using SS for data                     }
				mov   ss, ax

				lea   si, Clip8               {DS:SI -> 8-bit clipping buffer        }
				add   si, 128*Voices          {DS:SI -> Center of clipping buffer    }

				lea   bp, MixingBlock         {SS:BP -> 16-bit input block           }
				les   di, [CurBlockPtr]       {ES:DI -> 8-bit output block           }
				mov   cx, BlockLength         {CX = Number of samples to copy        }

			 @CopySample:
				mov   bx, [bp]                {BX = Sample from mixing block         }
				inc   di                      {Increment destination pointer (DI)    }
				add   bp, 2                   {Increment source pointer (BP)         }
				mov   al, [si+bx]             {AL = Clipped sample                   }
				mov   es:[di-1], al           {Store sample in output block          }
				dec   cx                      {Process the next sample               }
				jnz   @CopySample

				mov   ss, dx                  {Restore SS                            }
				popf                          {Restore flags                         }
				pop   bp
			end;

		procedure CopyData;
			begin
				if SixteenBit
					then CopyData16
					else CopyData8;
			end;

		procedure StartBlock_SC; {Starts a single-cycle DMA transfer}
			begin
				Port[DMAMaskPort]     := DMAStopMask;
				Port[DMAClrPtrPort]   := $00;
				Port[DMAModePort]     := DMAMode;
				Port[DMABaseAddrPort] := Lo(BlockOfs[CurBlock]);
				Port[DMABaseAddrPort] := Hi(BlockOfs[CurBlock]);
				Port[DMACountPort]    := Lo(DMALength-1);
				Port[DMACountPort]    := Hi(DMALength-1);
				Port[DMAPagePort]     := BlockPage[CurBlock];
				Port[DMAMaskPort]     := DMAStartMask;
				WriteDSP($14);                {8-bit single-cycle DMA sound output   }
				WriteDSP(Lo(BlockLength - 1));
				WriteDSP(Hi(BlockLength - 1));
			end;

		var Save_Test8086: byte; {CPU type flag}

		procedure IntHandler; interrupt;
			var
				Temp: byte;
			begin
			 {On a 386 or higher, Turbo Pascal uses 32-bit registers for LongInt   }
			 {math.  Unfortunately, it doesn't preserve these registers when       }
			 {generating code to handle interrupts, so they are occasionally       }
			 {corrupted.  This can cause a problem with LongInt math in your       }
			 {program or in TSRs. The below code disables 32-bit instructions for  }
			 {the interrupt to prevent 32-bit register corruption.                 }
				Save_Test8086 := Test8086;
				Test8086 := 0;

				Inc(IntCount);

				if not(AutoInit) {Start next block first if not using auto-init DMA}
					then
						begin
							StartBlock_SC;
							CopyData;
							ToggleBlock;
						end;

				UpdateVoices;
				MixVoices;

				if (AutoInit)
					then
						begin
							CopyData;
							ToggleBlock;
						end;

				Test8086 := Save_Test8086;

				Temp := Port[AckPort];
				Port[$A0] := $20;
				Port[$20] := $20;
			end;

		procedure EnableInterrupts;  InLine($FB); {STI}
		procedure DisableInterrupts; InLine($FA); {CLI}

		procedure InstallHandler;
			begin
				DisableInterrupts;
				Port[PICMaskPort] := Port[PICMaskPort] or IRQStopMask;
				GetIntVec(IRQIntVector, OldIntVector);
				SetIntVec(IRQIntVector, @IntHandler);
				Port[PICMaskPort] := Port[PICMaskPort] and IRQStartMask;
				EnableInterrupts;
				HandlerInstalled := true;
			end;

		procedure UninstallHandler;
			begin
				DisableInterrupts;
				Port[PICMaskPort] := Port[PICMaskPort] or IRQStopMask;
				SetIntVec(IRQIntVector, OldIntVector);
				EnableInterrupts;
				HandlerInstalled := false;
			end;

		procedure MixExitProc;       {Called automatically on program termination}
			begin
				ExitProc := OldExitProc;

				StopDAC;
				ShutdownSB;
			end;

	begin
		HandlerInstalled := false;
		SharedEMB        := false;
		ResourceFile     := false;
	end.
