program mp4parser;

{$WEAKLINKRTTI ON}
{$RTTI EXPLICIT METHODS([]) FIELDS([]) PROPERTIES([])}

uses
  Winapi.Windows,
  Vcl.Forms,
  mp4Atoms in 'Classes\mp4Atoms.pas',
  Main in 'Forms\Main.pas' {MainForm},
  mp4Container in 'Classes\mp4Container.pas',
  mp4AtomFactory in 'Classes\mp4AtomFactory.pas',
  mp4StreamHelper in 'Classes\mp4StreamHelper.pas',
  mp4ChunkOffsetTable in 'Classes\mp4ChunkOffsetTable.pas',
  mp4Sample2ChunkMapTable in 'Classes\mp4Sample2ChunkMapTable.pas',
  mp4SampleSizeTable in 'Classes\mp4SampleSizeTable.pas',
  mp4HandlerTypeData in 'Classes\mp4HandlerTypeData.pas',
  mp4SamplesOffsetMap in 'Classes\mp4SamplesOffsetMap.pas';

{$R *.res}

{$IFNDEF DEBUG}
  {$SetPEFlags IMAGE_FILE_RELOCS_STRIPPED} // �������� �� exe ������� ���������
  {$SetPEFlags IMAGE_FILE_DEBUG_STRIPPED} //  �������� �� ��� Debug ����������
  {$SetPEFlags IMAGE_FILE_LINE_NUMS_STRIPPED} // �������� �� exe ���������� � ������� �����
  {$SetPEFlags IMAGE_FILE_LOCAL_SYMS_STRIPPED} // �������� local symbols
{$ENDIF}

// up to 3GB memory for 32bit process in Windows 32
// up to 4GB memory for 32bit process in Windows 64
// up to 8TB memory for 64bit process in Windows 64
  {$SetPEFlags IMAGE_FILE_LARGE_ADDRESS_AWARE}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'mp4parser';
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
