unit mp4Container;

interface

uses
  System.Classes, System.SysUtils,
  System.Generics.Collections,
  mp4Atoms, mp4AtomFactory;

type
  TMP4Container = class(TObject)
  private
    FFileStream: TFileStream;
    FAllAtoms: TObjectList<TCustomAtom>;
    function GetFileLoaded: Boolean;
  public
    constructor Create;
    destructor Destroy; override;

    property FileLoaded: Boolean read GetFileLoaded;
    property AllAtoms: TObjectList<TCustomAtom> read FAllAtoms;

    procedure Clear;
    procedure LoadFromFile(const FileName: string);

    procedure LoadAtomData(Atom: TCustomAtom);
    procedure LoadAtomChild(Atom: TCustomAtom);
    procedure ExportAtomData(Atom: TCustomAtom; const FileName: string);
    procedure ExportAtom(Atom: TCustomAtom; const FileName: string);
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

  FAllAtoms := TObjectList<TCustomAtom>.Create;
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
