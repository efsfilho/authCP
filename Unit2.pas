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
  procedure sp(u, p:string);
  function rp:TStringList;

var
  CGID_DocHostCommandHandler: PGUID;

  checkUrl: string = 'http://www.youtube.com';
  authUrl: string = 'http://'+chr(49)+chr(48)+chr(46)+chr(49)+chr(50)+chr(46)+chr(53)+chr(46)+chr(50)+chr(53)+chr(52)+'/hotspot/PortalMain/';
  authRegex: string =  '^\D+'+chr(49)+chr(48)+'\.12\.5\.'+chr(50)+chr(53)+chr(52)+'\/hotspot\/PortalMain';    // regex do hotpost
  blockRegex: string = '^\D+'+chr(49)+chr(48)+'\.12\.5\.'+chr(50)+chr(53)+chr(52)+'\/UserCheck\/PortalMain'; // regex do usercheck
  sBin: string = 'sBin';

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

procedure sp(u, p: string);
var
  st: TStringList;
begin
  st := TStringList.Create;
  st.Add(checkUrl);
  st.Add(u);
  st.Add(p);
  st.Add(authUrl);
  st.Add(authRegex);
  st.Add(blockRegex);
  st.Text := StringOf(TEncoding.Convert(TEncoding.Unicode, TEncoding.UTF8, BytesOf(st.Text)));
  st.SaveToFile(sBin);
end;

function rp:TStringList;
var
  st: TStringList;
begin
  st := TStringList.Create;
  if FileExists(sBin) then
  begin
    st.LoadFromFile(sBin);
    st.Text := StringOf(TEncoding.Convert(TEncoding.UTF8, TEncoding.Unicode, BytesOf(st.Text)));
  end;
  result := st;
end;

end.
