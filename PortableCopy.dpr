program PortableCopy;

uses
  Vcl.Forms,
  PortCopyMain in 'PortCopyMain.pas' {MainForm};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
