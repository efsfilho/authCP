unit Unit2;

interface

uses
  Winapi.Windows, Winapi.Messages,
  SHDocVw, Winapi.Activex, MSHTML,
  System.SysUtils, System.Variants, System.Classes, System.RegularExpressions,
  IdBaseComponent, IdComponent, IdTCPConnection, IdTCPClient, idHttp,
  IdIOHandler, IdIOHandlerSocket, IdIOHandlerStack, IdSSL, IdSSLOpenSSL;

type
  TConfig = record
    authUrl: array [0..99]of byte;  // url de autenticacao
    checkUrl: array [0..99]of byte;  // url de check
    authRgx: array [0..99]of byte;
    blockRgx: array [0..99]of byte;  // padrao para redirect de bloqueio
    ip1: array [0..29]of byte;
    ip2: array [0..9]of byte;
    keep: Boolean;
    tout: Integer;
  end;
  TAuthCP = (AUTH_YES, AUTH_NO, AUTH_UNDEFINED);

  function executeScript(script: string): Boolean;
  function getElementValueById(Id : string):string;
  procedure writeConfig(config: TConfig);
  function readConfig: TConfig;

var
  template: array [0..447] of byte = (
    $25, $68, $74, $74, $70, $3a, $2f, $2f, $31, $30, $2e, $31, $32, $2e, $35, $2e, $32, $35, $34, $2f, $68, $6f, $74, $73,
    $70, $6f, $74, $2f, $50, $6f, $72, $74, $61, $6c, $4d, $61, $69, $6e, $00, $00, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff,
    $eb, $70, $35, $75, $47, $75, $35, $75, $00, $00, $00, $00, $00, $00, $00, $00, $c8, $11, $03, $00, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $00, $00, $00, $48, $13, $03, $00, $00, $00, $00, $00, $10, $60, $00, $80, $00, $00, $00, $00,
    $01, $00, $00, $00, $16, $68, $74, $74, $70, $3a, $2f, $2f, $77, $77, $77, $2e, $79, $6f, $75, $74, $75, $62, $65, $2e,
    $63, $6f, $6d, $00, $a0, $61, $6c, $77, $01, $00, $00, $00, $58, $f4, $19, $00, $00, $81, $36, $75, $59, $85, $af, $27,
    $fe, $ff, $ff, $ff, $44, $f2, $19, $00, $ef, $67, $35, $75, $c0, $db, $72, $73, $00, $00, $00, $00, $85, $00, $00, $00,
    $2c, $28, $04, $fe, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $10, $dd, $fd, $03, $88, $f4, $19, $00,
    $85, $00, $00, $00, $e8, $0e, $25, $02, $27, $5e, $5c, $44, $2b, $31, $30, $5c, $2e, $31, $32, $5c, $2e, $35, $5c, $2e,
    $32, $35, $34, $5c, $2f, $68, $6f, $74, $73, $70, $6f, $74, $5c, $2f, $50, $6f, $72, $74, $61, $6c, $4d, $61, $69, $6e,
    $88, $f4, $19, $00, $10, $dd, $fd, $03, $d0, $73, $56, $00, $70, $00, $00, $00, $55, $0d, $97, $ff, $00, $00, $2b, $02,
    $05, $00, $00, $00, $cd, $77, $5c, $00, $10, $dd, $fd, $03, $48, $11, $55, $00, $85, $00, $00, $00, $10, $dd, $fd, $03,
    $88, $f4, $19, $00, $29, $06, $01, $10, $38, $9d, $36, $02, $29, $5e, $5c, $44, $2b, $31, $30, $5c, $2e, $31, $32, $5c,
    $2e, $35, $5c, $2e, $32, $35, $34, $5c, $2f, $55, $73, $65, $72, $43, $68, $65, $63, $6b, $5c, $2f, $50, $6f, $72, $74,
    $61, $6c, $4d, $61, $69, $6e, $00, $00, $88, $f4, $19, $00, $10, $dd, $fd, $03, $04, $f4, $19, $00, $7c, $83, $54, $00,
    $85, $00, $00, $00, $01, $00, $00, $00, $10, $dd, $fd, $03, $00, $00, $2b, $02, $4a, $9d, $36, $02, $00, $00, $01, $00,
    $0a, $00, $04, $0e, $01, $00, $00, $00, $40, $33, $c3, $02, $6c, $0c, $59, $00, $00, $00, $00, $00, $ff, $ff, $ff, $ff,
    $00, $00, $00, $00, $00, $00, $10, $00, $a4, $1b, $00, $00, $05, $00, $00, $00, $68, $f3, $19, $00, $b7, $5b, $00, $75,
    $40, $33, $c3, $02, $00, $00, $00, $00, $00, $cb, $8d, $52, $ff, $ff, $ff, $ff
  );

  // $25, $68, $74, $74, $70, $3a, $2f, $2f, $31, $30, $2e, $31, $32, $2e, $35, $2e, $32, $35, $34, $2f, $68, $6f, $74, $73,
  // $70, $6f, $74, $2f, $50, $6f, $72, $74, $61, $6c, $4d, $61, $69, $6e, $00, $00, $00, $0b, $1d, $00, $02, $00, $04, $06,
  // $13, $00, $00, $00, $76, $01, $04, $73, $a6, $1c, $04, $1c, $48, $0f, $1f, $00, $06, $00, $07, $01, $a6, $1c, $00, $00,
  // $a6, $1c, $1c, $ff, $ff, $ff, $ff, $ff, $e0, $27, $00, $00, $70, $00, $00, $00, $48, $0f, $1f, $00, $00, $00, $00, $00,
  // $a6, $1c, $1c, $ff, $ff, $ff, $ff, $ff, $e0, $27, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $98, $52, $fe, $03,
  // $a6, $1c, $1c, $ff, $02, $00, $00, $00, $8e, $fe, $ff, $ff, $04, $1c, $04, $00, $00, $0b, $1d, $00, $b4, $04, $fe, $03,
  // $03, $00, $00, $00, $00, $00, $fe, $03, $35, $6f, $b0, $74, $95, $17, $01, $ea, $d0, $cf, $6e, $07, $a0, $00, $00, $80,
  // $00, $00, $00, $00, $a6, $1c, $04, $1c, $10, $00, $00, $00, $01, $00, $00, $00, $7f, $00, $00, $00, $04, $00, $00, $00,
  // $c0, $00, $fe, $03, $94, $02, $fe, $03, $27, $15, $6a, $75, $00, $00, $00, $00, $00, $00, $00, $00, $0a, $00, $05, $00,
  // $62, $00, $00, $40, $00, $00, $00, $00, $88, $08, $fe, $03, $00, $00, $00, $00, $28, $00, $00, $00, $00, $00, $15, $02,
  // $04, $00, $00, $00, $a8, $52, $fe, $03, $20, $00, $00, $00, $01, $00, $00, $00, $00, $50, $af, $02, $76, $03, $bd, $00,
  // $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $10, $00, $38, $2e, $00, $00, $05, $00, $00, $00,
  // $68, $f3, $19, $00, $b7, $5b, $6a, $75, $00, $50, $af, $02, $00, $00, $00, $00, $27, $92, $d6, $62, $15, $02, $00, $00,
  // $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $90, $52, $fe, $03, $00, $00, $00, $00, $fe, $ff, $ff, $ff,
  // $30, $f3, $19, $00, $00, $50, $f6, $76, $ff, $ff, $ff, $ff

  CGID_DocHostCommandHandler: PGUID;
  checkUrl: string = ''; // url pra testar
  authUrl: string = 'http://'+chr(49)+chr(48)+chr(46)+chr(49)+chr(50)+chr(46)+chr(53)+chr(46)+chr(50)+chr(53)+chr(52)+'/hotspot/PortalMain';
  authRgx: string =  '^\D+'+chr(49)+chr(48)+'\.12\.5\.'+chr(50)+chr(53)+chr(52)+'\/hotspot\/PortalMain';    // regex do hotpost
  blockRgx: string = '^\D+'+chr(49)+chr(48)+'\.12\.5\.'+chr(50)+chr(53)+chr(52)+'\/UserCheck\/PortalMain'; // regex do usercheck
  mainScript: string = ''; // js de autenticação
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

procedure writeConfig(config: TConfig);
var
  fs: TFileStream;
begin
  fs := TFileStream.Create('data.dat', fmCreate or fmOpenWrite);
  try
    fs.Write(config, sizeof(config));
  finally
    fs.Free;
  end;
end;

function readConfig:TConfig;
type
  PConfig = ^TConfig;
var
  fs: TFileStream;
  config: TConfig;
  pc: PConfig;
  fileName: String;
begin
  fileName := 'data.dat';

  if FileExists(fileName) then
    begin
      fs := TFileStream.Create('data.dat', fmOpenRead);
      try
        fs.Read(config, fs.size);
      finally
        fs.Free;
      end;
    end
  else
  begin
    pc := @config;
    CopyMemory(pc, @template, SizeOf(template));  // TODO arquivo aumentou
  end;
  result := config;
end;

end.
