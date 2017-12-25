unit mp4HandlerTypeData;

interface

uses
  System.Classes, System.SysUtils,
  mp4StreamHelper;

type
// 1 byte    version
// 3 bytes   flags
// 4 bytes   Component type
// 4 bytes   Component subtype
// 4 bytes   Component manufacturer (Reserved)
// 4 bytes   Component flags (Reserved)
// 4 bytes   Component flags mask (Reserved)
// variable  Component name
//
// The component_type can denote this track is 'dhlr' for data or 'mhlr' for media.
// The subtype is a 4 letter code identifying the specific handler - for example
// 'vide' for video, 'soun' for sound, 'alis' for a file alias, and more. The hdlr
// atom under mdia seems more useful than the descendant of minf.

  THandlerTypeData = record     // hdlr Atom
    Version: Byte;
    Flags: array [0..2] of Byte;
    ComponentType: UInt32;
    ComponentSubtype: string; // 4 bytes string
    ComponentManufacturer: UInt32;
    ComponentFlags: UInt32;
    ComponentFlagsMask: UInt32;
    ComponentName: string;
    procedure LoadFromStream(AStream: TStream; DataSize: UInt64);
    constructor Create(AStream: TStream; DataSize: UInt64);
  end;

implementation

{ THandlerTypeData }

constructor THandlerTypeData.Create(AStream: TStream; DataSize: UInt64);
begin
  LoadFromStream(AStream, DataSize);
end;

procedure THandlerTypeData.LoadFromStream(AStream: TStream; DataSize: UInt64);
var
  StringBuff: TBytes;
begin
  AStream.CheckStreamDataAvaliable(DataSize);

  AStream.Read(Version, 1);
  AStream.Read(Flags[0], 3); // 3 bytes flags

  ComponentType := AStream.ReadBigEndianInt; // 4 bytes ComponentType

  SetLength(StringBuff, 4); // 4 bytes ComponentSubtype
  AStream.Read(StringBuff[0], 4);
  ComponentSubtype := StringOf(StringBuff);

  ComponentManufacturer := AStream.ReadBigEndianInt;
  ComponentFlags := AStream.ReadBigEndianInt;
  ComponentFlagsMask := AStream.ReadBigEndianInt;

  SetLength(StringBuff, DataSize - 24); // - all fields before
  if Length(StringBuff) > 0 then
  begin
    AStream.Read(StringBuff[0], Length(StringBuff));
    ComponentName := StringOf(StringBuff);
  end;
end;

end.
