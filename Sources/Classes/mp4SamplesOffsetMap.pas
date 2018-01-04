unit mp4SamplesOffsetMap;

interface

uses
  System.Generics.Collections, System.Generics.Defaults, System.StrUtils;

type
  TSampleOffsetMapItem = record
    Offset: UInt64;
    DataPreview: UInt64;
    SampleSize: Integer;
    TrackID: string;
    ChunkNumber: Integer;
    SampleNumber: Integer;
    constructor Create(AOffset: UInt64; AData: UInt64; ASize: Integer;
      ATrackID: string; AChunkNumber: Integer; ASampleNumber: Integer);
  end;

  TSampleOffsetMapItemsComparer = class(TComparer<TSampleOffsetMapItem>)
  private
    function CompareByChunkNumber(const Left, Right: TSampleOffsetMapItem): Integer;
    function CompareBySampleNumber(const Left, Right: TSampleOffsetMapItem): Integer;
    function CompareByTrackID(const Left, Right: TSampleOffsetMapItem): Integer;
  public
    function Compare(const Left, Right: TSampleOffsetMapItem): Integer; override;
  end;


implementation

{ TSampleOffsetMapItem }

constructor TSampleOffsetMapItem.Create(AOffset, AData: UInt64; ASize: Integer;
  ATrackID: string; AChunkNumber, ASampleNumber: Integer);
begin
  Offset := AOffset;
  DataPreview := AData;
  SampleSize := ASize;
  TrackID := ATrackID;
  ChunkNumber := AChunkNumber;
  SampleNumber := ASampleNumber;
end;

{ TSampleOffsetMapItemsComparer }

function TSampleOffsetMapItemsComparer.Compare(const Left,
  Right: TSampleOffsetMapItem): Integer;
begin
  if (Left.Offset = 0) or (Right.Offset = 0) then
    Result := CompareByChunkNumber(Left, Right)
  else
  begin
    if Left.Offset < Right.Offset then
      Result := -1
    else if Left.Offset > Right.Offset then
      Result := 1
    else
      Result := CompareByChunkNumber(Left, Right);
  end;
end;

function TSampleOffsetMapItemsComparer.CompareByChunkNumber(const Left,
  Right: TSampleOffsetMapItem): Integer;
begin
  if Left.ChunkNumber < Right.ChunkNumber then
    Result := -1
  else if Left.ChunkNumber > Right.ChunkNumber then
    Result := 1
  else
    Result := CompareBySampleNumber(Left, Right);
end;

function TSampleOffsetMapItemsComparer.CompareBySampleNumber(const Left,
  Right: TSampleOffsetMapItem): Integer;
begin
  if Left.SampleNumber < Right.SampleNumber then
    Result := -1
  else if Left.SampleNumber > Right.SampleNumber then
    Result := 1
  else
    Result := CompareByTrackID(Left, Right);
end;

function TSampleOffsetMapItemsComparer.CompareByTrackID(const Left,
  Right: TSampleOffsetMapItem): Integer;
begin
  if Left.TrackID < Right.TrackID then
    Result := -1
  else if Left.TrackID > Right.TrackID then
    Result := 1
  else
    Result := 0;
end;

end.
