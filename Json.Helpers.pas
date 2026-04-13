unit Json.Helpers;

interface

uses
  System.Json;

const
  JSON_NULL = 'null';

type
  TJSONObjectHelper = class helper for TJSONObject
    procedure SetValue(const APath: string; const AValue: TJSONValue); overload;
    procedure SetValue(const APath: string; const AValue: string); overload;
    procedure SetValue(const APath: string; const AValue: Integer); overload;
    procedure SetValue(const APath: string; const AValue: Boolean); overload;
    procedure SetValue(const APath: string; const AValue: Double); overload;
    procedure SetValue(const APath: string; const AValue: Currency); overload;
    procedure SetValue(const APath: string; const AValue: Extended); overload;
    procedure SetValue(const APath: string; const AValue: Variant); overload;
    procedure SetValue(const APath: string; const AValue: TTime); overload;
    procedure SetValue(const APath: string; const AValue: TDate); overload;
    procedure SetValue(const APath: string; const AValue: TDateTime); overload;

    function Exists(const APath: string): Boolean; overload;
    function Exists(const APath: string; out AJsonValue: TJSONValue): Boolean; overload;
    function AsVariant(const APath: string): Variant;
    function AsString(const APath: string; const ADefault: string = ''): string;
    function AsJson(const APath: string; const ADefault: string = JSON_NULL): string;
    function AsDouble(const APath: string; const ADefault: Double = 0): Double;
    function AsCurrency(const APath: string; const ADefault: Currency = 0): Currency;
    function AsExtended(const APath: string; const ADefault: Extended = 0): Extended;
    function AsInteger(const APath: string; const ADefault: Integer = 0): Integer;
    function AsBoolean(const APath: string; const ADefault: Boolean = False): Boolean;
    function AsDate(const APath: string; const ADefault: TDate = 0): TDate;
    function AsTime(const APath: string; const ADefault: TTime = 0): TTime;
    function AsDateTime(const APath: string; const ADefault: TDateTime = 0): TDateTime;

    function GetArray(const APath: string): TJSONArray;
    function GetObject(const APath: string): TJSONObject;
  end;

implementation

uses
  System.Generics.Collections, // resolve Hint
  System.DateUtils,
  System.SysUtils,
  System.Variants;

procedure TJSONObjectHelper.SetValue(const APath: string; const AValue: TJSONValue);
var
  LCandidato: TJSONPair;
  I: Integer;
begin
  for I := 0 to Count - 1 do
  begin
    LCandidato := Pairs[I];
    if (LCandidato.JsonString.Value = APath) then
    begin
      LCandidato.JSONValue := AValue;
      Exit;
    end;
  end;
  AddPair(APath, AValue);
end;

procedure TJSONObjectHelper.SetValue(const APath: string; const AValue: string);
begin
  SetValue(APath, TJSONString.Create(AValue));
end;

procedure TJSONObjectHelper.SetValue(const APath: string; const AValue: Integer);
begin
  SetValue(APath, TJSONNumber.Create(AValue));
end;

procedure TJSONObjectHelper.SetValue(const APath: string; const AValue: Boolean);
begin
  SetValue(APath, TJSONBool.Create(AValue));
end;

procedure TJSONObjectHelper.SetValue(const APath: string; const AValue: Extended);
begin
  SetValue(APath, TJSONNumber.Create(AValue));
end;

procedure TJSONObjectHelper.SetValue(const APath: string; const AValue: Double);
begin
  SetValue(APath, TJSONNumber.Create(AValue));
end;

procedure TJSONObjectHelper.SetValue(const APath: string; const AValue: TDate);
begin
  SetValue(APath, TJSONString.Create(FormatDateTime('yyyy-MM-dd', AValue)));
end;

procedure TJSONObjectHelper.SetValue(const APath: string; const AValue: TTime);
begin
  SetValue(APath, TJSONString.Create(FormatDateTime('hh:mm:ss', AValue)));
end;

procedure TJSONObjectHelper.SetValue(const APath: string; const AValue: TDateTime);
begin
  SetValue(APath, TJSONString.Create(FormatDateTime('yyyy-MM-dd hh:mm:ss', AValue)));
end;

procedure TJSONObjectHelper.SetValue(const APath: string; const AValue: Currency);
begin
  SetValue(APath, TJSONNumber.Create(AValue));
end;

procedure TJSONObjectHelper.SetValue(const APath: string; const AValue: Variant);
begin
  case VarType(AValue) and VarTypeMask of
    varInt64, varSmallInt, varInteger, varSingle, varDouble, varCurrency:
      begin
        var
          f: Double;
        f := AValue;
        SetValue(APath, TJSONNumber.Create(f));
      end;
    varBoolean:
      SetValue(APath, TJSONBool.Create(AValue));
    { varEmpty, } varNull:
      SetValue(APath, TJSONNull.Create)
      // varDate:
      // varOleStr,
      // varDispatch,
      // varError,
      // varVariant,
      // varUnknown,
      // varByte,
      // varWord,
      // varLongWord,
      // varStrArg,
      // varString,
      // varAny,
      // VarTypeMask,
  else
    SetValue(APath, VarToStr(AValue));
  end;
end;

function TJSONObjectHelper.Exists(const APath: string): Boolean;
begin
  try
    Result := Values[APath] <> nil; // FindValue(APath)
  except
    Result := False;
  end;
end;

function TJSONObjectHelper.Exists(const APath: string; out AJsonValue: TJSONValue): Boolean;
begin
  try
    AJsonValue := Values[APath]; // FindValue(APath);
  except
    Exit(False);
  end;
  Result := AJsonValue <> nil;
end;

function TJSONObjectHelper.GetArray(const APath: string): TJSONArray;
var
  LJSONValue: TJSONValue;
begin
  if Exists(APath, LJSONValue) then
    Result := LJSONValue as TJSONArray
  else
  begin
    Result := TJSONArray.Create;
    AddPair(APath, Result);
  end;
end;

function TJSONObjectHelper.GetObject(const APath: string): TJSONObject;
var
  LJSONValue: TJSONValue;
begin
  if Exists(APath, LJSONValue) then
    Result := LJSONValue as TJSONObject
  else
  begin
    Result := TJSONObject.Create;
    AddPair(APath, Result);
  end;
end;

function TJSONObjectHelper.AsVariant(const APath: string): Variant;
var
  LJSONValue: TJSONValue;
begin
  Result := System.Variants.Null;
  if Exists(APath, LJSONValue) then
    try
      // if not GetValue(APath).Null then
      // if LJSONValue.Value <> JSON_NULL then
      if not(LJSONValue is TJSONNull) then
      begin
        Result := LJSONValue.GetValue<string>;
        // Result := LJSONValue.GetValue<Variant>; // EJSONException conversion from TJSONString to Variant is not supported
        // Result := LJSONValue.Value;
      end;
    except
    end;
end;

function TJSONObjectHelper.AsBoolean(const APath: string; const ADefault: Boolean = False): Boolean;
var
  LJSONValue: TJSONValue;
begin
  Result := ADefault;
  if Exists(APath, LJSONValue) then
    try
      if LJSONValue is TJSONNull then
        Result := ADefault
      else
        Result := GetValue<Boolean>(APath);
    except
    end;
end;

function TJSONObjectHelper.AsDate(const APath: string; const ADefault: TDate): TDate;
var
  LJSONValue: TJSONValue;
begin
  Result := ADefault;
  if Exists(APath, LJSONValue) then
    try
      if LJSONValue is TJSONNull then
        Result := ADefault
      else
        Result := GetValue<TDate>(APath);
    except
    end;
end;

function TJSONObjectHelper.AsTime(const APath: string; const ADefault: TTime): TTime;
var
  LJSONValue: TJSONValue;
begin
  Result := ADefault;
  if Exists(APath, LJSONValue) then
    try
      if LJSONValue is TJSONNull then
        Result := ADefault
      else
        Result := GetValue<TTime>(APath);
    except
    end;
end;

function TJSONObjectHelper.AsDateTime(const APath: string; const ADefault: TDateTime): TDateTime;
var
  LJSONValue: TJSONValue;
  LStrDateTime: string;
  LYear, LMonth, LDay, LHour, LMinute, LSecond, LMillisecond: Word;
begin
  Result := ADefault;
  if Exists(APath, LJSONValue) then
    try
      if LJSONValue is TJSONNull then
        Result := ADefault
      else
      begin
        LStrDateTime := LJSONValue.GetValue<string>;
        LYear := StrToInt(Copy(LStrDateTime, 1, 4));
        LMonth := StrToInt(Copy(LStrDateTime, 6, 2));
        LDay := StrToInt(Copy(LStrDateTime, 9, 2));
        LHour := StrToInt(Copy(LStrDateTime, 12, 2));
        LMinute := StrToInt(Copy(LStrDateTime, 15, 2));
        LSecond := StrToInt(Copy(LStrDateTime, 18, 2));
        LMillisecond := 0;
        Result := EncodeDateTime(LYear, LMonth, LDay, LHour, LMinute, LSecond, LMillisecond);
      end
    except
    end;
end;

function TJSONObjectHelper.AsCurrency(const APath: string; const ADefault: Currency): Currency;
var
  LJSONValue: TJSONValue;
begin
  Result := ADefault;
  if Exists(APath, LJSONValue) then
    try
      if LJSONValue is TJSONNull then
        Result := ADefault
      else
        Result := GetValue<Currency>(APath);
    except
    end;
end;

function TJSONObjectHelper.AsDouble(const APath: string; const ADefault: Double = 0): Double;
var
  LJSONValue: TJSONValue;
begin
  Result := ADefault;
  if Exists(APath, LJSONValue) then
    try
      if LJSONValue is TJSONNull then
        Result := ADefault
      else
        Result := GetValue<Double>(APath);
    except
    end;
end;

function TJSONObjectHelper.AsExtended(const APath: string; const ADefault: Extended): Extended;
var
  LJSONValue: TJSONValue;
begin
  Result := ADefault;
  if Exists(APath, LJSONValue) then
    try
      if LJSONValue is TJSONNull then
        Result := ADefault
      else
        Result := GetValue<Extended>(APath);
    except
    end;
end;

function TJSONObjectHelper.AsInteger(const APath: string; const ADefault: Integer): Integer;
var
  LJSONValue: TJSONValue;
begin
  Result := ADefault;
  if Exists(APath, LJSONValue) then
    try
      if LJSONValue is TJSONNull then
        Result := ADefault
      else
        Result := GetValue<Integer>(APath);
    except
    end;
end;

function TJSONObjectHelper.AsJson(const APath, ADefault: string): string;
var
  LJSONValue: TJSONValue;
begin
  Result := ADefault;
  if Exists(APath, LJSONValue) then
    try
      if LJSONValue is TJSONNull then
        Result := ADefault
      else
        Result := LJSONValue.Value; // LJSONValue.ToJSON;
    except
    end;
end;

function TJSONObjectHelper.AsString(const APath: string; const ADefault: string = ''): string;
var
  LJSONValue: TJSONValue;
begin
  Result := ADefault;
  if Exists(APath, LJSONValue) then
    try
      if LJSONValue is TJSONNull then
        Result := ADefault
      else
        Result := LJSONValue.GetValue<string>;
    except
    end;
end;

end.
