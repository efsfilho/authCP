program authCP;



{$R 'resources.res' 'resources.rc'}

uses
  Windows,
  SysUtils,
  Vcl.Forms,
  Unit1 in 'Unit1.pas' {MainForm},
  Unit2 in 'Unit2.pas';

{$R 'resources.res' 'resources.rc'}
{$R *.res}

begin
  if CreateMutex(nil, True, '{42BBC36F-432F-4DE8-A47A-9572A2286A61}') = 0 then
  begin
    RaiseLastOSError;
  end;

  if GetLastError = ERROR_ALREADY_EXISTS then
  begin
    Exit;
  end;

  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainForm);
  //  Application.ShowMainForm := False;
//  MainForm.ShowModal;
  Application.Run;
end.
