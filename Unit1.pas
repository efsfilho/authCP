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
    edtAuthUrl: TEdit;
    edtCheckUrl: TEdit;
    edtAuthRgx: TEdit;
    edtBlockRgx: TEdit;
    procedure exec(src: string);
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
//    procedure tmrAuthenticatorTimer(Sender: TObject);
    procedure autentica;
    procedure verifica;
    procedure cbb1Select(Sender: TObject);

    procedure saveConfig;
    procedure loadConfig;
    procedure edtAuthUrlChange(Sender: TObject);
    procedure edtCheckUrlChange(Sender: TObject);
    procedure edtAuthRgxChange(Sender: TObject);
    procedure edtBlockRgxChange(Sender: TObject);

  private

  public
//    flagAuth: Boolean;  // estado de autenticação
//    flagMain: Boolean;
//    flagXhr : Boolean;
//    flagIHttp:Boolean;
    flagLog:  Boolean;
    contAuth: Integer;
//    contMain: Integer;
//    log: TStringList;

  end;

var
  MainForm: TMainForm;
  closeForm : Boolean = false;

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

procedure TMainForm.exec(src: string);
begin
  executeScript(src);
end;

procedure TMainForm.FormCreate(Sender: TObject);
var
  resource: TResourceStream;
  auth_script: TStringlist;
  i: integer;
begin
  loadConfig; // carrega perfil
  auth_script := TStringList.Create;
  resource := TResourceStream.Create(hInstance, 'auth_script', 'RT_STRING');
  try
    auth_script.LoadFromStream(resource);
    for i := 0 to auth_script.Count-1 do
    begin
      if auth_script[i] <> '' then
      begin
        mainScript := mainScript+' '+auth_script[i];
      end;
    end;
  finally
    auth_script.Free;
    resource.Free;
  end;

  webbrowser1.navigate(authUrl);
  tmrMain.Interval := 3000;  // verifica usuario

  flagLog := true;
  contAuth := 0;
end;

procedure TMainForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
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
//  flagMain := False;
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
      contAuth := 0;
    end;

    AUTH_NO:
    begin
      lbl2.Caption := 'Desautenticado';
      writeLog('redirect: desautenticado');
      trycn1.IconIndex := 2;

      if chk1.Checked then // mantém logado
      begin
        if contAuth < 5 then
          begin
            webbrowser1.Refresh;
            autentica;
            Inc(contAuth); // primeira tentativa
          end
        else
        begin
          contAuth := 0;
        end;
      end;
    end;

    AUTH_UNDEFINED:
    begin
      writeLog('redirect: ??');
      lbl2.Caption := '--';
      trycn1.IconIndex := 3;
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
    Writeln(tFile, formatDateTime('DD/MM/YYYY-HH:MM:SS', Now)+' - '+log);
    Closefile(tFile);
  end;
end;

//procedure TMainForm.tmrAuthenticatorTimer(Sender: TObject);
//var
//  isAuth: string;
//begin
//  if flagAuth then  // autenticado ?
//    begin
//      writeLog('autenticado');
//      tmrAuthenticator.Enabled := False;
//    end
//  else
//  begin
//    inc(contAuth);
//    if contAuth > 3 then  // 10 tentativas
//    begin
//      writeLog('3 Tentativas');
//      tmrAuthenticator.Enabled := False;
//    end;
//
//    isAuth := getElementValueById('isauth');
//
//    if isAuth <> '' then
//    begin
//      lbl2.Caption := isAuth;
//      writeLog('getAuth: '+isAuth);
//      tmrAuthenticator.Enabled := False;
//      if isAuth = 'SUCCESS' then
//        begin
//          updateStatus(AUTH_YES);
//        end
//      else
//      begin
//        if isAuth = 'FAILURE' then //
//        begin
//          updateStatus(AUTH_NO);
//        end;
//      end
//    end;
//  end;
//end;

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

  // verifica autenticação apos o get, no redirect (IdHTTP1Redirect)
  TThread.CreateAnonymousThread(
    procedure
    begin
      try
        idhttp1.Get(checkUrl);
      except
        on e:Exception do
        begin
          writeLog('exception: '+e.Message);
        end
      end;
    end
  ).Start;
end;

procedure TMainForm.IdHTTP1Redirect(Sender: TObject; var dest: string; var NumRedirect: Integer; var Handled: Boolean; var VMethod: string);
begin
  if TRegex.IsMatch(dest, authRgx) then
    begin
      // redirect da tela de autenticação
      updateStatus(AUTH_NO);
    end
  else
  begin
    if TRegex.IsMatch(dest, blockRgx) then
      begin
        // redirect de bloqueio
        updateStatus(AUTH_UNDEFINED);
      end
    else
    begin
      // redirecionado para o endereco original(autenticado?)
      updateStatus(AUTH_YES);
    end;
  end;
end;

procedure TMainForm.btn1Click(Sender: TObject);
begin
  autentica;
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

procedure TMainForm.edtAuthRgxChange(Sender: TObject);
begin
  authRgx := edtAuthRgx.Text;
end;

procedure TMainForm.edtAuthUrlChange(Sender: TObject);
begin
  authUrl := edtAuthUrl.Text;
end;

procedure TMainForm.edtBlockRgxChange(Sender: TObject);
begin
  blockRgx := edtBlockRgx.Text;
end;

procedure TMainForm.edtCheckUrlChange(Sender: TObject);
begin
  checkUrl := edtcheckUrl.Text;
end;

procedure TMainForm.autentica;
var
  u: string;
  p: String;
begin
//  exec(mainScript);
  if edit1.Text <> '' then
    begin
      u := '"'+edit1.Text+'"';
    end
  else
  begin
    writeLog('Usuario em branco!');
    edit1.SetFocus;
    exit;
  end;

  if edit2.Text <> '' then
    begin
      p := '"'+edit2.Text+'"';
    end
  else
  begin
    writeLog('Senha em branco!');
    edit2.SetFocus;
    exit;
  end;

  exec('auth({id:'+u+', pass:'+p+'})');

  if not tmrMain.Enabled then
  begin
    tmrMain.Enabled := True;
  end;

//  tmrMain.Interval := 3000;
  writeLog('auth()');
end;

procedure TMainForm.verifica;
var
  isAuth: String;
begin
  isAuth := getElementValueById('isauth');

  TThread.CreateAnonymousThread(
    procedure
    begin
      try
        sleep(3000);
        if isAuth <> '' then
        begin
          lbl2.Caption := isAuth;
          writeLog('verifica: '+isAuth);

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
      except
        on e:Exception do
        begin
          writeLog('exception: '+e.Message);
        end
      end;
    end
  ).Start;
end;

procedure TMainForm.saveConfig;
var
  config: TConfig;
  i: Integer;
  enc :TBytes;
begin
  config.keep := chk1.Checked;   // mantém
  config.tout := cbb1.ItemIndex; // timeout

  // usuario
  enc := TEncoding.UTF8.GetBytes(edit1.Text);
  config.ip1[0] := TEncoding.UTF8.GetCharCount(enc);
  if config.ip1[0] > length(config.ip1) then
    begin
      exit;
    end
  else
  begin
    for I := Low(enc) to High(enc) do
    begin
      config.ip1[i+1] := enc[i];
    end;
  end;

  // senha
  enc := TEncoding.UTF8.GetBytes(edit2.Text);
  config.ip2[0] := TEncoding.UTF8.GetCharCount(enc);
  if config.ip2[0] > length(config.ip2) then
    begin
      exit;
    end
  else
  begin
    for I := Low(enc) to High(enc) do
    begin
      config.ip2[i+1] := enc[i];
    end;
  end;

//  enc := TEncoding.UTF8.GetBytes('http://10.12.5.254/hotspot/PortalMain');
  enc := TEncoding.UTF8.GetBytes(authUrl);
  config.authUrl[0] := TEncoding.UTF8.GetCharCount(enc);
  // TODO validação decente
  if config.authUrl[0] > length(config.authUrl) then
    begin
      exit;
    end
  else
  begin
    for I := Low(enc) to High(enc) do
    begin
      config.authUrl[i+1] := enc[i];
    end;
  end;

  // url de teste
  enc := TEncoding.UTF8.GetBytes(checkUrl);
  config.checkUrl[0] := TEncoding.UTF8.GetCharCount(enc);
  if config.checkUrl[0] > length(config.checkUrl) then
    begin
      exit;
    end
  else
  begin
    for I := Low(enc) to High(enc) do
    begin
      config.checkUrl[i+1] := enc[i];
    end;
  end;

  // expressão de autenticação
  enc := TEncoding.UTF8.GetBytes(authRgx);
  config.authRgx[0] := TEncoding.UTF8.GetCharCount(enc);
  if config.authRgx[0] > length(config.authRgx) then
    begin
      exit;
    end
  else
  begin
    for I := Low(enc) to High(enc) do
    begin
      config.authRgx[i+1] := enc[i];
    end;
  end;

  // expressão de bloqueio
  enc := TEncoding.UTF8.GetBytes(blockRgx);
  config.blockRgx[0] := TEncoding.UTF8.GetCharCount(enc);
  if config.blockRgx[0] > length(config.blockRgx) then
    begin
      exit;
    end
  else
  begin
    for I := Low(enc) to High(enc) do
    begin
      config.blockRgx[i+1] := enc[i];
    end;
  end;

  writeConfig(config);
end;

procedure TMainForm.loadConfig;
var
  config: TConfig;
  i: Integer;
  dec: TBytes;
begin
  config := readConfig();

  chk1.Checked := config.keep;
  cbb1.ItemIndex := config.tout;

  // usuario
  setlength(dec, config.ip1[0]);
  for I := 1 to config.ip1[0] do
  begin
    dec[i-1] := config.ip1[i];
  end;
  edit1.Text := TEncoding.UTF8.GetString(dec);

  // senha
  setlength(dec, config.ip2[0]);
  for I := 1 to config.ip2[0] do
  begin
    dec[i-1] := config.ip2[i];
  end;
  edit2.Text := TEncoding.UTF8.GetString(dec);


  setlength(dec, config.authUrl[0]);
  for I := 1 to config.authUrl[0] do
  begin
    dec[i-1] := config.authUrl[i];
  end;
  edtAuthUrl.Text := TEncoding.UTF8.GetString(dec);

  setlength(dec, config.checkUrl[0]);
  for I := 1 to config.checkUrl[0] do
  begin
    dec[i-1] := config.checkUrl[i];
  end;
  edtCheckUrl.Text := TEncoding.UTF8.GetString(dec);

  setlength(dec, config.authRgx[0]);
  for I := 1 to config.authRgx[0] do
  begin
    dec[i-1] := config.authRgx[i];
  end;
  edtAuthRgx.Text := TEncoding.UTF8.GetString(dec);

  setlength(dec, config.blockRgx[0]);
  for I := 1 to config.blockRgx[0] do
  begin
    dec[i-1] := config.blockRgx[i];
  end;
  edtBlockRgx.Text := TEncoding.UTF8.GetString(dec);
end;
end.
