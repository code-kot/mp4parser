unit Unit3;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, System.Actions, Vcl.ActnList,
  Vcl.StdActns, Vcl.Menus, Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.StdCtrls,

  System.Generics.Collections, System.UITypes,

  mp4Atoms, mp4Container;

type
  TForm3 = class(TForm)
    mmo1: TMemo;
    tv1: TTreeView;
    spl1: TSplitter;
    mm1: TMainMenu;
    mniFile: TMenuItem;
    actlst1: TActionList;
    flpnFileOpen: TFileOpen;
    mniFileOpen: TMenuItem;
    mniExit: TMenuItem;
    pm1: TPopupMenu;
    ALoadAtomData: TAction;
    mniLoadAtomData: TMenuItem;
    ALoadChildAtoms: TAction;
    mniLoadChildAtoms: TMenuItem;
    procedure mniExitClick(Sender: TObject);
    procedure flpnFileOpenAccept(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure pm1Popup(Sender: TObject);
    procedure ALoadAtomDataExecute(Sender: TObject);
    procedure ALoadChildAtomsExecute(Sender: TObject);
  private
    { Private declarations }
    FFileName: string;
    FAllAtoms: TObjectList<TCustomAtom>;
    FMP4Container: TMP4Container;
    function GetAtomPreviewHexStr(Atom: TCustomAtom): string;
    function GetAtomPreviewStr(Atom: TCustomAtom): string;
    procedure AddAtomInfo(tv: TTreeView; TVRoot: TTreeNode; Atom: TCustomAtom);
    procedure AddAtomSubInfo(tv: TTreeView; TVRoot: TTreeNode; Atom: TCustomAtom);
    function TVItemsWithObjectsSelected(tv: TTreeView): Boolean;
    function TVItemsWithChildObjectsSelected(tv: TTreeView): Boolean;
    procedure UpdateUI;
  public
    { Public declarations }
  end;

var
  Form3: TForm3;

implementation

{$R *.dfm}

const
 PREVIEW_SIZE = 24;

type
  TByteArray = array [0..0] of Byte;
  PByteArray = ^TByteArray;

procedure TForm3.AddAtomInfo(tv: TTreeView; TVRoot: TTreeNode; Atom: TCustomAtom);
var
  TVChild: TTreeNode;
begin
  TVChild := tv.Items.AddChildObject(TVRoot, Format('%s (%u)', [Atom.AtomType, Atom.Size]), Atom);

  mmo1.Lines.Add(StringOfChar(' ', TVRoot.Level) + Format('Atom %s @ %u of size: %u, ends @ %u', [Atom.AtomType, Atom.Position, Atom.Size, Atom.Position + Atom.Size]));

  AddAtomSubInfo(tv, TVChild, Atom);
end;

procedure TForm3.AddAtomSubInfo(tv: TTreeView; TVRoot: TTreeNode;
  Atom: TCustomAtom);
var
  ChildAtom: TCustomAtom;
begin
  TVRoot.DeleteChildren;

  tv.Items.AddChild(TVRoot, Format('Data: %s', [GetAtomPreviewHexStr(Atom)]));
  tv.Items.AddChild(TVRoot, Format('DataStr: %s', [GetAtomPreviewStr(Atom)]));

  for ChildAtom in Atom.ChildAtomCollection do
    AddAtomInfo(tv, TVRoot, ChildAtom);
end;

procedure TForm3.ALoadAtomDataExecute(Sender: TObject);
var
  i: Integer;
begin
  tv1.Items.BeginUpdate;
  try
    for i := 0 to tv1.SelectionCount - 1 do
      if Assigned(tv1.Selections[i].Data) then
      begin
        FMP4Container.LoadAtomData(tv1.Selections[i].Data);
        AddAtomSubInfo(tv1, tv1.Selections[i], tv1.Selections[i].Data);
        tv1.Selections[i].Expand(False);
      end;
  finally
    tv1.Items.EndUpdate;
  end;

//  UpdateUI;
end;

procedure TForm3.ALoadChildAtomsExecute(Sender: TObject);
var
  i: Integer;
//  Atom: TCustomAtom;
begin
  tv1.Items.BeginUpdate;
  try
    for i := 0 to tv1.SelectionCount - 1 do
      if Assigned(tv1.Selections[i].Data) then
      begin
        FMP4Container.LoadAtomChild(tv1.Selections[i].Data);
        AddAtomSubInfo(tv1, tv1.Selections[i], tv1.Selections[i].Data);
        tv1.Selections[i].Expand(False);
//        for Atom in TCustomAtom(tv1.Selections[i].Data).ChildAtomCollection do
//          AddAtomInfo(tv1, tv1.Selections[i], Atom);
      end;
  finally
    tv1.Items.EndUpdate;
  end;
end;

procedure TForm3.flpnFileOpenAccept(Sender: TObject);
begin
  FMP4Container.Clear;

  FFileName := flpnFileOpen.Dialog.FileName;

  FMP4Container.LoadFromFile(FFileName);

  UpdateUI;
end;

procedure TForm3.FormCreate(Sender: TObject);
begin
  mmo1.Clear;
  FAllAtoms := TObjectList<TCustomAtom>.Create;
  FMP4Container := TMP4Container.Create;
end;

procedure TForm3.FormDestroy(Sender: TObject);
begin
  FAllAtoms.Free;

  FMP4Container.Free;
end;

function TForm3.GetAtomPreviewHexStr(Atom: TCustomAtom): string;
var
  i: Integer;
  PreviewSize: Integer;
begin
  Result := '';
  if (Atom.DataSize > 0) then
  begin
    if Atom.IsDataLoaded then
      PreviewSize := Atom.DataSize
    else
    begin
      PreviewSize := PREVIEW_SIZE;
      if Atom.DataSize < PreviewSize then
        PreviewSize := Atom.DataSize;
    end;

    for i := 0 to PreviewSize - 1 do
      Result := Result + IntToHex(PByteArray(Atom.DataStream.Memory)^[i], 2);
  end;
end;

function TForm3.GetAtomPreviewStr(Atom: TCustomAtom): string;
var
  i: Integer;
  PreviewSize: Integer;
begin
  Result := '';
  if (Atom.DataSize > 0) then
  begin
    if Atom.IsDataLoaded then
      PreviewSize := Atom.DataSize
    else
    begin
      PreviewSize := PREVIEW_SIZE;
      if Atom.DataSize < PreviewSize then
        PreviewSize := Atom.DataSize;
    end;

    for i := 0 to PreviewSize - 1 do
      if (PByteArray(Atom.DataStream.Memory)^[i] >= 32)
        and (PByteArray(Atom.DataStream.Memory)^[i] <= 126)
      then
        Result := Result + Char(PByteArray(Atom.DataStream.Memory)^[i])
      else
        Result := Result + '.';
  end;
end;

procedure TForm3.mniExitClick(Sender: TObject);
begin
  Close;
end;

procedure TForm3.pm1Popup(Sender: TObject);
begin
  ALoadAtomData.Enabled := (tv1.Items.Count > 0) and TVItemsWithObjectsSelected(tv1);
  ALoadChildAtoms.Enabled := (tv1.Items.Count > 0) and TVItemsWithChildObjectsSelected(tv1);
end;

function TForm3.TVItemsWithChildObjectsSelected(tv: TTreeView): Boolean;
var
  i: Integer;
begin
  for i := 0 to tv.SelectionCount - 1 do
    if Assigned(tv.Selections[i].Data) and TCustomAtom(tv.Selections[i].Data).CanContainChild then
      Exit(True);

  Result := False;
end;

function TForm3.TVItemsWithObjectsSelected(tv: TTreeView): Boolean;
var
  i: Integer;
begin
  for i := 0 to tv.SelectionCount - 1 do
    if Assigned(tv.Selections[i].Data) then
      Exit(True);

  Result := False;
end;

procedure TForm3.UpdateUI;
var
  Atom: TCustomAtom;
  TVRoot: TTreeNode;
begin
  mmo1.Clear;
  tv1.Items.Clear;
  TVRoot := tv1.Items.Add(nil, ExtractFileName(FFileName));
  for Atom in FMP4Container.AllAtoms do
    AddAtomInfo(tv1, TVRoot, Atom);
end;

end.
