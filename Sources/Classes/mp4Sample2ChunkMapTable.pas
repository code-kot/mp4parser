unit mp4Sample2ChunkMapTable;

interface

uses
  System.Classes, System.SysUtils,
  mp4StreamHelper;

type
//  1 byte    version
//  3 bytes   flags
//  4 bytes   total entries count (n)
// 12 bytes   entry 0
// 12 bytes   entry 1
//  ..
//  ..
// 12 bytes   entry n-1

// entry structure:
// 4 bytes    First chunk - The first chunk number using this table entry.
// 4 bytes    Samples per chunk - The number of samples in each chunk.
// 4 bytes    Sample description ID - The ID number associated with the sample description for the sample.

  TSample2ChunkMapTableEntry = packed record
    FirstChunk: UInt32;
    SamplesPerChunk: UInt32;
    DescriptionID: UInt32;
  end;

  TSample2ChunkMapTable = record   // stsc Atom
    Version: Byte;
    Flags: array [0..2] of Byte;
    Count: UInt32;
    Entries: array of TSample2ChunkMapTableEntry;
    procedure LoadFromStream(AStream: TStream);
    constructor Create(AStream: TStream);
  end;

implementation

{ TSample2ChunkMapTable }

constructor TSample2ChunkMapTable.Create(AStream: TStream);
begin
  LoadFromStream(AStream);
end;

procedure TSample2ChunkMapTable.LoadFromStream(AStream: TStream);
var
  i: Integer;
begin
  AStream.CheckStreamDataAvaliable(8); // version + flags + total entries count

  AStream.Read(Version, 1);
  AStream.Read(Flags[0], 3); // 3 bytes flags
  Count := AStream.ReadBigEndianInt;

  AStream.CheckStreamDataAvaliable(Count * SizeOf(TSample2ChunkMapTableEntry)); // total entries count * 12 bytes per entry

  SetLength(Entries, Count);
  for i := 0 to Count - 1 do
  begin
    Entries[i].FirstChunk      := AStream.ReadBigEndianInt;
    Entries[i].SamplesPerChunk := AStream.ReadBigEndianInt;
    Entries[i].DescriptionID   := AStream.ReadBigEndianInt;
  end;
end;

end.
