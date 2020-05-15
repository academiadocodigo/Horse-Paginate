unit Horse.Paginate;

interface

uses
  System.SysUtils,
  Horse,
  System.Classes,
  System.JSON,
  Web.HTTPApp;

procedure Middleware(Req: THorseRequest; Res: THorseResponse; Next: TProc);
function Paginate : THorseCallback; overload;

implementation

function Paginate : THorseCallback; overload;
begin
  Result := Middleware;
end;

procedure Middleware(Req: THorseRequest; Res: THorseResponse; Next: TProc); overload;
var
  LWebResponse: TWebResponse;
  LContent: TObject;
  aJsonArray, NewJsonArray : TJsonArray;
  LLimit : String;
  i, x  : Integer;
  Pages : Double;
  Page : String;
begin
  try
    Next;
  finally
    if Req.Headers['X-Paginate'] = 'true' then
    begin
      if not Req.Query.TryGetValue('limit', LLimit) then LLimit := '25';
      if not Req.Query.TryGetValue('page', Page) then Page := '1';
      LWebResponse := THorseHackResponse(Res).GetWebResponse;
      LContent := THorseHackResponse(Res).GetContent;
      if Assigned(LContent) and LContent.InheritsFrom(TJSONValue) then
      begin
          aJsonArray := TJSONValue(LContent) as TJSONArray;
          Pages := Trunc((aJsonArray.Count / LLimit.ToInteger) + 1);
          NewJsonArray := TJSONArray.Create;
          for I := (LLimit.ToInteger * (Page.ToInteger-1)) to ((LLimit.ToInteger * Page.ToInteger) + LLimit.ToInteger) -2 do
          begin
            if I < aJsonArray.Count then
              NewJsonArray.AddElement(aJsonArray.Items[I]);
          end;
          LWebResponse.Content :=
            TJsonObject.Create
              .AddPair(
                'docs',
                NewJsonArray
              )
              .AddPair(TJsonPair.Create(TJSONString.Create('total'), TJSONNumber.Create(aJsonArray.Count)))
              .AddPair(TJsonPair.Create(TJSONString.Create('limit'), TJSONNumber.Create(LLimit.ToInteger)))
              .AddPair(TJsonPair.Create(TJSONString.Create('page'), TJSONNumber.Create(Page.ToInteger)))
              .AddPair(TJsonPair.Create(TJSONString.Create('pages'), TJSONNumber.Create(Pages)))
              .ToJSON;
            LWebResponse.ContentType := 'application/json';
      end;
    end;
  end;
end;

end.

