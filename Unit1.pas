unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.AppEvnts, Vcl.StdCtrls,
  Vcl.Menus, Vcl.OleCtrls, SHDocVw, Winapi.Activex, MSHTML, System.RegularExpressions,
  IdBaseComponent, IdComponent, IdTCPConnection, IdTCPClient, idHttp,
  IdIOHandler, IdIOHandlerSocket, IdIOHandlerStack, IdSSL, IdSSLOpenSSL;

type

  //  TWebBrowser = class(SHDocVw.TWebBrowser)
  TWebBrowser = class(SHDocVw.TWebBrowser, IOleCommandTarget)
  private
    function QueryStatus(CmdGroup: PGUID; cCmds: Cardinal; prgCmds: POleCmd; CmdText: POleCmdText): HResult; stdcall;
    function Exec(CmdGroup: PGUID; nCmdID, nCmdexecopt: DWORD; const vaIn: OleVariant; var vaOut: OleVariant): HResult; stdcall;
  end;

  TForm1 = class(TForm)
    trycn1: TTrayIcon;
    btn1: TButton;
    pm1: TPopupMenu;
    mniSair1: TMenuItem;
    mnieste1: TMenuItem;
    WebBrowser1: TWebBrowser;
    Label1: TLabel;
    tmrStatus: TTimer;
    tmrStart: TTimer;
    Label2: TLabel;
    Edit1: TEdit;
    Edit2: TEdit;
    IdHTTP1: TIdHTTP;
    IdSSLIOHandlerSocketOpenSSL1: TIdSSLIOHandlerSocketOpenSSL;
    Label3: TLabel;
    Label4: TLabel;
    tmrMain: TTimer;
    btn2: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure trycn1Click(Sender: TObject);
    procedure mniSair1Click(Sender: TObject);
    procedure mnieste1Click(Sender: TObject);
    procedure activateForm(sta: Boolean);

    function execute(script: string): Boolean;
    function getElementValueById(Id : string):string;
    procedure WebBrowser1NavigateComplete2(ASender: TObject; const pDisp: IDispatch; const URL: OleVariant);

    procedure startScript(sender: TObject);
    procedure tmrMainTimer(Sender: TObject);
    procedure tmrStatusTimer(Sender: TObject);
    procedure IdHTTP1Redirect(Sender: TObject; var dest: string; var NumRedirect: Integer; var Handled: Boolean; var VMethod: string);

    procedure btn1Click(Sender: TObject);
    procedure btn2Click(Sender: TObject);

  private
    { Private declarations }
  public
    mainAuth: Boolean;
    mainFlag: Boolean;
    log: TStringList;
  end;

var
  Form1: TForm1;
  closeForm : Boolean=False;
  CGID_DocHostCommandHandler: PGUID;

  authUrl: string = '';
  checkUrl: string = '';
  authRegex: string = '';  // regex do hotpost
  blockRegex: string = ''; //regex do usercheck

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

procedure TForm1.FormCreate(Sender: TObject);
var
  stlFile: TStrings;
  fStream: TFileStream;
begin
//  stlFile := TStringList.Create;
//  fStream := TFileStream.Create('C:Windowswin.ini', fmOpenRead);
//  stlFile.LoadFromStream(fStream);
//  Memo1.Lines.Assign(stlFile);
//  fStream.Free;
//  stlFile.Free;

  Form1.Hide;
  mainAuth := False;
  mainFlag := False;    // flag do timer principal
  log := TStringlist.Create;

//  icon := TIcon.Create;
//  icon.LoadFromFile('icons/lock_closed.ico');
//  trycn1.Icon.LoadFromFile('icons/lock_closed.ico');
end;

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if not closeForm then
  begin
    Form1.Hide;
    Action := caNone;
  end;
end;

procedure TForm1.trycn1Click(Sender: TObject);
begin
  if not Form1.Visible then
  begin
    Form1.Show;
  end;
end;

procedure TForm1.mniSair1Click(Sender: TObject);
begin
  closeForm := True;
  Form1.Close;
end;

procedure TForm1.mnieste1Click(Sender: TObject);
begin
  if not Form1.Visible then
  begin
    Form1.Show;
  end;
end;

procedure TForm1.activateForm(sta: Boolean);
begin
  Edit1.Enabled := sta;
  Edit2.Enabled := sta;
  btn1.Enabled := sta;
end;

function TForm1.execute(script: string): Boolean;
var
  win: IHTMLWindow2;
  doc : IHTMLDocument2;
begin
  doc := webBrowser1.Document as IHTMLDocument2;
  if Assigned(doc) then
  begin
    win := doc.parentWindow;
    if script <> '' then
      begin
        Result := True;
        try
          win.ExecScript(script, Olevariant('JavaScript'));
        except
          on E:Exception do
          begin
            Result := False;
          end;
        end;
      end
    else
    begin
      Result := False;
    end;
  end
  else
  begin
    Result := False;
  end;
end;

function TForm1.getElementValueById(Id : string):string;
var
  doc: IHTMLDocument2;
  body: IHTMLElement2;
  Tag      : IHTMLElement;
  TagsList : IHTMLElementCollection;
  Index    : Integer;
begin
  doc := webBrowser1.Document as IHTMLDocument2;
  if doc = nil then
  begin
    exit;
  end;

  supports(doc.body, IHTMLElement2, body);
  Result:='';

  TagsList := body.getElementsByTagName('input');
  for Index := 0 to TagsList.length-1 do
  begin
    Tag:=TagsList.item(Index, EmptyParam) As IHTMLElement;
    if CompareText(Tag.id,Id) = 0 then
    begin
      Result := Tag.getAttribute('value', 0);
    end;
  end;
end;

procedure TForm1.WebBrowser1NavigateComplete2(ASender: TObject; const pDisp: IDispatch; const URL: OleVariant);
begin
  activateForm(True);
end;

procedure TForm1.startScript(sender: TObject);
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
  if execute(mainScript) then
  begin
    label2.Caption := 'Start';
    tmrStart.Enabled := False;
  end;
end;

procedure TForm1.tmrMainTimer(Sender: TObject);
var
  res: String;
begin
//  tmrMain.Interval := 1800000; // meia hora
//  tmrMain.Interval := 3600000;
  if mainFlag then
  begin
    TThread.CreateAnonymousThread(
      procedure
      begin
        try
          try
            mainFlag := False;
            res := idhttp1.Get(checkUrl);
            if idhttp1.ResponseCode = 200 then
            begin
              TThread.Synchronize(
                nil,
                procedure
                begin
                  label4.Caption := 'ok';
                end
              );
              mainAuth := True;
            end;
          finally
            idhttp1.Disconnect;
            mainFlag := True;
          end;
        except
          on e:Exception do
          begin
            log.Add('except: '+e.Message);
          end
        end;
      end
    ).Start;
  end;

//  if mainAuth then
//    begin
//      mainFlag := True;
//    end
//  else
//  begin
//    mainFlag := False;
//
//  end;
end;

procedure TForm1.tmrStatusTimer(Sender: TObject);
var
  isAuth: string;
begin
  isAuth := getElementValueById('isauth');
  if isAuth <> '' then
  begin
    label1.Caption := isAuth;
    tmrStatus.Enabled := False;
    if isAuth = 'FAILURE' then
    begin
      activateForm(True);
    end;
  end;
end;

procedure TForm1.IdHTTP1Redirect(Sender: TObject; var dest: string; var NumRedirect: Integer; var Handled: Boolean; var VMethod: string);
var
  rgx: TRegex;
begin
  if rgx.IsMatch(dest, authRegex) then
    begin
      label4.Caption := 'no';
      mainAuth := False;
    end
  else
  begin
    if rgx.IsMatch(dest, blockRegex) then
      begin
        label4.Caption := '!!';
        mainAuth := True;
      end
    else
    begin
      label4.Caption := 'ok';
      mainAuth := True;
    end;
  end;
end;

procedure TForm1.btn1Click(Sender: TObject);
var
  user: string;
  pass: String;
begin
  user := '"'+edit1.Text+'"';
  pass := '"'+edit2.Text+'"';
  execute('auth({id:'+user+', pass:'+pass+'})');
  tmrStatus.Enabled := true;
  label1.Caption := '...';
  activateForm(False);
end;

procedure TForm1.btn2Click(Sender: TObject);
begin
  WebBrowser1.Navigate(authUrl);
  tmrStart.Enabled := True;
end;

end.
