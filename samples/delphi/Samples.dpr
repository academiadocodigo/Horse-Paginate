program Samples;

{$APPTYPE CONSOLE}
{$R *.res}

uses
  Horse,
  Horse.Paginate,
  Horse.Jhonson,
  DataSet.Serialize,
  System.JSON,
  System.SysUtils,
  DBClient;

begin
  THorse
    .Use(Paginate)
    .Use(Jhonson);

  THorse.Get('/ping',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      LDataSet: TClientDataSet;
    begin
      LDataSet := TClientDataSet.Create(nil);
      try
        LDataSet.LoadFromFile('items.xml');
        Res.Send<TJSONArray>(LDataSet.ToJsonArray);
      finally
        LDataSet.Free;
      end;
    end);

  THorse.Listen(9000);
end.
