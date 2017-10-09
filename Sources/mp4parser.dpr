program mp4parser;

uses
  Vcl.Forms,
  mp4Atoms in 'Classes\mp4Atoms.pas',
  Unit3 in 'Forms\Unit3.pas' {Form3},
  mp4Container in 'Classes\mp4Container.pas',
  mp4AtomFactory in 'Classes\mp4AtomFactory.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm3, Form3);
  Application.Run;
end.
