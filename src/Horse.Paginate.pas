unit Horse.Paginate;

{$IF DEFINED(FPC)}
  {$MODE DELPHI}{$H+}
{$ENDIF}

interface

uses
{$IF DEFINED(FPC)}
  SysUtils, fpjson, HTTPDefs,
{$ELSE}
  System.SysUtils, System.Classes, System.JSON, Web.HTTPApp,
{$ENDIF}
  Horse;

type
  THorsePaginateOption = (gpoDoNotIncludeSummary);
  THorsePaginateOptionSet = set of THorsePaginateOption;

const
  HORSE_PAGINATE_OPTION_ALL = [gpoDoNotIncludeSummary];

function Paginate: THorseCallback; overload;
function Paginate(APaginateOptions: THorsePaginateOptionSet): THorseCallback; overload;

implementation

uses
{$IF DEFINED(FPC)}
  Generics.Collections;
{$ELSE}
  System.Generics.Collections;
{$ENDIF}

var
  PaginateOptionSet: THorsePaginateOptionSet;

procedure Middleware(Req: THorseRequest; Res: THorseResponse; Next: {$IF DEFINED(FPC)}TNextProc{$ELSE}TProc{$ENDIF});
var
  LWebResponse: {$IF DEFINED(FPC)}TResponse{$ELSE}TWebResponse{$ENDIF};
  LJsonValueResponse: {$IF DEFINED(FPC)}TJSONData{$ELSE}TJSONValue{$ENDIF};
  LContent: TObject;
  LJsonArray, LNewJsonArray: TJSONArray;
  LJsonObjectResponse: TJSONObject;
  LLimit, LPage: string;
  I: Integer;
  LPages: Double;
begin
  try
    Next;
  finally
    if Req.Headers.ContainsKey('X-Paginate') and (LowerCase(Req.Headers['X-Paginate']) = 'true') then
    begin
      if not Req.Query.TryGetValue('limit', LLimit) then
        LLimit := '25';
      if not Req.Query.TryGetValue('page', LPage) then
        LPage := '1';

      LWebResponse := Res.RawWebResponse;
      if (Length(LWebResponse.Content) > 0 ) and (LWebResponse.ContentType.Contains('application/json')) then
      begin
        try
        {$IF DEFINED(FPC)}
          Res.Content(GetJSON(LWebResponse.Content));
        {$ELSE}
          Res.Content(TJSONValue.ParseJSONValue(LWebResponse.Content));
        {$ENDIF}
        except
        end;
      end;

      LContent := Res.Content;
      if Assigned(LContent) and LContent.InheritsFrom({$IF DEFINED(FPC)}TJSONData{$ELSE}TJSONValue{$ENDIF}) then
      begin
        try
          LJsonArray := {$IF DEFINED(FPC)}TJSONData{$ELSE}TJSONValue{$ENDIF}(LContent) as TJSONArray;
          LPages := Trunc(LJsonArray.Count / LLimit.ToInteger) + Byte((LJsonArray.Count Mod  LLimit.ToInteger) <> 0);

          LNewJsonArray := TJsonArray.Create;
          for I := (LLimit.ToInteger * (LPage.ToInteger - 1)) to ((LLimit.ToInteger * LPage.ToInteger)) - 1 do
          begin
            if I < LJsonArray.Count then
              LNewJsonArray.{$IF DEFINED(FPC)}Add{$ELSE}AddElement{$ENDIF}(LJsonArray.Items[I].Clone as {$IF DEFINED(FPC)}TJSONData{$ELSE}TJSONValue{$ENDIF});
          end;

          if (gpoDoNotIncludeSummary in PaginateOptionSet) then
            LJsonValueResponse := LNewJsonArray
          else
          begin
            LJsonObjectResponse := TJsonObject.Create;
            LJsonObjectResponse.{$IF DEFINED(FPC)}Add{$ELSE}AddPair{$ENDIF}('docs', LNewJsonArray);
            LJsonObjectResponse.{$IF DEFINED(FPC)}Add{$ELSE}AddPair{$ENDIF}('total', {$IF DEFINED(FPC)}LJsonArray.Count{$ELSE}TJSONNumber.Create(LJsonArray.Count){$ENDIF});
            LJsonObjectResponse.{$IF DEFINED(FPC)}Add{$ELSE}AddPair{$ENDIF}('limit', {$IF DEFINED(FPC)}LLimit.ToInteger{$ELSE}TJSONNumber.Create(LLimit.ToInteger){$ENDIF});
            LJsonObjectResponse.{$IF DEFINED(FPC)}Add{$ELSE}AddPair{$ENDIF}('page', {$IF DEFINED(FPC)}LPage.ToInteger{$ELSE}TJSONNumber.Create(LPage.ToInteger){$ENDIF});
            LJsonObjectResponse.{$IF DEFINED(FPC)}Add{$ELSE}AddPair{$ENDIF}('pages', {$IF DEFINED(FPC)}LPages{$ELSE}TJSONNumber.Create(LPages){$ENDIF});
            FreeAndNil(LContent);
            LJsonValueResponse := LJsonObjectResponse;
          end;

          //LWebResponse.Content := LJsonValueResponse.{$IF DEFINED(FPC)}ToString{$ELSE}ToJSON{$ENDIF};
          LWebResponse.Content := LJsonValueResponse.{$IF DEFINED(FPC)}AsJson{$ELSE}ToJSON{$ENDIF};
          Res.Send<{$IF DEFINED(FPC)}TJSONData{$ELSE}TJSONValue{$ENDIF}>(LJsonValueResponse);
          LWebResponse.ContentType := Res.RawWebResponse.ContentType;
        except
        end;
      end;
    end;
  end;
end;

function Paginate: THorseCallback; overload;
begin
  Result := Paginate([]);
end;

function Paginate(APaginateOptions: THorsePaginateOptionSet): THorseCallback;
begin
  PaginateOptionSet := APaginateOptions;
  Result := Middleware;
end;

end.
