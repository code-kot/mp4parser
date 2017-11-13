unit mp4SampleChunkOffsetTable;

interface

uses
  System.Classes, System.SysUtils,
  mp4StreamHelper;

type
// 1 byte    version
// 3 bytes   flags
// 4 bytes   total entries in offset table (n)
// 4 bytes   chunk offset 0
// 4 bytes   chunk offset 1
//  ..
//  ..
// 4 bytes   chunk offset n-1

  TSampleChunkOffsetTable = record
    Version: Byte;
    Flags: array [0..2] of Byte;
    Count: UInt32;
    ChunckOffset: array of UInt32;
    procedure LoadFromStream(AStream: TStream);
    constructor Create(AStream: TStream);
  end;

// 1 byte    version
// 3 bytes   flags
// 4 bytes   total entries in offset table (n)
// 8 bytes   chunk offset 0
// 8 bytes   chunk offset 1
//  ..
//  ..
// 8 bytes   chunk offset n-1

  TSampleChunkOffsetTable64 = record
    Version: Byte;
    Flags: array [0..2] of Byte;
    Count: UInt32;
    ChunckOffset: array of UInt64;
    procedure LoadFromStream(AStream: TStream);
    constructor Create(AStream: TStream);
  end;

implementation

{ TSampleChunkOffsetTable }

constructor TSampleChunkOffsetTable.Create(AStream: TStream);
begin
  LoadFromStream(AStream);
end;

procedure TSampleChunkOffsetTable.LoadFromStream(AStream: TStream);
var
  i: Integer;
begin
  AStream.CheckStreamDataAvaliable(8); // version + flags + total entries count

  AStream.Read(Version, 1);
  AStream.Read(Flags[0], 3); // 3 bytes flags
  Count := AStream.ReadBigEndianInt;

  AStream.CheckStreamDataAvaliable(Count * 4); // total entries count * 4 bytes per entry

  SetLength(ChunckOffset, Count);
  for i := 0 to Count - 1 do
    ChunckOffset[i] := AStream.ReadBigEndianInt; // 4 bytes chunk offset
end;

{ TSampleChunkOffsetTable64 }

constructor TSampleChunkOffsetTable64.Create(AStream: TStream);
begin
  LoadFromStream(AStream);
end;

procedure TSampleChunkOffsetTable64.LoadFromStream(AStream: TStream);
var
  i: Integer;
begin
  AStream.CheckStreamDataAvaliable(8); // version + flags + total entries count

  AStream.Read(Version, 1);
  AStream.Read(Flags[0], 3); // 3 bytes flags
  Count := AStream.ReadBigEndianInt;

  AStream.CheckStreamDataAvaliable(Count * 8); // total entries count * 8 bytes per entry

  SetLength(ChunckOffset, Count);
  for i := 0 to Count - 1 do
    ChunckOffset[i] := AStream.ReadBigEndianInt64; // 8 bytes chunk offset
end;

end.
