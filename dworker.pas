unit dworker;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,DataAccess, SQLDB, BufDataset, DB, Variants,Da_table;

type

  { TWorker }

  TWorker = class(TDA_table)

  private

  public


        procedure init (D : TMainData);
        procedure search(crit : string; R : TDataset);override;

  end;

var
  Worker: TWorker;

implementation

uses UException;

{$R *.lfm}

procedure TWorker.init(D:TMainData);
begin
  inherited init(D);
  table:='WORKER';
  cle:= 'SY_ID';
  checkcrc:=true;
end;


procedure TWorker.search(crit : string; R : TDataset);(* ************** *)

var query : string;

begin
  assert(assigned(R),'Buffer non initialisé');
  try
    R.close;
    crit:=trim(crit);
    if MainData.isConnected then
    begin
       query:=Maindata.getQuery('Q0010','SELECT SY_ID, SUBSTR(SY_CODE,1,10) AS SY_CODE, SUBSTR(SY_LASTNAME,1,30) AS SY_LASTNAME, Substr(SY_FIRSTNAME,1,25) AS SY_FIRSTNAME FROM INTERVENANT WHERE SY_CODE LIKE ''%s%'' OR SY_LASTNAME LIKE ''%s%''  ORDER BY 2,3');
       query:=query.replace('%s',crit);
    end;
    MainData.readDataSet(R,query,true);
  except
    on E: Exception do Error(e, dber_sql, 'TWorker.search crit="'+crit+'" Query="'+query+'"');
  end;
end;



end.

