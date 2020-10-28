program Samples;

{$MODE DELPHI}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Horse, Horse.Paginate, Horse.Jhonson, DataSet.Serialize, SysUtils, fpjson, memds;

procedure GetPing(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  LDataSet: {$IF DEFINED(FPC)}TMemDataset{$ELSE}TClientDataSet{$ENDIF};
begin
  LDataSet := {$IF DEFINED(FPC)}TMemDataset.Create(nil){$ELSE}TClientDataSet.Create(nil){$ENDIF};
  try
    LDataSet.LoadFromFile('items.xml');
    Res.Send<TJSONArray>(LDataSet.ToJSONArray());
  finally
    LDataSet.Free;
  end;
end;

procedure OnListen(Horse: THorse);
begin
  Writeln(Format('Server is runing on %s:%d', [Horse.Host, Horse.Port]));
end;

begin
  THorse
    .Use(Paginate)
    .Use(Jhonson);

  THorse.Get('/ping', GetPing);

  THorse.Listen(9000, OnListen);
end.
