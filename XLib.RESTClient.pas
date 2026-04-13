unit XLib.RESTClient;

interface

uses
  Json.Interfaces,
  REST.Client,
  REST.Authenticator.OAuth,
  Rest.Types;

//  System.JSON,
//  IPPeerClient,

type
  RestClient = interface
    ['{6D1047A0-DE1E-42C1-8D0F-6B744D630244}']
    function get: RestClient;
    function post: RestClient;
    function put: RestClient;
    function delete: RestClient;
    function path: RestClient;
    function prepare(const AEndPoint: string): RestClient;
    function authRequest(const AToken: string): RestClient; // overload;
    // function authRequest: RestClient; overload;
    function getBaseUrl: string;
    function getOAuth2: TOAuth2Authenticator;
    function getResponse: TCustomRESTResponse;
    procedure setBaseUrl(const ABaseUrl: string);

    function responseJsonObject: IJsonObject;
    function responseJsonArray: IJsonArray;
    // function responseJsonArrayObject: IJsonArrayObject<IJsonObject>;
    function addBody(const AJsonObject: IJsonObject): RestClient; overload;
    function addBody(const AJsonArray: IJsonArray): RestClient; overload;
    function addBody(const AJsonArrayObject: IJsonArrayObject<IJsonObject>): RestClient; overload;

    function disconnect: RestClient;

    property BaseURL: string read getBaseUrl write setBaseUrl;
    property Response: TCustomRESTResponse read getResponse;
  end;

  TInterfacedRest = class(TInterfacedObject, RestClient)
  strict private
    procedure normalizeBaseURL;
  strict protected
    FRequest: TRESTRequest;
    function getConnection: TCustomRESTClient;
    procedure setConnection(const AConnection: TCustomRESTClient);

    // function getRaiseExceptionOnNotSuccess: Boolean;
    // procedure setRaiseExceptionOnNotSuccess(const AValue: Boolean);

    function getBaseUrl: string;
    procedure setBaseUrl(const ABaseUrl: string);

    procedure setResponse(const AResponse: TCustomRESTResponse);
    function getResponse: TCustomRESTResponse;
    function getOAuth2: TOAuth2Authenticator;

    procedure addParamJson(const AJson: string);
    procedure addBodyJson(const AJson: string);

    procedure execute;

    procedure doRaise(const AMgs: string); virtual;
    procedure errorHandling; virtual;
  public
    function prepare(const AEndPoint: string): RestClient; virtual;
    function authRequest(const AToken: string): RestClient; overload;
    function authRequest: RestClient; overload;
    function get: RestClient; virtual;
    function post: RestClient; virtual;
    function put: RestClient; virtual;
    function delete: RestClient; virtual;
    function path: RestClient; virtual;
    constructor Create;
    destructor Destroy; override;
    class function New(const ABaseUrl: string): RestClient;

    function addParam(const AJsonObject: IJsonObject): RestClient; overload;
    function addParam(const AJsonArray: IJsonArray): RestClient; overload;
    function addParam(const AJsonArrayObject: IJsonArrayObject<IJsonObject>): RestClient; overload;

    function responseJsonObject: IJsonObject;
    function responseJsonArray: IJsonArray;
    // function ResponseJsonArrayObject: IJsonArrayObject<IJsonObject>;
    function addBody(const AJsonObject: IJsonObject): RestClient; overload;
    function addBody(const AJsonArray: IJsonArray): RestClient; overload;
    function addBody(const AJsonArrayObject: IJsonArrayObject<IJsonObject>): RestClient; overload;

    function disconnect: RestClient;

    function stringResponse: string;
    function Success: Boolean; virtual;
  const
    sMimeApplicationJSON = Rest.Types.CONTENTTYPE_APPLICATION_JSON;
  end;

implementation

uses
  System.SysUtils,
  System.Json,
  Json.Classes,
  XLib.RESTClient.Exceptions;

{ TInterfacedRest }

class function TInterfacedRest.New(const ABaseUrl: string): RestClient;
begin
  Result := TInterfacedRest.Create;
  Result.BaseURL := ABaseUrl;
end;

constructor TInterfacedRest.Create;
begin
  FRequest := TRESTRequest.Create(nil);
  FRequest.Accept := sMimeApplicationJSON;
  setResponse(TRESTResponse.Create(FRequest.Owner));

  FRequest.SynchronizedEvents := False;
  FRequest.BindSource.AutoActivate := False;
  FRequest.BindSource.AutoEdit := False;
  FRequest.BindSource.AutoPost := False;
  setConnection(TRESTClient.Create(FRequest.Owner));

  // setRaiseExceptionOnNotSuccess(True);
end;

procedure TInterfacedRest.setConnection(const AConnection: TCustomRESTClient);
begin
  FRequest.Client := AConnection;
  FRequest.Client.Accept := sMimeApplicationJSON;
  // 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8'
  // 'application/json, text/plain; q=0.9, text/html;q=0.8,'
  FRequest.Client.AcceptCharset := 'UTF-8'; // 'UTF-8, *;q=0.8'
  FRequest.Client.ContentType := sMimeApplicationJSON;
  FRequest.Client.HandleRedirects := True;
  // FRequest.Client.OnHTTPProtocolError := HTTPProtocolError;
end;

function TInterfacedRest.getBaseUrl: string;
begin
  Result := getConnection.BaseURL;
end;

procedure TInterfacedRest.setBaseUrl(const ABaseUrl: string);
begin
  getConnection.BaseURL := ABaseUrl;
end;

function TInterfacedRest.getResponse: TCustomRESTResponse;
begin
  Result := FRequest.Response;
end;

procedure TInterfacedRest.setResponse(const AResponse: TCustomRESTResponse);
begin
  FRequest.Response := AResponse;
end;

function TInterfacedRest.getConnection: TCustomRESTClient;
begin
  Result := FRequest.Client;
end;

function TInterfacedRest.getOAuth2: TOAuth2Authenticator;
begin
  if assigned(getConnection.Authenticator) then
    Result := TOAuth2Authenticator(getConnection.Authenticator)
  else
  begin
    getConnection.Authenticator := TOAuth2Authenticator.Create(FRequest.Owner);
    Result := TOAuth2Authenticator(getConnection.Authenticator);
    TOAuth2Authenticator(Result).ResponseType := TOAuth2ResponseType.rtTOKEN;
    TOAuth2Authenticator(Result).TokenType := TOAuth2TokenType.ttBEARER;
  end;
end;

function TInterfacedRest.authRequest: RestClient;
begin
  if not assigned(getConnection.Authenticator) then
    exit(nil);

  if getConnection.Authenticator is TOAuth1Authenticator then
    Result := authRequest(TOAuth1Authenticator(getConnection.Authenticator).AccessToken)
  else if getConnection.Authenticator is TOAuth2Authenticator then
    Result := authRequest(TOAuth2Authenticator(getConnection.Authenticator).AccessToken);
end;

function TInterfacedRest.authRequest(const AToken: string): RestClient;
const
  sHeaderAuthorization = 'Authorization';
begin
  Result := Self;

  FRequest.AddAuthParameter(sHeaderAuthorization, AToken, TRESTRequestParameterKind.pkHTTPHEADER, [poDoNotEncode]);
end;

function TInterfacedRest.addParam(const AJsonObject: IJsonObject): RestClient;
begin
  Result := Self;
  addParamJson(AJsonObject.ToJson);
end;

function TInterfacedRest.addParam(const AJsonArray: IJsonArray): RestClient;
begin
  Result := Self;
  addParamJson(AJsonArray.ToJson);
end;

function TInterfacedRest.addParam(const AJsonArrayObject: IJsonArrayObject<IJsonObject>): RestClient;
begin
  Result := Self;
  addParamJson(AJsonArrayObject.ToJson);
end;

procedure TInterfacedRest.addParamJson(const AJson: string);
begin
  with FRequest.Params.AddItem do
  begin
    Kind := TRESTRequestParameterKind.pkGETorPOST;
    ContentType := TRESTContentType.ctAPPLICATION_JSON;
    Value := AJson;
  end;
end;

function TInterfacedRest.addBody(const AJsonObject: IJsonObject): RestClient;
begin
  Result := Self;
  addBodyJson(AJsonObject.ToJson);
end;

function TInterfacedRest.addBody(const AJsonArray: IJsonArray): RestClient;
begin
  Result := Self;
  addBodyJson(AJsonArray.ToJson);
end;

function TInterfacedRest.addBody(const AJsonArrayObject: IJsonArrayObject<IJsonObject>): RestClient;
begin
  Result := Self;
  addBodyJson(AJsonArrayObject.ToJson);
end;

procedure TInterfacedRest.addBodyJson(const AJson: string);
begin
  FRequest.AddBody(AJson, TRESTContentType.ctAPPLICATION_JSON);
end;

function TInterfacedRest.get: RestClient;
begin
  Result := Self;
  FRequest.Method := TRESTRequestMethod.rmGET;
  execute;
end;

function TInterfacedRest.post: RestClient;
begin
  Result := Self;
  FRequest.Method := TRESTRequestMethod.rmPOST;
  normalizeBaseURL;
  execute;
end;

function TInterfacedRest.put: RestClient;
begin
  Result := Self;
  FRequest.Method := TRESTRequestMethod.rmPUT;
  execute;
end;

function TInterfacedRest.delete: RestClient;
begin
  Result := Self;
  FRequest.Method := TRESTRequestMethod.rmDELETE;
  execute;
end;

function TInterfacedRest.path: RestClient;
begin
  Result := Self;
  FRequest.Method := TRESTRequestMethod.rmPATCH;
  execute;
end;

procedure TInterfacedRest.normalizeBaseURL;
begin
  if (FRequest.Method = TRESTRequestMethod.rmPOST) and (copy(getBaseURL, length(getBaseURL)) <> '/') then
    getConnection.BaseURL := getBaseURL + '/';
end;

function TInterfacedRest.prepare(const AEndPoint: string): RestClient;
begin
  Result := Self;
  FRequest.ResetToDefaults;
  getResponse.ResetToDefaults;
  FRequest.Params.Clear;
  // FRequest.Client.ResetToDefaults;
  // FRequest.Client.Params.Clear;
  FRequest.Resource := AEndPoint;
end;

procedure TInterfacedRest.execute;
var
  s: string;
begin
  try
    s := '';
    for var i := 0 to FRequest.Params.Count - 1 do
      s := s + FRequest.Params[i].Name + FRequest.Params[i].Value;
    FRequest.Execute;
  except
    on E: Exception do
      DoRaise(E.Message);
  end;
  errorHandling;
end;

procedure TInterfacedRest.errorHandling;
begin
  if not Success then
    DoRaise(getResponse.ErrorMessage);
end;

procedure TInterfacedRest.doRaise(const AMgs: string);
begin
  // if (Response.StatusCode < 500) or FRequest.Client.RaiseExceptionOn500 then

  raise ERestApi.Create(getResponse, AMgs);
end;

function TInterfacedRest.stringResponse: string;
begin
  Result := 'Status Code: ' + IntToStr(getResponse.StatusCode);
  Result := Result + sLineBreak + getResponse.StatusText;
  Result := Result + sLineBreak + getResponse.Content;
end;

function TInterfacedRest.Success: Boolean;
begin
  Result := getResponse.Status.Success;
end;

function TInterfacedRest.responseJsonObject: IJsonObject;
begin
  Result := TInterfacedJson.Create(getResponse.JSONValue as TJSONObject)
end;

function TInterfacedRest.responseJsonArray: IJsonArray;
begin
  Result := TInterfacedJsonArray.Create(getResponse.JSONValue as TJSONArray)
end;

function TInterfacedRest.disconnect: RestClient;
begin
  Result := Self;
  getConnection.disconnect;
end;

destructor TInterfacedRest.Destroy;
begin
  try
    if assigned(getConnection.Authenticator) then
      getConnection.Authenticator.Free
  except
  end;
  try
    FRequest.Client.Free;
  except
  end;
  try
    FRequest.Response.Free;
  except
  end;
  try
    FRequest.Free;
  except
  end;
  try
    inherited
  except
  end;
end;

end.
