unit mp4Atoms;

interface

uses
  System.Classes, SysUtils, System.Generics.Collections,
  mp4StreamHelper, mp4SampleChunkOffsetTable;

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
    FChildAtomCollection: TObjectList<TCustomAtom>;

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
    property ChildAtomCollection: TObjectList<TCustomAtom> read FChildAtomCollection;
    function IsDataLoaded: Boolean;

    procedure LoadFromStream(AStream: TStream);
    procedure LoadData(AStream: TStream);
    procedure LoadChildAtoms(AStream: TStream);
    procedure LoadKnownData(AStream: TStream); virtual;

    procedure CopyData(ADataSourceStream, ADestStream: TStream);
    procedure SaveAtom(ADataSourceStream, ADestStream: TStream);

    function CanContainChild: Boolean; virtual;
    procedure Assign(Source: TPersistent); override;
  end;

  TftypAtom = class(TCustomAtom)
  const
    ATOM_TYPE = 'ftyp';
  protected
    function GetAvaliableChildTypes: string; override;
  public
    function CanContainChild: Boolean; override;
  end;

  TmoovAtom = class(TCustomAtom)
  const
    ATOM_TYPE = 'moov';
  protected
    function GetAvaliableChildTypes: string; override;
  end;

  TmvhdAtom = class(TCustomAtom)
  const
    ATOM_TYPE = 'mvhd';
  protected
    function GetAvaliableChildTypes: string; override;
  public
    function CanContainChild: Boolean; override;
    procedure LoadKnownData(AStream: TStream); override;
  end;

  TtrakAtom = class(TCustomAtom)
  const
    ATOM_TYPE = 'trak';
  protected
    function GetAvaliableChildTypes: string; override;
  end;

  TtkhdAtom = class(TCustomAtom)
  const
    ATOM_TYPE = 'tkhd';
  protected
    function GetAvaliableChildTypes: string; override;
  public
    function CanContainChild: Boolean; override;
  end;

  TmdiaAtom = class(TCustomAtom)
  const
    ATOM_TYPE = 'mdia';
  protected
    function GetAvaliableChildTypes: string; override;
  end;

  TmdhdAtom = class(TCustomAtom)
  const
    ATOM_TYPE = 'mdhd';
  protected
    function GetAvaliableChildTypes: string; override;
  public
    procedure LoadKnownData(AStream: TStream); override;
    function CanContainChild: Boolean; override;
  end;

  ThdlrAtom = class(TCustomAtom)
  const
    ATOM_TYPE = 'hdlr';
  protected
    function GetAvaliableChildTypes: string; override;
  public
    procedure LoadKnownData(AStream: TStream); override;
    function CanContainChild: Boolean; override;
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

  TstcoAtom = class(TCustomAtom)
  const
    ATOM_TYPE = 'stco';
  protected
    function GetAvaliableChildTypes: string; override;
  public
    ChunkOffsetTable: TSampleChunkOffsetTable;
    procedure LoadKnownData(AStream: TStream); override;
    function CanContainChild: Boolean; override;
  end;

  Tco64Atom = class(TCustomAtom)
  const
    ATOM_TYPE = 'co64';
  protected
    function GetAvaliableChildTypes: string; override;
  public
    ChunkOffsetTable: TSampleChunkOffsetTable64;
    procedure LoadKnownData(AStream: TStream); override;
    function CanContainChild: Boolean; override;
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
end;

{ TCustomAtom }

constructor TCustomAtom.Create;
begin
  inherited Create;

  FDataStream := TMemoryStream.Create;
  FChildAtomCollection := TObjectList<TCustomAtom>.Create;
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

function TCustomAtom.GetAvaliableChildTypes: string;
begin
  Result := ANY_CHILD_TYPE; // any child
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

{ TftypAtom }

function TftypAtom.CanContainChild: Boolean;
begin
  Result := False;
end;

function TftypAtom.GetAvaliableChildTypes: string;
begin
  Result := '';
end;

{ TmoovAtom }

function TmoovAtom.GetAvaliableChildTypes: string;
begin
  Result := 'mvhd';
end;

{ TmvhdAtom }

function TmvhdAtom.CanContainChild: Boolean;
begin
  Result := False;
end;

function TmvhdAtom.GetAvaliableChildTypes: string;
begin
  Result := '';
end;

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

function TmdhdAtom.CanContainChild: Boolean;
begin
  Result := False;
end;

function TmdhdAtom.GetAvaliableChildTypes: string;
begin
  Result := '';
end;

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

{ TtkhdAtom }

function TtkhdAtom.CanContainChild: Boolean;
begin
  Result := False;
end;

function TtkhdAtom.GetAvaliableChildTypes: string;
begin
  Result := '';
end;

{ TmdiaAtom }

function TmdiaAtom.GetAvaliableChildTypes: string;
begin
  Result := 'mdhd|hdlr|minf';
end;

{ ThdlrAtom }

function ThdlrAtom.CanContainChild: Boolean;
begin
  Result := False;
end;

function ThdlrAtom.GetAvaliableChildTypes: string;
begin
  Result := '';
end;

procedure ThdlrAtom.LoadKnownData(AStream: TStream);
begin
//   version
//   flags
//   component_type
//   subtype
//   manufacturer
//   res_flags
//   res_flags_mask
//   name
//
// The component_type can denote this track is 'dhlr' for data or 'mhlr' for media.
// The subtype is a 4 letter code identifying the specific handler - for example
// 'vide' for video, 'soun' for sound, 'alis' for a file alias, and more. The hdlr
// atom under mdia seems more useful than the descendant of minf.
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

function TstcoAtom.CanContainChild: Boolean;
begin
  Result := False;
end;

function TstcoAtom.GetAvaliableChildTypes: string;
begin
  Result := '';
end;

procedure TstcoAtom.LoadKnownData(AStream: TStream);
begin
  AStream.Position := FDataPosition;
  ChunkOffsetTable := TSampleChunkOffsetTable.Create(AStream);
end;

{ Tco64Atom }

function Tco64Atom.CanContainChild: Boolean;
begin
  Result := False;
end;

function Tco64Atom.GetAvaliableChildTypes: string;
begin
  Result := '';
end;

procedure Tco64Atom.LoadKnownData(AStream: TStream);
begin
  AStream.Position := FDataPosition;
  ChunkOffsetTable := TSampleChunkOffsetTable64.Create(AStream);
end;

initialization
  RegisterAtoms;

end.
