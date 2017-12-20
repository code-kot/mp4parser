unit mp4SampleSizesTable;

interface

uses
  System.Classes, System.SysUtils,
  mp4StreamHelper;

type
// 1 byte    version
// 3 bytes   flags
// 4 bytes   uniform size of each sample
// 4 bytes   total samples count (n)
// 4 bytes   sample 0 size
// 4 bytes   sample 1 size
//  ..
//  ..
// 4 bytes   sample n-1 size

  TChunkOffsetTable = record   // stsz Atom
    Version: Byte;
    Flags: array [0..2] of Byte;
    UniSize: UInt32;
    Count: UInt32;
    SampleSizes: array of UInt32;
    procedure LoadFromStream(AStream: TStream);
    constructor Create(AStream: TStream);
  end;

implementation

{ TChunkOffsetTable }

constructor TChunkOffsetTable.Create(AStream: TStream);
begin
  LoadFromStream(AStream);
end;

procedure TChunkOffsetTable.LoadFromStream(AStream: TStream);
var
  i: Integer;
begin
  AStream.CheckStreamDataAvaliable(12); // version + flags + uniform size + total samples count

  AStream.Read(Version, 1);
  AStream.Read(Flags[0], 3); // 3 bytes flags

  UniSize := AStream.ReadBigEndianInt; // 4 bytes uniform size

  Count := AStream.ReadBigEndianInt;   // 4 bytes total samples count

  AStream.CheckStreamDataAvaliable(Count * 4); // total entries count * 4 bytes per entry

  SetLength(SampleSizes, Count);
  for i := 0 to Count - 1 do
    SampleSizes[i] := AStream.ReadBigEndianInt; // 4 bytes sample size
end;

end.
