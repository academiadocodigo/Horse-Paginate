program Project1;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  Horse,
  Horse.Paginate,
  Horse.Jhonson,
  System.JSON,
  DBClient,
  DataSet.Serialize;

var
  App: THorse;

begin
  App := THorse.Create(9000);
  App.Use(Paginate);
  App.Use(Jhonson);

  App.Get('/ping',
  procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
  var
    DataSet : TClientDataSet;
  begin
    DataSet := TClientDataSet.Create(nil);
    try
      DataSet.LoadFromFile('items.xml');
      Res.Send<TJsonArray>(DataSet.ToJsonArray);
    finally
      DataSet.Free;
    end;

  end);

  App.Start;
end.
