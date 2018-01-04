unit mp4Container;

interface

uses
  System.Classes, System.SysUtils,
  System.Generics.Collections,
  mp4Atoms, mp4AtomFactory, mp4SamplesOffsetMap, mp4StreamHelper;

type
  TMP4Container = class(TObject)
  private
    FFileStream: TFileStream;
    FAllAtoms: TAtomsList;
    function GetFileLoaded: Boolean;
  public
    constructor Create;
    destructor Destroy; override;

    property FileLoaded: Boolean read GetFileLoaded;
    property AllAtoms: TAtomsList read FAllAtoms;

    procedure Clear;
    procedure LoadFromFile(const FileName: string);

    procedure LoadAtomData(Atom: TCustomAtom);
    procedure LoadAtomChild(Atom: TCustomAtom);
    procedure ExportAtomData(Atom: TCustomAtom; const FileName: string);
    procedure ExportAtom(Atom: TCustomAtom; const FileName: string);

    procedure GenerateSamplesOffsetMap(const FileName: string);
  end;

implementation

{ TMP4Container }

procedure TMP4Container.Clear;
begin
  FreeAndNil(FFileStream);

  FAllAtoms.Clear;
end;

constructor TMP4Container.Create;
begin
  inherited Create;

  FAllAtoms := TAtomsList.Create;
end;

destructor TMP4Container.Destroy;
begin
  FFileStream.Free;
  FAllAtoms.Free;

  inherited Destroy;
end;

procedure TMP4Container.ExportAtom(Atom: TCustomAtom; const FileName: string);
var
  ExportFileStream: TFileStream;
begin
  ExportFileStream := TFileStream.Create(FileName, fmCreate or fmShareDenyWrite);
  try
    Atom.SaveAtom(FFileStream, ExportFileStream);
  finally
    ExportFileStream.Free;
  end;
end;

procedure TMP4Container.ExportAtomData(Atom: TCustomAtom; const FileName: string);
var
  ExportFileStream: TFileStream;
begin
  ExportFileStream := TFileStream.Create(FileName, fmCreate or fmShareDenyWrite);
  try
    Atom.CopyData(FFileStream, ExportFileStream);
  finally
    ExportFileStream.Free;
  end;
end;

procedure TMP4Container.GenerateSamplesOffsetMap(const FileName: string);
var
//  MoovAtom: TCustomAtom;
  CustomAtom: TCustomAtom;
  hdlrAtom: ThdlrAtom;
  AllTrakAtoms: TList<TCustomAtom>;
  trakAtom: TCustomAtom;
  i: Integer;
  stblAtom: TstblAtom;
  stcoAtom: TstcoAtom;
  stscAtom: TstscAtom;
  stszAtom: TstszAtom;
  Sample2ChunkMapIndex: Cardinal;
  SampleSizeTableIndex: Cardinal;
  j: Integer;
  SampleOffsetMap: TList<TSampleOffsetMapItem>;
  NextSampleOffset: UInt64;
  TrackID: string;
begin
  // stco - Chunks offset
  // stsc - Sample to chunk map
  // stsz - Sample size table
  CustomAtom := FAllAtoms.GetAtomByName('moov');
  if Assigned(CustomAtom) then
  begin
    AllTrakAtoms := CustomAtom.GetAllChildAtomsByName('trak');
    try
      SampleOffsetMap := TList<TSampleOffsetMapItem>.Create(TSampleOffsetMapItemsComparer.Create);
      try
        for trakAtom in AllTrakAtoms do
        begin
          CustomAtom := trakAtom.GetChildAtomByName('mdia');
          if not Assigned(CustomAtom) then
            Continue;

          hdlrAtom := ThdlrAtom(CustomAtom.GetChildAtomByName('hdlr'));
          if not Assigned(hdlrAtom) then
            Continue;

          if not hdlrAtom.IsDataLoaded then
            hdlrAtom.LoadKnownData(FFileStream);

          TrackID := hdlrAtom.HandlerTypeData.ComponentSubtype;

          CustomAtom := CustomAtom.GetChildAtomByName('minf');
          if not Assigned(CustomAtom) then
            Continue;

          stblAtom := TstblAtom(CustomAtom.GetChildAtomByName('stbl'));
          if not Assigned(stblAtom) then
            Continue;

          // Get Chunks offset Atom
          CustomAtom := stblAtom.GetChildAtomByName('stco');
          if Assigned(CustomAtom) then
            stcoAtom := TstcoAtom(CustomAtom)
          else
          begin
            CustomAtom := stblAtom.GetChildAtomByName('co64');
            if Assigned(CustomAtom) then
              stcoAtom := Tco64Atom(CustomAtom)
            else
              Continue;
          end;

          // Get Sample to chunk map Atom
          stscAtom := TstscAtom(stblAtom.GetChildAtomByName('stsc'));
          if not Assigned(stscAtom) then
            Continue;

          // Get Sample size table Atom
          stszAtom := TstszAtom(stblAtom.GetChildAtomByName('stsz'));
          if not Assigned(stscAtom) then
            Continue;

          Sample2ChunkMapIndex := 0;
          SampleSizeTableIndex := 0;
          for i := 0 to stcoAtom.ChunksCount - 1 do
          begin
            // check sample to chunk table entry
            if (Cardinal(i) + 1 >= stscAtom.Entries[Sample2ChunkMapIndex].FirstChunk)
              and (Sample2ChunkMapIndex < (stscAtom.EntriesCount - 1))
            then
              Inc(Sample2ChunkMapIndex);

            // process the next portion of sample size table
            NextSampleOffset := stcoAtom.ChunkOffset[i];
            SampleOffsetMap.Capacity := SampleOffsetMap.Count + Integer(stscAtom.Entries[Sample2ChunkMapIndex].SamplesPerChunk);
            for j := SampleSizeTableIndex to SampleSizeTableIndex + stscAtom.Entries[Sample2ChunkMapIndex].SamplesPerChunk - 1 do
            begin
              if j >= Integer(stszAtom.SamplesCount) then
                SampleOffsetMap.Add(
                  TSampleOffsetMapItem.Create(
                    0,
                    0,
                    0,
                    TrackID,
                    i + 1,
                    j + 1
                  )
                )
              else
              begin
                FFileStream.Position := NextSampleOffset;
                SampleOffsetMap.Add(
                  TSampleOffsetMapItem.Create(
                    NextSampleOffset,
                    //0,
                    FFileStream.ReadBigEndianInt64,
                    stszAtom.SampleSize[j],
                    TrackID,
                    i + 1,
                    j + 1
                  )
                );
                NextSampleOffset := NextSampleOffset + stszAtom.SampleSize[j];
              end;
            end;
            SampleSizeTableIndex := SampleSizeTableIndex + stscAtom.Entries[Sample2ChunkMapIndex].SamplesPerChunk;
          end;
        end;

        SampleOffsetMap.Sort;

        with TStreamWriter.Create(FileName, False, TEncoding.Default) do
        try
          WriteLine('TrackID Offset            DataPreview      SampleSize    SampleNumber ChunkNumber');

          for i := 0 to SampleOffsetMap.Count - 1 do
          with SampleOffsetMap.Items[i] do
            WriteLine(Format(' %s   @%.16x %.16x %.5x(%3:.6d) %.6d       %.5d',
             [TrackID, Offset, DataPreview, SampleSize, SampleNumber, ChunkNumber]));
        finally
          Free;
        end;
      finally
        SampleOffsetMap.Free;
      end;
    finally
      AllTrakAtoms.Free;
    end;
  end;
end;

function TMP4Container.GetFileLoaded: Boolean;
begin
  Result := Assigned(FFileStream);
end;

procedure TMP4Container.LoadAtomChild(Atom: TCustomAtom);
begin
  if Assigned(FFileStream) then
    Atom.LoadChildAtoms(FFileStream);
end;

procedure TMP4Container.LoadAtomData(Atom: TCustomAtom);
begin
  if Assigned(FFileStream) then
    Atom.LoadData(FFileStream);
end;

procedure TMP4Container.LoadFromFile(const FileName: string);
begin
  Clear;

  FFileStream := TFileStream.Create(FileOpen(FileName, fmOpenRead or fmShareDenyWrite));
  while FFileStream.Position < FFileStream.Size do
    FAllAtoms.Add(TAtomFactory.CreateAndLoadAtom(FFileStream));
end;

end.
