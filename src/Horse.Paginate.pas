unit Horse.Paginate;

interface

uses
  System.SysUtils,
  Horse,
  System.Classes,
  System.JSON,
  Web.HTTPApp;

procedure Middleware(Req: THorseRequest; Res: THorseResponse; Next: TProc);
function Paginate: THorseCallback; overload;

implementation

uses System.Generics.Collections;

function Paginate: THorseCallback; overload;
begin
  Result := Middleware;
end;

procedure Middleware(Req: THorseRequest; Res: THorseResponse; Next: TProc); overload;
var
  LWebResponse: TWebResponse;
  LContent: TObject;
  LJsonArray, LNewJsonArray: TJsonArray;
  LJsonObjectResponse: TJsonObject;
  LLimit: String;
  i: Integer;
  LPages: Double;
  LPage: String;
begin
  try
    Next;
  finally
    if Req.Headers['X-Paginate'] = 'true' then
    begin
      if not Req.Query.TryGetValue('limit', LLimit) then
        LLimit := '25';
      if not Req.Query.TryGetValue('page', LPage) then
        LPage := '1';
      LWebResponse := THorseHackResponse(Res).GetWebResponse;
      LContent := THorseHackResponse(Res).GetContent;
      if Assigned(LContent) and LContent.InheritsFrom(TJSONValue) then
      begin
        LJsonArray := TJSONValue(LContent) as TJsonArray;
        LPages := Trunc((LJsonArray.Count / LLimit.ToInteger) + 1);
        LNewJsonArray := TJsonArray.Create;
        for i := (LLimit.ToInteger * (LPage.ToInteger - 1)) to ((LLimit.ToInteger * LPage.ToInteger)) - 1 do
        begin
          if i < LJsonArray.Count then
            LNewJsonArray.AddElement(LJsonArray.Items[i].Clone as TJsonValue);
        end;
        LJsonObjectResponse := TJsonObject.Create;
        try
        LJsonObjectResponse
          .AddPair('docs', LNewJsonArray)
          .AddPair(TJsonPair.Create(TJSONString.Create('total'), TJSONNumber.Create(LJsonArray.Count)))
          .AddPair(TJsonPair.Create(TJSONString.Create('limit'), TJSONNumber.Create(LLimit.ToInteger)))
          .AddPair(TJsonPair.Create(TJSONString.Create('page'), TJSONNumber.Create(LPage.ToInteger)))
          .AddPair(TJsonPair.Create(TJSONString.Create('pages'), TJSONNumber.Create(LPages)));

          LWebResponse.Content := LJsonObjectResponse.ToJSON;
        finally
          LJsonObjectResponse.Free;
        end;
        LWebResponse.ContentType := 'application/json';
      end;
    end;
  end;
end;

end.
