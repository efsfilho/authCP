unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.AppEvnts, Vcl.StdCtrls,
  Vcl.Menus, Vcl.OleCtrls, System.RegularExpressions, SHDocVw, Winapi.Activex, MSHTML,
  IdBaseComponent, IdComponent, IdTCPConnection, IdTCPClient, idHttp,
  IdIOHandler, IdIOHandlerSocket, IdIOHandlerStack, IdSSL, IdSSLOpenSSL,
  Vcl.ImgList, frxCtrls, Data.Bind.Components, Data.Bind.ObjectScope,
  REST.Client, REST.Authenticator.Basic, ComboBoxValue, Unit2;

type

  //  TWebBrowser = class(SHDocVw.TWebBrowser)
  TWebBrowser = class(SHDocVw.TWebBrowser, IOleCommandTarget)
  private
    function QueryStatus(CmdGroup: PGUID; cCmds: Cardinal; prgCmds: POleCmd; CmdText: POleCmdText): HResult; stdcall;
    function Exec(CmdGroup: PGUID; nCmdID, nCmdexecopt: DWORD; const vaIn: OleVariant; var vaOut: OleVariant): HResult; stdcall;
  end;

  TMainForm = class(TForm)
    trycn1: TTrayIcon;
    btn1: TButton;
    pm1: TPopupMenu;
    mniSair1: TMenuItem;
    mnieste1: TMenuItem;
    WebBrowser1: TWebBrowser;
    tmrGetAuth: TTimer;
    Edit1: TEdit;
    Edit2: TEdit;
    IdHTTP1: TIdHTTP;
    IdSSLIOHandlerSocketOpenSSL1: TIdSSLIOHandlerSocketOpenSSL;
    tmrMain: TTimer;
    il1: TImageList;
    chk1: TCheckBox;
    lbl1: TLabel;
    lbl2: TLabel;
    cbb1: TComboBox;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure trycn1Click(Sender: TObject);
    procedure mniSair1Click(Sender: TObject);
    procedure mnieste1Click(Sender: TObject);

    procedure updateStatus(status: TauthCP);
    procedure writeLog(log: string);
    procedure tmrMainTimer(Sender: TObject);
    procedure IdHTTP1Redirect(Sender: TObject; var dest: string; var NumRedirect: Integer; var Handled: Boolean; var VMethod: string);

    procedure btn1Click(Sender: TObject);
    procedure tmrGetAuthTimer(Sender: TObject);
    procedure autentica;
    procedure cbb1Select(Sender: TObject);

  private
    { Private declarations }
  public
    flagAuth: Boolean;  // estado de autenticação
    flagMain: Boolean;
    flagXhr : Boolean;
    flagIHttp:Boolean;
    flagLog:  Boolean;
    contAuth: Integer;
    contMain: Integer;
    log: TStringList;
//    tt: TCheck;
    xhr: TIdhttp;
  end;

var
  MainForm: TMainForm;
  closeForm : Boolean=false;
  stopThread: boolean=false;
implementation

{$R *.dfm}

function TWebbrowser.QueryStatus(CmdGroup: PGUID; cCmds: Cardinal; prgCmds: POleCmd; CmdText: POleCmdText): HResult; stdcall;
begin
  Result := S_OK;
end;

function TWebbrowser.Exec(CmdGroup: PGUID; nCmdID: Cardinal; nCmdexecopt: Cardinal; const vaIn: OleVariant; var vaOut: OleVariant): HResult; stdcall;
begin
  Result := S_OK;
  if nCmdID = OLECMDID_SHOWSCRIPTERROR then
  begin
    Result := S_OK;
  end;
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  cbb1.Items.Add('30 Minutos');
  cbb1.Items.Add('1 Hora');
  cbb1.Items.Add('2 Horas');
  cbb1.Items.Add('6 Horas');

//  checkUrl := 'http://www.sighra.com.br/maps/';

  webbrowser1.navigate(authUrl);
  flagAuth := False; // user autenticado
  flagMain := True;  // thread principal
  flagXhr  := False;

  flagLog  := true; // flag grava log em disco
  contAuth := 0;     // tentativas de login
  rp;

  tmrMain.Enabled := True;  // verifica o estado

//  tmrMain:
//    verifica se maquina não esta autenticada ou não
//    identifica redirect de authenticação ou bloqueio de url testada
//  tmrGetAuth:
//    verifica o resultado da tentativa de autenticação

end;

procedure TMainForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  sp;
  if not closeForm then
    begin
      MainForm.Hide;
      Action := caNone;
    end
  else
  begin
    if not MainForm.Visible then
    begin
      MainForm.Show;
    end
  end;
end;

procedure TMainForm.trycn1Click(Sender: TObject);
begin
  if not MainForm.Visible then
  begin
    MainForm.Show;
  end;
end;

procedure TMainForm.mniSair1Click(Sender: TObject);
begin
  tmrMain.Enabled := False;
  flagMain := False;
  closeForm := True;
  Close;
end;

procedure TMainForm.mnieste1Click(Sender: TObject);
begin
  if not MainForm.Visible then
  begin
    MainForm.Show;
  end;
end;

procedure TMainForm.updateStatus(status: TAuthCP);
begin
//  iconIndex
//  0 Azul
//  1 Verde
//  2 Vermelho
//  3 Amarelo
  case status of
    AUTH_YES:
    begin
      lbl2.Caption := 'Autenticado';
      writeLog('redirect: autenticado');
      trycn1.IconIndex := 1;
      flagAuth := True;      ;
    end;

    AUTH_NO:
    begin
      lbl2.Caption := 'Desautenticado';
      writeLog('redirect: desautenticado');
      trycn1.IconIndex := 2;
      flagAuth := False;
      if chk1.Checked then // mantém logado
      begin
        webbrowser1.Refresh;
        autentica;
        contAuth := 1; // primeira tentativa
        tmrGetAuth.Enabled := True; // tenta autenticar
      end;
    end;

    AUTH_UNDEFINED:
    begin
      writeLog('redirect: ??');
      lbl2.Caption := '--';
      trycn1.IconIndex := 3;
      flagAuth := False;
    end;
  else
    begin
//      label4.Caption := '';
      trycn1.IconIndex := 0;
    end;
  end;
end;

procedure TMainForm.writeLog(log: string);
var
  local: string;
  tFile: TextFile;
begin
  if flagLog then
  begin
//    local := 'log_'+FormatDateTime('YYYYMMDD_HHMMSS', Now)+'.txt';
    local := 'log.txt';
    Assignfile(tFile, local);
    if not FileExists(local) Then
      begin
        Rewrite(tFile);
      end
    else
    begin
      Append(tFile);
    end;
    Writeln(tFile, FormatDateTime('DD/MM/YYYY-HH:MM:SS', Now)+' - '+log);
    Closefile(tFile);
  end;
end;

procedure TMainForm.tmrGetAuthTimer(Sender: TObject);
var
  isAuth: string;
begin
  if flagAuth then  // autenticado ?
    begin
      writeLog('autenticado');
      tmrGetAuth.Enabled := False;
    end
  else
  begin
    inc(contAuth);
    if contAuth > 3 then  // 10 tentativas
    begin
      writeLog('3 Tentativas');
      tmrGetAuth.Enabled := False;
    end;

    isAuth := getElementValueById('isauth');

    if isAuth <> '' then
    begin
      lbl2.Caption := isAuth;
      writeLog('getAuth: '+isAuth);
      tmrGetAuth.Enabled := False;
      if isAuth = 'SUCCESS' then
        begin
          updateStatus(AUTH_YES);
        end
      else
      begin
        if isAuth = 'FAILURE' then //
        begin
          updateStatus(AUTH_NO);
        end;
      end
    end;
  end;
end;

procedure TMainForm.tmrMainTimer(Sender: TObject);
begin

//  tmrMain.Interval := 1800000; // meia hora
//  tmrMain.Interval := 3600000;
//  tmrMain.Interval := 10000;
  if cbb1.ItemIndex >= 0 then
    begin
      case cbb1.ItemIndex of
        0:
        begin
          tmrMain.Interval := 1800000;
        end;
        1:
        begin
          tmrMain.Interval := 3600000;
        end;
        2:
        begin
          tmrMain.Interval := 14400000;
        end;
        3:
        begin
          tmrMain.Interval := 43200000;
        end;
      end;
    end
  else
  begin
    tmrMain.Interval := 3600000;
  end;

  if flagMain then
  begin
    TThread.CreateAnonymousThread(
      procedure
      begin
        try
          flagMain := False;
          try
            idhttp1.Get(checkUrl);
          except
            on e:Exception do
            begin
              writeLog('exception: '+e.Message);
            end
          end;
        finally
//          idhttp1.Disconnect;
//          idhttp1.Free;
          flagMain := True;
        end;
      end
    ).Start;
  end;
end;

procedure TMainForm.IdHTTP1Redirect(Sender: TObject; var dest: string; var NumRedirect: Integer; var Handled: Boolean; var VMethod: string);
begin

  if TRegex.IsMatch(dest, authRegex) then
    begin
      // redirect da tela de autenticação
      updateStatus(AUTH_NO);
    end
  else
  begin
    if TRegex.IsMatch(dest, blockRegex) then
      begin
        // redirect de bloqueio
        updateStatus(AUTH_UNDEFINED);
      end
    else
    begin
      updateStatus(AUTH_YES);
    end;
  end;
end;

procedure TMainForm.btn1Click(Sender: TObject);
begin
  autentica;
  contAuth := 1; // primeira tentativa
  tmrGetAuth.Enabled := True; // tenta autenticar
end;

procedure TMainForm.cbb1Select(Sender: TObject);
begin
//  cbb1.Items.Add('30 Minutos');
//  cbb1.Items.Add('1 Hora');
//  cbb1.Items.Add('2 Horas');
//  cbb1.Items.Add('6 Horas');
  case cbb1.ItemIndex of
    0:
    begin
      tmrMain.Interval := 1800000;
    end;
    1:
    begin
      tmrMain.Interval := 3600000;
    end;
    2:
    begin
      tmrMain.Interval := 14400000;
    end;
    3:
    begin
      tmrMain.Interval := 43200000;
    end;
  end;
end;

procedure TMainForm.autentica;
var
  u: string;
  p: String;
begin
  executeScript(mainScript);

  if edit1.Text <> '' then
    begin
      u := '"'+edit1.Text+'"';
    end
  else
  begin
    writeLog('usuario errado');
    edit1.SetFocus;
    exit;
  end;

  if edit2.Text <> '' then
    begin
      p := '"'+edit2.Text+'"';
    end
  else
  begin
    writeLog('usuario errado');
    edit2.SetFocus;
    exit;
  end;
  executeScript('auth({id:'+u+', pass:'+p+'})');
  writeLog('auth()');
end;

end.
