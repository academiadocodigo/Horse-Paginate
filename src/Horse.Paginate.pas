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

procedure Middleware(Req: THorseRequest; Res: THorseResponse; Next: {$IF DEFINED(FPC)}TNextProc{$ELSE}TProc{$ENDIF});
function Paginate: THorseCallback;

implementation

uses
{$IF DEFINED(FPC)}
  Generics.Collections;
{$ELSE}
  System.Generics.Collections;
{$ENDIF}

function Paginate: THorseCallback;
begin
  Result := Middleware;
end;

procedure Middleware(Req: THorseRequest; Res: THorseResponse; Next: {$IF DEFINED(FPC)}TNextProc{$ELSE}TProc{$ENDIF});
var
  LWebResponse: {$IF DEFINED(FPC)}TResponse{$ELSE}TWebResponse{$ENDIF};
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
      LContent := Res.Content;
      if Assigned(LContent) and LContent.InheritsFrom({$IF DEFINED(FPC)}TJSONData{$ELSE}TJSONValue{$ENDIF}) then
      begin
        try
          LJsonArray := {$IF DEFINED(FPC)}TJSONData{$ELSE}TJSONValue{$ENDIF}(LContent) as TJSONArray;
          LPages := Trunc(LJsonArray.Count / LLimit.ToInteger) + Byte((LJsonArray.Count Mod  LLimit.ToInteger) <> 0);

          LNewJsonArray := TJsonArray.Create;
          for i := (LLimit.ToInteger * (LPage.ToInteger - 1)) to ((LLimit.ToInteger * LPage.ToInteger)) - 1 do
          begin
            if i < LJsonArray.Count then
              LNewJsonArray.{$IF DEFINED(FPC)}Add{$ELSE}AddElement{$ENDIF}(LJsonArray.Items[i].Clone as {$IF DEFINED(FPC)}TJSONData{$ELSE}TJSONValue{$ENDIF});
          end;
          LJsonObjectResponse := TJsonObject.Create;
          LJsonObjectResponse.{$IF DEFINED(FPC)}Add{$ELSE}AddPair{$ENDIF}('docs', LNewJsonArray);
          LJsonObjectResponse.{$IF DEFINED(FPC)}Add{$ELSE}AddPair{$ENDIF}('total', {$IF DEFINED(FPC)}LJsonArray.Count{$ELSE}TJSONNumber.Create(LJsonArray.Count){$ENDIF});
          LJsonObjectResponse.{$IF DEFINED(FPC)}Add{$ELSE}AddPair{$ENDIF}('limit', {$IF DEFINED(FPC)}LLimit.ToInteger{$ELSE}TJSONNumber.Create(LLimit.ToInteger){$ENDIF});
          LJsonObjectResponse.{$IF DEFINED(FPC)}Add{$ELSE}AddPair{$ENDIF}('page', {$IF DEFINED(FPC)}LPage.ToInteger{$ELSE}TJSONNumber.Create(LPage.ToInteger){$ENDIF});
          LJsonObjectResponse.{$IF DEFINED(FPC)}Add{$ELSE}AddPair{$ENDIF}('pages', {$IF DEFINED(FPC)}LPages{$ELSE}TJSONNumber.Create(LPages){$ENDIF});
          FreeAndNil(LContent);
          LWebResponse.Content := LJsonObjectResponse.{$IF DEFINED(FPC)}ToString{$ELSE}ToJSON{$ENDIF};
          Res.Send<{$IF DEFINED(FPC)}TJSONData{$ELSE}TJSONValue{$ENDIF}>(LJsonObjectResponse);
          LWebResponse.ContentType := Res.RawWebResponse.ContentType;
        except
        end;
      end;
    end;
  end;
end;

end.
