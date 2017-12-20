program mp4parser;

{$WEAKLINKRTTI ON}
{$RTTI EXPLICIT METHODS([]) FIELDS([]) PROPERTIES([])}

uses
  Winapi.Windows,
  Vcl.Forms,
  mp4Atoms in 'Classes\mp4Atoms.pas',
  Unit3 in 'Forms\Unit3.pas' {Form3},
  mp4Container in 'Classes\mp4Container.pas',
  mp4AtomFactory in 'Classes\mp4AtomFactory.pas',
  mp4StreamHelper in 'Classes\mp4StreamHelper.pas',
  mp4ChunkOffsetTable in 'Classes\mp4ChunkOffsetTable.pas',
  mp4Sample2ChunkMapTable in 'Classes\mp4Sample2ChunkMapTable.pas',
  mp4SampleSizesTable in 'Classes\mp4SampleSizesTable.pas';

{$R *.res}

{$IFNDEF DEBUG}
  {$SetPEFlags IMAGE_FILE_RELOCS_STRIPPED} // Удаление из exe таблицы релокаций
  {$SetPEFlags IMAGE_FILE_DEBUG_STRIPPED} //  Удаление из ехе Debug информации
  {$SetPEFlags IMAGE_FILE_LINE_NUMS_STRIPPED} // Удаление из exe информации о номерах строк
  {$SetPEFlags IMAGE_FILE_LOCAL_SYMS_STRIPPED} // Удаление local symbols
{$ENDIF}

// up to 3GB memory for 32bit process in Windows 32
// up to 4GB memory for 32bit process in Windows 64
// up to 8TB memory for 64bit process in Windows 64
  {$SetPEFlags IMAGE_FILE_LARGE_ADDRESS_AWARE}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm3, Form3);
  Application.Run;
end.
