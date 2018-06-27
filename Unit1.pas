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
//  TAuthCP = (AUTH_YES, AUTH_NO, AUTH_UNDEFINED, AUTH_DEFAULT);

  TMainForm = class(TForm)
    trycn1: TTrayIcon;
    btn1: TButton;
    pm1: TPopupMenu;
    mniSair1: TMenuItem;
    mnieste1: TMenuItem;
    WebBrowser1: TWebBrowser;
    Label1: TLabel;
    tmrAuthStatus: TTimer;
    tmrSetScript: TTimer;
    Label2: TLabel;
    Edit1: TEdit;
    Edit2: TEdit;
    IdHTTP1: TIdHTTP;
    IdSSLIOHandlerSocketOpenSSL1: TIdSSLIOHandlerSocketOpenSSL;
    Label3: TLabel;
    Label4: TLabel;
    tmrMain: TTimer;
    btn2: TButton;
    il1: TImageList;
    chk1: TCheckBox;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure trycn1Click(Sender: TObject);
    procedure mniSair1Click(Sender: TObject);
    procedure mnieste1Click(Sender: TObject);
    procedure activateForm(sta: Boolean);
    procedure updateStatus(status: TauthCP);
    procedure writeLog(log: string);

//    function execute(script: string): Boolean;
//    function getElementValueById(Id : string):string;
    procedure WebBrowser1NavigateComplete2(ASender: TObject; const pDisp: IDispatch; const URL: OleVariant);
    procedure tmrMainTimer(Sender: TObject);
    procedure IdHTTP1Redirect(Sender: TObject; var dest: string; var NumRedirect: Integer; var Handled: Boolean; var VMethod: string);

    procedure btn1Click(Sender: TObject);
    procedure btn2Click(Sender: TObject);
    procedure tmrSetScriptTimer(Sender: TObject);
    procedure tmrAuthStatusTimer(Sender: TObject);

  private
    { Private declarations }
  public
    flagAuth: Boolean;  // setados no create
    flagMain: Boolean;
    flagLog:  Boolean;
    contAuth: Integer;
    contMain: Integer;
    log: TStringList;
  end;

var
  MainForm: TMainForm;
  closeForm : Boolean=False;
//  CGID_DocHostCommandHandler: PGUID;
//
//  checkUrl: string = 'http://www.youtube.com';
//  authUrl: string = 'http://'+chr(49)+chr(48)+chr(46)+chr(49)+chr(50)+chr(46)+chr(53)+chr(46)+chr(50)+chr(53)+chr(52)+'/hotspot/PortalMain/';
//  authRegex: string =  '^\D+'+chr(49)+chr(48)+'\.12\.5\.'+chr(50)+chr(53)+chr(52)+'\/hotspot\/PortalMain';    // regex do hotpost
//  blockRegex: string = '^\D+'+chr(49)+chr(48)+'\.12\.5\.'+chr(50)+chr(53)+chr(52)+'\/UserCheck\/PortalMain'; // regex do usercheck

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
var
  st: TStringList;
begin

  flagAuth := False; // user autenticado
  flagMain := True;  // flag do timer principal
  flagLog  := true; // flag grava log em disco
  contAuth := 0;     // tentativas de login
  contMain := 0;     //
  log := TStringlist.Create;

//  tmrMain:
//    verifica se maquina n�o esta autenticada ou n�o
//    identifica redirect de authentica��o ou bloqueio de url testada
//  tmrSetScript:
//    tenta carregar o script inicial
//  tmrAuthStatus:
//    verifica o resultado da tentativa de autentica��o
  tmrMain.Enabled := False;
  tmrSetScript.Enabled := False;
  tmrAuthStatus.Enabled := False;

  st := rp;
  if st.Text <> '' then
    begin
//      chk1.Checked := strToBool(st[0]);
      edit1.Text := stringReplace(st[1],'"','',[rfReplaceAll]);
      edit2.Text := stringReplace(st[2],'"','',[rfReplaceAll]);
    end
  else
  begin

  end;
end;

procedure TMainForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if not closeForm then
  begin
    MainForm.Hide;
    Action := caNone;
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

procedure TMainForm.activateForm(sta: Boolean);
begin
  Edit1.Enabled := sta;
  Edit2.Enabled := sta;
  btn1.Enabled := sta;
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
      label4.Caption := 'On';
      trycn1.IconIndex := 1;
      flagAuth := True;
    end;
    AUTH_NO:
    begin
      label4.Caption := 'Off';
      trycn1.IconIndex := 2;
      flagAuth := False;
      if chk1.Checked then
      begin
        writelog('off');
        if not flagAuth then
        begin
          btn1.Click;
        end;
      end;
    end;
    AUTH_UNDEFINED:
    begin
      label4.Caption := '-';
      trycn1.IconIndex := 3;
      flagAuth := False;
    end;
    AUTH_DEFAULT:
    begin
      label4.Caption := '';
      trycn1.IconIndex := 0;
      flagAuth := False;
    end;
  else
    begin
      label4.Caption := '';
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
//    local := 'log'+DateTimeToStr(Now, 'DDMMAAHHMMSS');
    local := 'log_'+FormatDateTime('YYYYMMDD_HHMMSS', Now)+'.txt';


    Assignfile(tFile, local);
    if not FileExists(local) Then
      begin
        Rewrite(tFile);
      end
    else
    begin
      Append(tFile);
    end;
    Writeln(tFile, log);
    Closefile(tFile);
  end;
end;

//function TMainForm.execute(script: string): Boolean;
//var
//  win: IHTMLWindow2;
//  doc : IHTMLDocument2;
//begin
//  doc := webBrowser1.Document as IHTMLDocument2;
//  if Assigned(doc) then
//    begin
//      win := doc.parentWindow;
//      if script <> '' then
//        begin
//          Result := True;
//          try
//            win.ExecScript(script, Olevariant('JavaScript'));
//          except
//            on E:Exception do
//            begin
//              Result := False;
//            end;
//          end;
//        end
//      else
//      begin
//        Result := False;
//      end;
//    end
//  else
//  begin
//    Result := False;
//  end;
//end;

//function TMainForm.getElementValueById(Id : string):string;
//var
//  doc: IHTMLDocument2;
//  body: IHTMLElement2;
//  Tag      : IHTMLElement;
//  TagsList : IHTMLElementCollection;
//  Index    : Integer;
//begin
//  doc := webBrowser1.Document as IHTMLDocument2;
//  if doc = nil then
//  begin
//    exit;
//  end;
//
//  supports(doc.body, IHTMLElement2, body);
//  Result:='';
//
//  TagsList := body.getElementsByTagName('input');
//  for Index := 0 to TagsList.length-1 do
//  begin
//    Tag:=TagsList.item(Index, EmptyParam) As IHTMLElement;
//    if CompareText(Tag.id,Id) = 0 then
//    begin
//      Result := Tag.getAttribute('value', 0);
//    end;
//  end;
//end;

procedure TMainForm.WebBrowser1NavigateComplete2(ASender: TObject; const pDisp: IDispatch; const URL: OleVariant);
begin
  activateForm(True);
end;

procedure TMainForm.tmrAuthStatusTimer(Sender: TObject);
var
  isAuth: string;
begin
  isAuth := getElementValueById('isauth');
  if isAuth <> '' then
  begin
    label1.Caption := isAuth;

    tmrAuthStatus.Enabled := False;
    if isAuth = 'FAILURE' then
    begin
      activateForm(True);
    end;
  end;
end;

procedure TMainForm.tmrSetScriptTimer(Sender: TObject);
var
  mainScript: string;
begin
  mainScript := ''+
    'var isauth=document.createElement("input");function auth(e){var t="IID=-1&'+
    'UserOption=OK&UserID="+e.id+"&Password="+e.pass,a=new XMLHttpRequest;a.ope'+
    'n("POST","/hotspot/data/GetUserCheckUserChoiceData",!0),a.setRequestHeader'+
    '("Content-type","application/x-www-form-urlencoded"),a.onreadystatechange='+
    'function(){4==a.readyState&&(document.getElementById("isauth").value=JSON.'+
    'parse(a.responseText).ReturnCode)},a.send(t)}isauth.setAttribute("type","h'+
    'idden"),isauth.setAttribute("id","isauth"),isauth.setAttribute("value","")'+
    ',document.body.appendChild(isauth);';
  if executeScript(mainScript) then
  begin
    label2.Caption := 'Start';
    tmrSetScript.Enabled := False;
  end;
end;

procedure TMainForm.tmrMainTimer(Sender: TObject);
var
  res: String;
begin
//  tmrMain.Interval := 1800000; // meia hora
//  tmrMain.Interval := 3600000;
  tmrMain.Interval := 10000;
  if flagMain then
  begin
    TThread.CreateAnonymousThread(
      procedure
      begin
        try
          try
            flagMain := False;
            res := idhttp1.Get(checkUrl);
//            if idhttp1.ResponseCode = 200 then
//            begin
//              TThread.Synchronize(
//                nil,
//                procedure
//                begin
//                  updateStatus(AUTH_YES);
//                end
//              );
//              flagAuth := True;
//            end;
          finally
            idhttp1.Disconnect;
            flagMain := True;
          end;
        except
          on e:Exception do log.Add('except: '+e.Message);
        end;
      end
    ).Start;
  end;
end;

procedure TMainForm.IdHTTP1Redirect(Sender: TObject; var dest: string; var NumRedirect: Integer; var Handled: Boolean; var VMethod: string);
begin
  if TRegex.IsMatch(dest, authRegex) then
    begin
      // redirect da tela de autentica��o
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
var
  u: string;
  p: String;
  st: TStringList;
begin
  u := '"'+edit1.Text+'"';
  p := '"'+edit2.Text+'"';
  executeScript('auth({id:'+u+', pass:'+p+'})');
  if not tmrAuthStatus.Enabled then
  begin
    tmrAuthStatus.Enabled := true;
    label1.Caption := '...';
    activateForm(False);
  end;

  sp;
end;

procedure TMainForm.btn2Click(Sender: TObject);
begin
  activateForm(True);
  
end;

end.
