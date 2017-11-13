unit mp4StreamHelper;

interface

uses
  System.Classes;

type
  TStreamHelper = class helper for TStream
  private
    procedure DoReadBigEndianInt(PBuffer: PByte; Size: Integer);
    function DoWriteBigEndianInt(PBuffer: PByte; Size: Integer): Integer; // return Bytes written
  public
    function ReadBigEndianInt: UInt32;
    function WriteBigEndianInt(AValue: UInt32): Integer; // return Bytes written
    function ReadBigEndianInt64: UInt64;
    function WriteBigEndianInt64(AValue: UInt64): Integer; // return Bytes written

    procedure CheckStreamDataAvaliable(DataSize: Int64);
  end;

implementation

resourcestring
  NO_DATA_TO_READ = 'No data to read!';

{ TStreamHelper }

procedure TStreamHelper.CheckStreamDataAvaliable(DataSize: Int64);
begin
  if Size - Position < DataSize then
    raise EReadError.Create(NO_DATA_TO_READ);
end;

procedure TStreamHelper.DoReadBigEndianInt(PBuffer: PByte; Size: Integer);
var
  NextByte: PByte;
begin
  NextByte := PBuffer + Size;
  while NextByte > PBuffer do
  begin
    Dec(NextByte);
    Read(NextByte^, 1);
  end;
end;

function TStreamHelper.DoWriteBigEndianInt(PBuffer: PByte;
  Size: Integer): Integer;
var
  NextByte: PByte;
begin
  Result := 0;
  NextByte := PBuffer + Size;
  while NextByte > PBuffer do
  begin
    Dec(NextByte);
    Inc(Result, Write(NextByte^, 1));
  end;
end;

function TStreamHelper.ReadBigEndianInt: UInt32;
begin
  DoReadBigEndianInt(@Result, SizeOf(Result));
end;

function TStreamHelper.ReadBigEndianInt64: UInt64;
begin
  DoReadBigEndianInt(@Result, SizeOf(Result));
end;

function TStreamHelper.WriteBigEndianInt(AValue: UInt32): Integer;
begin
  Result := DoWriteBigEndianInt(@AValue, SizeOf(AValue));
end;

function TStreamHelper.WriteBigEndianInt64(AValue: UInt64): Integer;
begin
  Result := DoWriteBigEndianInt(@AValue, SizeOf(AValue));
end;

end.
