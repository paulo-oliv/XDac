unit Json.Interfaces;

interface

uses
  System.Json;

type
  IJsonObject = interface
    ['{B7E6AD4E-301D-4435-B133-F22B14714163}']
    // function ToString: string;
    function ToJson: string;
    // procedure setJsonObject(const AJsonObject: TJSONObject);
    function getJsonObject: TJSONObject;
    property JsonObject: TJSONObject read getJsonObject { write setJsonObject };
  end;

  IJsonArray = interface
    ['{32F4009B-C0E3-4DA7-9AD3-CEB79BD74DA6}']
    // function ToString: string;
    function ToJson: string;
    function Clear: IJsonArray;
    function Count: Integer;
    function getJsonArray: TJSONArray;
    function Get(const AIndex: Integer): TJSONValue;
    property JsonArray: TJSONArray read getJsonArray;
    function Add(const AItem: string): IJsonArray;
    property Item[const Index: Integer]: TJSONValue read Get; Default;
  end;

  IJsonArrayObject<I: IJsonObject> = interface(IJsonArray)
    ['{5A1E2A78-DBEA-4C65-B611-5E16788450B1}']
    function GetItem(const AIndex: Integer): I;
    function AddItem(const AItem: I): I;
    function New: I;
    property Item[const Index: Integer]: I read GetItem; Default;
  end;

implementation

end.
