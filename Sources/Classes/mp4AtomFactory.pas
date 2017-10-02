unit mp4AtomFactory;

interface

uses
  System.Classes, System.Generics.Collections,

  mp4Atoms;

type
  TAtomFactory = class(TObject)
  private
    class var FAtomDictionary: TDictionary<string, TCustomAtomClass>;
    class constructor Create;
    class destructor Destroy;
  public
    class function CreateAndLoadAtom(AStream: TStream): TCustomAtom;
    class procedure RegisterAtomClass(AtomType: string; AtomClass: TCustomAtomClass);
  end;

implementation

{ TAtomFactory }

class constructor TAtomFactory.Create;
begin
  FAtomDictionary := TDictionary<string, TCustomAtomClass>.Create;
end;

class function TAtomFactory.CreateAndLoadAtom(AStream: TStream): TCustomAtom;
var
  Atom: TCustomAtom;
  AtomClass: TCustomAtomClass;
begin
  Atom := TCustomAtom.Create;
  try
    Atom.LoadFromStream(AStream);

    if FAtomDictionary.TryGetValue(Atom.AtomType, AtomClass) then
    begin
      Result := AtomClass.Create;
      try
        Result.Assign(Atom);
        Result.LoadKnownData(AStream);

        if Result.CanContainChild then
          Result.LoadChildAtoms(AStream);
      except
        Result.Free;
        raise;
      end;
    end
    else
    begin
      Result := Atom;
      Atom := nil;
    end;
  finally
    Atom.Free;
  end;
end;

class destructor TAtomFactory.Destroy;
begin
  FAtomDictionary.Free;
end;

class procedure TAtomFactory.RegisterAtomClass(AtomType: string;
  AtomClass: TCustomAtomClass);
begin
  FAtomDictionary.AddOrSetValue(AtomType, AtomClass);
end;

end.
