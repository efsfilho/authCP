unit Unit2;

interface

uses
  Winapi.Windows, Winapi.Messages,
  SHDocVw, Winapi.Activex, MSHTML,
  System.SysUtils, System.Variants, System.Classes, System.RegularExpressions,
  IdBaseComponent, IdComponent, IdTCPConnection, IdTCPClient, idHttp,
  IdIOHandler, IdIOHandlerSocket, IdIOHandlerStack, IdSSL, IdSSLOpenSSL;

type

  TAuthCP = (AUTH_YES, AUTH_NO, AUTH_UNDEFINED, AUTH_DEFAULT);

  function executeScript(script: string): Boolean;
  function getElementValueById(Id : string):string;
  procedure sp;
  function rp:TStringList;
  function stringToHex(S: String): string;
  function hexToString(H: String): String;

var
  CGID_DocHostCommandHandler: PGUID;

  checkUrl: string = 'http://www.youtube.com';
  authUrl: string = 'http://'+chr(49)+chr(48)+chr(46)+chr(49)+chr(50)+chr(46)+chr(53)+chr(46)+chr(50)+chr(53)+chr(52)+'/hotspot/PortalMain/';
  authRegex: string =  '^\D+'+chr(49)+chr(48)+'\.12\.5\.'+chr(50)+chr(53)+chr(52)+'\/hotspot\/PortalMain';    // regex do hotpost
  blockRegex: string = '^\D+'+chr(49)+chr(48)+'\.12\.5\.'+chr(50)+chr(53)+chr(52)+'\/UserCheck\/PortalMain'; // regex do usercheck
  sBin: string = 'sBin';

  mainScript: string = ''+
    'var isauth=document.createElement("input");function auth(e){var t="IID=-1&'+
    'UserOption=OK&UserID="+e.id+"&Password="+e.pass,a=new XMLHttpRequest;a.ope'+
    'n("POST","/hotspot/data/GetUserCheckUserChoiceData",!0),a.setRequestHeader'+
    '("Content-type","application/x-www-form-urlencoded"),a.onreadystatechange='+
    'function(){4==a.readyState&&(document.getElementById("isauth").value=JSON.'+
    'parse(a.responseText).ReturnCode)},a.send(t)}isauth.setAttribute("type","h'+
    'idden"),isauth.setAttribute("id","isauth"),isauth.setAttribute("value","")'+
    ',document.body.appendChild(isauth);';

implementation

uses
  Unit1;

function executeScript(script: string): Boolean;
var
  win: IHTMLWindow2;
  doc : IHTMLDocument2;
begin
  doc := MainForm.webBrowser1.Document as IHTMLDocument2;
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

function getElementValueById(id : string):string;
var
  doc: IHTMLDocument2;
  body: IHTMLElement2;
  Tag      : IHTMLElement;
  TagsList : IHTMLElementCollection;
  Index    : Integer;
begin
  doc := MainForm.webBrowser1.Document as IHTMLDocument2;
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

procedure sp;
var
  st: TStringList;
  BinaryStream: TMemoryStream;
  HexStr: string;
begin
  st := TStringList.Create;
  st.Add(BoolToStr(MainForm.chk1.Checked));
  st.Add(MainForm.edit1.Text);
  st.Add(MainForm.edit2.Text);
  st.Add(authUrl);
  st.Add(authRegex);
  st.Add(blockRegex);
  st.Text := StringOf(TEncoding.Convert(TEncoding.Unicode, TEncoding.UTF8, BytesOf(st.Text)));
  st.SaveToFile(sBin);
end;

function rp:TStringList;
var
  st: TStringList;
  stream: TMemoryStream;
  str: string;
  b: byte;
  p: Pointer;
begin
  st := TStringList.Create;
  if FileExists(sBin) then
  begin
    st.LoadFromFile(sBin);
    st.Text := StringOf(TEncoding.Convert(TEncoding.UTF8, TEncoding.Unicode, BytesOf(st.Text)));
  end;

  if st.Text <> '' then
  begin
//      mainForm.chk1.Checked := strToBool(st[0]);
    mainForm.edit1.Text := stringReplace(st[1],'"','',[rfReplaceAll]);
    mainForm.edit2.Text := stringReplace(st[2],'"','',[rfReplaceAll]);
  end;

  result := st;
end;

function stringToHex(S: String): string;
var I: Integer;
begin
  Result:= '';
  for I := 1 to length (S) do
  begin
    Result:= Result+IntToHex(ord(S[i]),2);
  end;
end;

function hexToString(H: String): String;
var I: Integer;
begin
  Result:= '';
  for I := 1 to length(H) div 2 do
  begin
    Result:= Result+Char(StrToInt('$'+Copy(H,(I-1)*2+1,2)));
  end;
end;

end.
