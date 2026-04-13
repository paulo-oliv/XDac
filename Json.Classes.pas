unit Json.Classes;

interface

uses
  Json.Interfaces,
  System.Json;

type
  TInterfacedJson = class(TInterfacedObject, IJsonObject)
  strict private
    FFreeJsonObject: Boolean;
    FJsonObject: TJSONObject;
    procedure FreeJsonObject;
  public
    function getJsonObject: TJSONObject;
    // procedure setJsonObject(const AJsonObject: TJSONObject);
    constructor Create(const AJsonValue: TJSONValue; const AAnswerable: Boolean = False);
      overload;
    constructor Create(const AJsonObject: TJSONObject; const AAnswerable: Boolean = False);
      overload;
    constructor Create(const AAnswerable: Boolean = True); overload;
    destructor Destroy; override;
    function ToString: string; override;
    function ToJson: string;
  end;

  TInterfacedJsonArray = class(TInterfacedObject, IJsonArray)
  strict protected
    FFreeJsonArray: Boolean;
    FJsonArray: TJSONArray;
    procedure FreeJsonArray;
    function Get(const AIndex: Integer): TJSONValue;
  public
    function ToString: string; override;
    function ToJson: string;
    function Count: Integer;
    function Clear: IJsonArray;
    function getJsonArray: TJSONArray;
    function Add(const AItem: string): IJsonArray;
    constructor Create(const AJsonArray: TJSONArray; const AAnswerable: Boolean = False); overload;
    constructor Create(const AJsonValue: TJSONValue; const AAnswerable: Boolean = False); overload;
    constructor Create(const AJson: string); overload;
    constructor Create; overload;
    destructor Destroy; override;
  end;

  TInterfacedJsonArrayObject<I: IJsonObject> = class abstract(TInterfacedJsonArray,
    IJsonArrayObject<I>)
  strict protected
    function CreateItem(const AJsonObject: TJSONObject): I; virtual; abstract;
  public
    function GetItem(const AIndex: Integer): I;
    function AddItem(const AItem: I): I;
    function New: I;
  end;

implementation

uses
  System.Generics.Collections // resolve Hint
    ;

{ TInterfacedJson }

{ procedure TInterfacedJson.setJsonObject(const AJsonObject: TJSONObject);
  begin
  FJsonObject := AJsonObject;
  end; }

constructor TInterfacedJson.Create(const AJsonObject: TJSONObject; const AAnswerable: Boolean);
begin
  inherited Create;
  FJsonObject := AJsonObject;
  if not Assigned(FJsonObject) then
    FJsonObject := TJSONObject.Create;

  FFreeJsonObject := AAnswerable;
  if FFreeJsonObject then
    FJsonObject.Owned := False;
end;

constructor TInterfacedJson.Create(const AAnswerable: Boolean);
begin
  Create(TJSONObject.Create, AAnswerable);
end;

constructor TInterfacedJson.Create(const AJsonValue: TJSONValue; const AAnswerable: Boolean);
begin
  Create(TJSONObject(AJsonValue), AAnswerable);
end;

procedure TInterfacedJson.FreeJsonObject;
begin
  if (FJsonObject <> nil) { and FJsonObject.GetOwned } then
    try
      if FFreeJsonObject then
        FJsonObject.Free;
      FJsonObject := nil;
    except
    end;
end;

destructor TInterfacedJson.Destroy;
begin
  FreeJsonObject;
  try
    inherited
  except
  end;
end;

function TInterfacedJson.getJsonObject: TJSONObject;
begin
  Result := FJsonObject;
end;

function TInterfacedJson.ToJson: string;
begin
  if Assigned(FJsonObject) then
    Result := FJsonObject.ToJson
  else
    Result := '';
end;

function TInterfacedJson.ToString: string;
begin
  if Assigned(FJsonObject) then
    Result := FJsonObject.ToString
  else
    Result := '';
end;

{ TInterfacedJsonArray<I> }

constructor TInterfacedJsonArray.Create(const AJsonArray: TJSONArray; const AAnswerable: Boolean);
begin
  inherited Create;
  FJsonArray := AJsonArray;
  if not Assigned(FJsonArray) then
    FJsonArray := TJSONArray.Create;
  FFreeJsonArray := AAnswerable;
  if FFreeJsonArray then
    FJsonArray.Owned := False;
end;

function TInterfacedJsonArray.Clear: IJsonArray;
begin
  Result := Self;
  while Count > 0 do
    FJsonArray.Remove(0);
end;

function TInterfacedJsonArray.Count: Integer;
begin
  Result := FJsonArray.Count;
end;

constructor TInterfacedJsonArray.Create(const AJson: string);
begin
  Create(TJSONObject.ParseJSONValue(
    // TEncoding.ASCII.GetBytes(
    AJson
    // ),0)
    ) as TJSONArray);
end;

constructor TInterfacedJsonArray.Create;
begin
  Create(TJSONArray.Create, True);
end;

constructor TInterfacedJsonArray.Create(const AJsonValue: TJSONValue; const AAnswerable: Boolean);
begin
  Create(TJSONArray(AJsonValue), AAnswerable);
end;

procedure TInterfacedJsonArray.FreeJsonArray;
begin
  if (FJsonArray <> nil) { and FJsonArray.GetOwned } then
    try
      if FFreeJsonArray then
        FJsonArray.Free;
      FJsonArray := nil;
    except
    end;
end;

destructor TInterfacedJsonArray.Destroy;
begin
  FreeJsonArray;
  try
    inherited
  except
  end;
end;

function TInterfacedJsonArray.getJsonArray: TJSONArray;
begin
  Result := FJsonArray;
end;

function TInterfacedJsonArray.ToJson: string;
begin
  if Assigned(FJsonArray) then
    Result := FJsonArray.ToJson
  else
    Result := '';
end;

function TInterfacedJsonArray.ToString: string;
begin
  if Assigned(FJsonArray) then
    Result := FJsonArray.ToString
  else
    Result := '';
end; 

function TInterfacedJsonArray.Add(const AItem: string): IJsonArray;
begin
  Result := Self;
  FJsonArray.Add(AItem);
end;

function TInterfacedJsonArray.Get(const AIndex: Integer): TJSONValue;
begin
  Result := FJsonArray.Items[AIndex];
end;

{ TInterfacedJsonArrayObject<I> }

function TInterfacedJsonArrayObject<I>.AddItem(const AItem: I): I;
begin
  Result := AItem;
  if Assigned(Result) then
  begin
    // Result.Answerable := False; // desenvolver
    FJsonArray.AddElement(Result.JsonObject);
  end;
end;

function TInterfacedJsonArrayObject<I>.GetItem(const AIndex: Integer): I;
begin
  Result := CreateItem(TJSONObject(FJsonArray.Items[AIndex]));
end;

function TInterfacedJsonArrayObject<I>.New: I;
begin
  Result := AddItem(CreateItem(TJSONObject.Create));
end;

end.
