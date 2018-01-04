unit mp4Atoms;

interface

uses
  System.Classes, SysUtils, System.Generics.Collections,
  mp4StreamHelper, mp4ChunkOffsetTable, mp4Sample2ChunkMapTable,
  mp4SampleSizeTable, mp4HandlerTypeData;

//const
//  'ftyp'
//    'pdin'
//    'moov'
//    'moof'
//    'mfra'
//    'free'
//    'skip'
//    'junk'
//    'wide'
//    'pnot'
//    'pict'
//    'meta'
//    'meco'
//    'uuid' : Used by Sony's MSNV brand of MP4
//    'mdat'

type
  TCustomAtom = class;

  TAtomsList = class(TObjectList<TCustomAtom>)
  public
    function GetAtomByName(const AtomName: string): TCustomAtom;
    function GetAllAtomsByName(const AtomName: string): TList<TCustomAtom>;
  end;

  TCustomAtomClass = class of TCustomAtom;

  TCustomAtom = class(TPersistent)
//  private
//    procedure SetSize(const Value: Int64);
  protected
    FPosition: Int64;
    FSize: Int64;     // Atom size with header
    FType: string;
    FDataPosition: Int64;
    FDataSize: Int64;
    FDataStream: TMemoryStream;
    FChildAtomPosition: Int64;
    FChildAtomCollection: TAtomsList;

    function GetAvaliableChildTypes: string; virtual;
    function IsChildTypeAvaliable(const ChildType: string): Boolean;

    procedure LoadDataPreview(AStream: TStream);
  protected
    class procedure RegisterAtomClass(AtomType: string; AtomClass: TCustomAtomClass);
  public
    constructor Create; overload;
    constructor Create(AStream: TStream); overload;
    destructor Destroy; override;

    property Position: Int64 read FPosition;
    property Size: Int64 read FSize; // write SetSize;
    property DataSize: Int64 read FDataSize;
    property AtomType: string read FType;
    property DataStream: TMemoryStream read FDataStream;
    property ChildAtomCollection: TAtomsList read FChildAtomCollection;
    function IsDataLoaded: Boolean;

    procedure LoadFromStream(AStream: TStream);
    procedure LoadData(AStream: TStream);
    procedure LoadChildAtoms(AStream: TStream);
    procedure LoadKnownData(AStream: TStream); virtual;

    procedure CopyData(ADataSourceStream, ADestStream: TStream);
    procedure SaveAtom(ADataSourceStream, ADestStream: TStream);

    function CanContainChild: Boolean; virtual;
    procedure Assign(Source: TPersistent); override;

    function GetChildAtomByName(const AtomName: string): TCustomAtom;
    function GetAllChildAtomsByName(const AtomName: string): TList<TCustomAtom>;
  end;

  TCustomNoChildAtom = class(TCustomAtom)
  protected
    function GetAvaliableChildTypes: string; override;
  public
    function CanContainChild: Boolean; override;
  end;

  TftypAtom = class(TCustomNoChildAtom)
  const
    ATOM_TYPE = 'ftyp';
  end;

  TmoovAtom = class(TCustomAtom)
  const
    ATOM_TYPE = 'moov';
  protected
    function GetAvaliableChildTypes: string; override;
  end;

  TmvhdAtom = class(TCustomNoChildAtom)
  const
    ATOM_TYPE = 'mvhd';
  public
    procedure LoadKnownData(AStream: TStream); override;
  end;

  TtrakAtom = class(TCustomAtom)
  const
    ATOM_TYPE = 'trak';
  protected
    function GetAvaliableChildTypes: string; override;
  end;

  TtkhdAtom = class(TCustomNoChildAtom)
  const
    ATOM_TYPE = 'tkhd';
  end;

  TmdiaAtom = class(TCustomAtom)
  const
    ATOM_TYPE = 'mdia';
  protected
    function GetAvaliableChildTypes: string; override;
  end;

  TmdhdAtom = class(TCustomNoChildAtom)
  const
    ATOM_TYPE = 'mdhd';
  public
    procedure LoadKnownData(AStream: TStream); override;
  end;

  ThdlrAtom = class(TCustomNoChildAtom)
  const
    ATOM_TYPE = 'hdlr';
  public
    HandlerTypeData: THandlerTypeData;
    procedure LoadKnownData(AStream: TStream); override;
  end;

  TminfAtom = class(TCustomAtom)
  const
    ATOM_TYPE = 'minf';
  protected
    function GetAvaliableChildTypes: string; override;
  end;

  TstblAtom = class(TCustomAtom)
  const
    ATOM_TYPE = 'stbl';
  protected
    function GetAvaliableChildTypes: string; override;
  end;

  TstcoAtom = class(TCustomNoChildAtom)
  const
    ATOM_TYPE = 'stco';
  private
    function GetChunkOffset(Index: Uint32): UInt64; virtual;
    function GetChunksCount: Uint32; virtual;
  public
    ChunkOffsetTable: TChunkOffsetTable;
    procedure LoadKnownData(AStream: TStream); override;
    property ChunksCount: Uint32 read GetChunksCount;
    property ChunkOffset[Index: Uint32]: UInt64 read GetChunkOffset;
  end;

  Tco64Atom = class(TstcoAtom)
  const
    ATOM_TYPE = 'co64';
  private
    function GetChunkOffset(Index: Uint32): UInt64; override;
    function GetChunksCount: Uint32; override;
  public
    ChunkOffsetTable: TChunkOffsetTable64;
    procedure LoadKnownData(AStream: TStream); override;
  end;

  TstscAtom = class(TCustomNoChildAtom)
  const
    ATOM_TYPE = 'stsc';
  private
    function GetEntriesCount: Cardinal;
    function GetTableEntry(Index: Cardinal): TSample2ChunkMapTableEntry;
  public
    Sample2ChunkMap: TSample2ChunkMapTable;
    property EntriesCount: Cardinal read GetEntriesCount;
    property Entries[Index: Cardinal]: TSample2ChunkMapTableEntry read GetTableEntry;
    procedure LoadKnownData(AStream: TStream); override;
  end;

  TstszAtom = class(TCustomNoChildAtom)
  const
    ATOM_TYPE = 'stsz';
  private
    function GetSamplesCount: Cardinal;
    function GetSampleSize(Index: Cardinal): UInt32;
  public
    SampleSizeTable: TSampleSizeTable;
    property SamplesCount: Cardinal read GetSamplesCount;
    property SampleSize[Index: Cardinal]: UInt32 read GetSampleSize;
    procedure LoadKnownData(AStream: TStream); override;
  end;

implementation

uses
  mp4AtomFactory;

resourcestring
  ATOM_SIZE_IS_WRONG = 'Atom (%s) has wrong size (%d) at position (0x%.8X).';

const
  HEADER_SIZE_32 = 4 + 4;     // 32bit size + type
  HEADER_SIZE_64 = 4 + 4 + 8; // 32bit size + type + 64bit size

  ANY_CHILD_TYPE = '*';

procedure RegisterAtoms;
begin
  TAtomFactory.RegisterAtomClass(TftypAtom.ATOM_TYPE, TftypAtom);
  TAtomFactory.RegisterAtomClass(TmoovAtom.ATOM_TYPE, TmoovAtom);
  TAtomFactory.RegisterAtomClass(TmvhdAtom.ATOM_TYPE, TmvhdAtom);
  TAtomFactory.RegisterAtomClass(TtrakAtom.ATOM_TYPE, TtrakAtom);
  TAtomFactory.RegisterAtomClass(TtkhdAtom.ATOM_TYPE, TtkhdAtom);
  TAtomFactory.RegisterAtomClass(TmdiaAtom.ATOM_TYPE, TmdiaAtom);
  TAtomFactory.RegisterAtomClass(TmdhdAtom.ATOM_TYPE, TmdhdAtom);
  TAtomFactory.RegisterAtomClass(ThdlrAtom.ATOM_TYPE, ThdlrAtom);
  TAtomFactory.RegisterAtomClass(TminfAtom.ATOM_TYPE, TminfAtom);
  TAtomFactory.RegisterAtomClass(TstblAtom.ATOM_TYPE, TstblAtom);
  TAtomFactory.RegisterAtomClass(TstcoAtom.ATOM_TYPE, TstcoAtom);
  TAtomFactory.RegisterAtomClass(Tco64Atom.ATOM_TYPE, Tco64Atom);
  TAtomFactory.RegisterAtomClass(TstscAtom.ATOM_TYPE, TstscAtom);
  TAtomFactory.RegisterAtomClass(TstszAtom.ATOM_TYPE, TstszAtom);
end;

{ TCustomAtom }

constructor TCustomAtom.Create;
begin
  inherited Create;

  FDataStream := TMemoryStream.Create;
  FChildAtomCollection := TAtomsList.Create;
end;

procedure TCustomAtom.Assign(Source: TPersistent);
begin
  if Assigned(Source) and (Source is TCustomAtom) then
  begin
    FPosition := (Source as TCustomAtom).FPosition;
    FSize := (Source as TCustomAtom).FSize;
    FType := (Source as TCustomAtom).FType;
    FDataPosition := (Source as TCustomAtom).FDataPosition;
    FDataSize := (Source as TCustomAtom).FDataSize;
    FDataStream.CopyFrom((Source as TCustomAtom).FDataStream, 0);
    FChildAtomPosition := (Source as TCustomAtom).FChildAtomPosition;
    FChildAtomCollection.Clear;
    FChildAtomCollection.AddRange((Source as TCustomAtom).FChildAtomCollection);
  end;
end;

function TCustomAtom.CanContainChild: Boolean;
begin
  Result := True;
end;

constructor TCustomAtom.Create(AStream: TStream);
begin
  Create;

  LoadFromStream(AStream);
end;

destructor TCustomAtom.Destroy;
begin
  FDataStream.Free;
  FChildAtomCollection.Free;

  inherited Destroy;
end;

function TCustomAtom.GetAllChildAtomsByName(
  const AtomName: string): TList<TCustomAtom>;
begin
  Result := FChildAtomCollection.GetAllAtomsByName(AtomName);
end;

function TCustomAtom.GetAvaliableChildTypes: string;
begin
  Result := ANY_CHILD_TYPE; // any child
end;

function TCustomAtom.GetChildAtomByName(const AtomName: string): TCustomAtom;
begin
  Result := FChildAtomCollection.GetAtomByName(AtomName);
end;

function TCustomAtom.IsChildTypeAvaliable(const ChildType: string): Boolean;
var
  AvaliableChildTypes: string;
begin
  AvaliableChildTypes := GetAvaliableChildTypes;
  Result := AvaliableChildTypes = ANY_CHILD_TYPE;
  if not Result then
    Result := Pos(ChildType, AvaliableChildTypes) > 0;
end;

function TCustomAtom.IsDataLoaded: Boolean;
begin
  Result := (FSize > 0) and (FDataStream.Size = FDataSize);
end;

procedure TCustomAtom.LoadChildAtoms(AStream: TStream);

  function GetChildType: string;
  var
    Buffer: TBytes;
  begin
    SetLength(Buffer, 4);
    AStream.Read(Buffer, 4); // 32bit size
    AStream.Read(Buffer, 4); // type
    Result := StringOf(Buffer);
    AStream.Seek(-HEADER_SIZE_32, soCurrent);
  end;

begin
  if (FChildAtomPosition > 0) and CanContainChild then
  begin
    FChildAtomCollection.Clear;

    AStream.Position := FChildAtomPosition;

    while AStream.Position < (FPosition + FSize) do
      FChildAtomCollection.Add(TAtomFactory.CreateAndLoadAtom(AStream));
  end;
end;

procedure TCustomAtom.LoadData(AStream: TStream);
begin
  AStream.Position := FDataPosition;

  FDataStream.Position := 0;
  AStream.CheckStreamDataAvaliable(FDataSize);
  FDataStream.CopyFrom(AStream, FDataSize);
end;

procedure TCustomAtom.LoadDataPreview(AStream: TStream);
begin
  AStream.Position := FDataPosition;

  if FDataSize <= HEADER_SIZE_64 then
  begin
    AStream.CheckStreamDataAvaliable(FDataSize);

    FDataStream.CopyFrom(AStream, FDataSize);
  end
  else
  begin
    AStream.CheckStreamDataAvaliable(HEADER_SIZE_64);

    FDataStream.CopyFrom(AStream, HEADER_SIZE_64);

    AStream.Seek(FDataSize - HEADER_SIZE_64, soCurrent);
  end;
end;

procedure TCustomAtom.LoadFromStream(AStream: TStream);
var
  AtomSize: UInt32;
  Buffer: TBytes;
begin
  FPosition := AStream.Position;

  AStream.CheckStreamDataAvaliable(HEADER_SIZE_32);
  AtomSize := AStream.ReadBigEndianInt;

  SetLength(Buffer, 4);
  AStream.Read(Buffer, 4);
  FType := StringOf(Buffer);

  if AtomSize = 1 then // 64bit atom header
  begin
    AStream.CheckStreamDataAvaliable(HEADER_SIZE_64 - HEADER_SIZE_32);

    FSize := AStream.ReadBigEndianInt64;
    FDataSize := FSize - HEADER_SIZE_64;
  end
  else   // 32bit atom header
  begin
    FSize := AtomSize;
    if FSize < HEADER_SIZE_32 then  //TODO: '.' for unprintable ASCII char in FType
      raise EReadError.CreateFmt(ATOM_SIZE_IS_WRONG, [Trim(FType), FSize, FPosition]);

    FDataSize := FSize - HEADER_SIZE_32;
  end;

  FDataPosition := AStream.Position;

  if FDataSize = 0 then
    Exit;

  FChildAtomPosition := FDataPosition;

  LoadDataPreview(AStream);
end;

procedure TCustomAtom.LoadKnownData(AStream: TStream);
begin
  // no known data
end;

class procedure TCustomAtom.RegisterAtomClass(AtomType: string;
  AtomClass: TCustomAtomClass);
begin
  TAtomFactory.RegisterAtomClass(AtomType, AtomClass);
end;

procedure TCustomAtom.SaveAtom(ADataSourceStream, ADestStream: TStream);
var
  AtomSize32: UInt32;
  AtomSize64: UInt64;
  AtomType: TBytes;
begin
  AtomType := TEncoding.ASCII.GetBytes(FType);
  if FDataSize + HEADER_SIZE_32 > $FFFFFFFF then // MaxUInt32
  begin
    AtomSize32 := 1;
    ADestStream.WriteBigEndianInt(AtomSize32);
    ADestStream.Write(AtomType, Length(AtomType));
    AtomSize64 := FDataSize + HEADER_SIZE_32;
    ADestStream.WriteBigEndianInt64(AtomSize64);
  end
  else
  begin
    AtomSize32 := FDataSize + HEADER_SIZE_32;
    ADestStream.WriteBigEndianInt(AtomSize32);
    ADestStream.Write(AtomType, Length(AtomType));
  end;

  CopyData(ADataSourceStream, ADestStream);
end;

procedure TCustomAtom.CopyData(ADataSourceStream, ADestStream: TStream);
var
  DataSourceStream: TStream;
begin
  if Assigned(ADataSourceStream) then
  begin
    DataSourceStream := ADataSourceStream;
    DataSourceStream.Position := FDataPosition;
  end
  else
  begin
    DataSourceStream := FDataStream;
    DataSourceStream.Position := 0;
  end;

  DataSourceStream.CheckStreamDataAvaliable(FDataSize);

  ADestStream.CopyFrom(DataSourceStream, FDataSize);
end;

//procedure TCustomAtom.SetSize(const Value: Int64);
//var
//  NewDataSize: Int64;
//begin
//  if FSize <> Value then
//  begin
//    FSize := Value;
//
//    if IsDataLoaded then
//    begin
//      if FSize > $FFFFFFFF then  // 64bit header
//        NewDataSize := FSize - HEADER_SIZE_64
//      else                   // 32bit header
//        NewDataSize := FSize - HEADER_SIZE_32;
//
//      FData.SetSize(NewDataSize);
//    end;
//  end;
//end;

{ TmoovAtom }

function TmoovAtom.GetAvaliableChildTypes: string;
begin
  Result := 'mvhd';
end;

{ TmvhdAtom }

procedure TmvhdAtom.LoadKnownData(AStream: TStream);
begin
  // ???
end;

{ TtrakAtom }

function TtrakAtom.GetAvaliableChildTypes: string;
begin
  Result := 'tkhd|mdia|edts';
end;

{ TmdhdAtom }

procedure TmdhdAtom.LoadKnownData(AStream: TStream);
begin
//  An mdhd version 0 atom has the following structure:
//
// QuickTime Atom Preamble
// 1 byte    version
// 3 bytes   flags
// 4 bytes   creation time
// 4 bytes   modification time
// 4 bytes   time scale
// 4 bytes   duration
// 2 bytes   language
// 2 bytes   quality
//
//For version 1 instead a few entries have changed sizes from 4 to 8 bytes:
//
// QuickTime Atom Preamble
// 1 byte    version
// 3 bytes   flags
// 8 bytes   creation time
// 8 bytes   modification time
// 4 bytes   time scale
// 8 bytes   duration
// 2 bytes   language
// 2 bytes   quality

// The language value is a three letters ISO 639 language code represented with
// three 5-bit values (each of which is the ASCII value of the letter minus 0x60).
end;

{ TmdiaAtom }

function TmdiaAtom.GetAvaliableChildTypes: string;
begin
  Result := 'mdhd|hdlr|minf';
end;

{ ThdlrAtom }

procedure ThdlrAtom.LoadKnownData(AStream: TStream);
begin
  LoadData(AStream); // load DataStream
  FDataStream.Position := 0;
  HandlerTypeData := THandlerTypeData.Create(FDataStream, FDataSize);
end;

{ TminfAtom }

function TminfAtom.GetAvaliableChildTypes: string;
begin
  Result := 'gmhd|smhd|stbl|vmhd|dinf';
end;

{ TstblAtom }

function TstblAtom.GetAvaliableChildTypes: string;
begin
  Result := 'co64|ctts|stco|stsc|stsd|stss|stsz|stts';
end;

{ TstcoAtom }

function TstcoAtom.GetChunkOffset(Index: Uint32): UInt64;
begin
  if (Index < ChunkOffsetTable.Count) then
    Result := ChunkOffsetTable.ChunkOffset[Index]
  else
    raise EArgumentOutOfRangeException.Create('Argument is out of range');
end;

function TstcoAtom.GetChunksCount: Uint32;
begin
  Result := ChunkOffsetTable.Count;
end;

procedure TstcoAtom.LoadKnownData(AStream: TStream);
begin
  LoadData(AStream); // load DataStream
  FDataStream.Position := 0;
  ChunkOffsetTable := TChunkOffsetTable.Create(FDataStream);
end;

{ Tco64Atom }

function Tco64Atom.GetChunkOffset(Index: Uint32): UInt64;
begin
  if (Index < ChunkOffsetTable.Count) then
    Result := ChunkOffsetTable.ChunkOffset[Index]
  else
    raise EArgumentOutOfRangeException.Create('Argument is out of range');
end;

function Tco64Atom.GetChunksCount: Uint32;
begin
  Result := ChunkOffsetTable.Count;
end;

procedure Tco64Atom.LoadKnownData(AStream: TStream);
begin
  LoadData(AStream); // load DataStream
  FDataStream.Position := 0;
  ChunkOffsetTable := TChunkOffsetTable64.Create(FDataStream);
end;

{ TAtomsList }

function TAtomsList.GetAllAtomsByName(const AtomName: string): TList<TCustomAtom>;
var
  Atom: TCustomAtom;
begin
  Result := TList<TCustomAtom>.Create;
  try
    for Atom in Self do
      if SameText(Atom.AtomType, AtomName) then
        Result.Add(Atom);
  except
    Result.Free;
    raise;
  end;
end;

function TAtomsList.GetAtomByName(const AtomName: string): TCustomAtom;
begin
  for Result in Self do
    if SameText(Result.AtomType, AtomName) then
      Exit;

  Result := nil;
end;

{ TstscAtom }

function TstscAtom.GetEntriesCount: Cardinal;
begin
  Result := Sample2ChunkMap.Count;
end;

function TstscAtom.GetTableEntry(Index: Cardinal): TSample2ChunkMapTableEntry;
begin
  if (Index < Sample2ChunkMap.Count) then
    Result := Sample2ChunkMap.Entries[Index]
  else
    raise EArgumentOutOfRangeException.Create('Argument is out of range');
end;

procedure TstscAtom.LoadKnownData(AStream: TStream);
begin
  LoadData(AStream); // load DataStream
  FDataStream.Position := 0;
  Sample2ChunkMap := TSample2ChunkMapTable.Create(FDataStream);
end;

{ TCustomNoChildAtom }

function TCustomNoChildAtom.CanContainChild: Boolean;
begin
  Result := False;
end;

function TCustomNoChildAtom.GetAvaliableChildTypes: string;
begin
  Result := '';
end;

{ TstszAtom }

function TstszAtom.GetSamplesCount: Cardinal;
begin
  Result := SampleSizeTable.Count;
end;

function TstszAtom.GetSampleSize(Index: Cardinal): UInt32;
begin
  if Index < SampleSizeTable.Count then
    Result := SampleSizeTable.SampleSizes[Index]
  else
    raise EArgumentOutOfRangeException.Create('Argument is out of range');
end;

procedure TstszAtom.LoadKnownData(AStream: TStream);
begin
  LoadData(AStream); // load DataStream
  FDataStream.Position := 0;
  SampleSizeTable := TSampleSizeTable.Create(FDataStream);
end;

initialization
  RegisterAtoms;

end.
