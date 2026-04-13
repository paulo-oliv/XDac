unit XLib.RESTClient.Exceptions;

interface

uses
  Rest.Types,
  Rest.Client;

type
  ERestApi = class(ERequestError)
  public
    constructor Create(const AResponse: TCustomRESTResponse; const AMsg: string); overload;
    constructor Create(const AStatusCode: Integer; const AStatusText, AResponseContent,
      AMsg: string); overload;
    function ToString: string; override;
  end;

implementation

uses
  System.SysUtils;

{ ERestApi }

constructor ERestApi.Create(const AResponse: TCustomRESTResponse; const AMsg: string);
begin
  if Assigned(AResponse) then
  begin
    Create(AResponse.StatusCode, AResponse.StatusText, AResponse.Content, AMsg);
  end
  else
  begin
    Create(-555, 'Sem resposta do servidor', 'Response not Assigned', AMsg);
  end;
end;

constructor ERestApi.Create(const AStatusCode: Integer; const AStatusText, AResponseContent,
  AMsg: string);
begin
  inherited Create(AStatusCode, AStatusText, AResponseContent);
  Message := AMsg + sLineBreak + Message;
end;

function ERestApi.ToString: string;
var
  LInner: Exception;
  LInnerMsg: string;
begin
  Result := '';
  LInner := Self;
  while LInner <> nil do
  begin
    LInnerMsg := LInner.Message.Trim;
    if LInnerMsg <> '' then
    begin
      if Pos(LInnerMsg, Result) <= 0 then
        Result := Result + sLineBreak + LInner.ClassName + ': ' + LInnerMsg;
    end;
    LInner := LInner.InnerException;
  end;

  Result := Result + sLineBreak + 'StatusCode: ' + IntToStr(StatusCode) + ' - ' + StatusText +
    sLineBreak + 'ResponseContent: ' + ResponseContent;
end;

end.
