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
    procedure IdHTTP1Work(ASender: TObject; AWorkMode: TWorkMode;
      AWorkCount: Int64);

  private
    { Private declarations }
  public
    flagAuth: Boolean;  // estado de autenticação
    flagMain: Boolean;
    flagLog:  Boolean;
    contAuth: Integer;
    contMain: Integer;
    log: TStringList;
    tt: TCheck;
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

  webbrowser1.navigate(authUrl);
  flagAuth := False; // user autenticado
  flagMain := True;  // flag do timer principal
  flagLog  := true; // flag grava log em disco
  contAuth := 0;     // tentativas de login
  rp;

//  tmrMain:
//    verifica se maquina não esta autenticada ou não
//    identifica redirect de authenticação ou bloqueio de url testada
//  tmrGetAuth:
//    verifica o resultado da tentativa de autenticação

  tmrMain.Enabled := true;  // verifica o estado
//  tmrGetAuth.Enabled := False;

//  tt := TCheck.Create(
//    procedure
//    begin
//      while not stopThread do
//      begin
//        try
//          flagMain := False;
//          try
//            idhttp1.Get(checkUrl);
//          except
//            on e:Exception do
//            begin
//              writeLog('exception: '+e.Message);
//            end
//          end;
//          // verificação no redirect
//        finally
//          idhttp1.Disconnect;
//          idhttp1.Free;
//          flagMain := True;
//        end;
//
////        sleep(1800000);
//        sleep(2000);
//
//        if stopThread then
//        begin
//          tt.Terminate;
//          closeform := true;
//          close;
//        end;
//      end
//    end
//  );
//
//  tt.Start;
end;

procedure TMainForm.FormClose(Sender: TObject; var Action: TCloseAction);
var
  s :string;
  c: Cardinal;
begin
  sp;
  xhr.Disconnect;
  xhr.Free;
//  if not stopThread then
//  begin
//    stopThread := true;
//    closeForm := True;
//  end;

  if not closeForm then
  begin
    MainForm.Hide;
    Action := caNone;
  end
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
  closeForm := True;
  MainForm.Close;
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
var
  res: String;

begin
//  xhr := Tidhttp.Create(nil);
//  xhr.OnRedirect := IdHTTP1Redirect;
  tmrMain.Interval := 1800000; // meia hora
//  tmrMain.Interval := 3600000;
//  tmrMain.Interval := 10000;

//  if flagMain then
//  begin
//    TThread.CreateAnonymousThread(
//      procedure
//      begin
//        try
//          flagMain := False;
//          try
//            res := idhttp1.Get(checkUrl);
//          except
//            on e:Exception do
//            begin
//              writeLog('exception: '+e.Message);
//            end
//          end;
//          // verificação no redirect
//        finally
//          idhttp1.Disconnect;
////          idhttp1.Free;
//          flagMain := True;
//        end;
//      end
//    ).Start;
//  end;


  if flagMain then
  begin
    TThread.CreateAnonymousThread(
      procedure
//      var
//        xhr: TIdhttp;
      begin
        xhr := Tidhttp.Create(nil);
        try
          flagMain := False;
          try
            xhr.IOHandler := IdSSLIOHandlerSocketOpenSSL1;
            xhr.OnWork := IdHTTP1Work;
            xhr.OnRedirect := IdHTTP1Redirect;
            xhr.Get(checkUrl);
          except
            on e:Exception do
            begin
              writeLog('exception: '+e.Message);
            end
          end;
          // verificação no redirect
        finally
          xhr.Disconnect;
          xhr.Free;
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

procedure TMainForm.IdHTTP1Work(ASender: TObject; AWorkMode: TWorkMode; AWorkCount: Int64);
var
  i: Int64;
begin
  i := AWorkCount;

end;

procedure TMainForm.btn1Click(Sender: TObject);
begin
  autentica;
  contAuth := 1; // primeira tentativa
  tmrGetAuth.Enabled := True; // tenta autenticar
end;

procedure TMainForm.autentica;
var
  u: string;
  p: String;
  st: TStringList;
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
