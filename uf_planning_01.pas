unit UF_planning_01;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Buttons, DBCtrls,
  DBGrids, StdCtrls, ListFilterEdit, W_A, DB, memds, DataAccess,
  DPlanning;

type

  { TF_planning_01 }

  TF_planning_01 = class(TW_A)
    BitBtn1: TBitBtn;
    DataSource1: TDataSource;
    DBGrid1: TDBGrid;
    Ed_lib: TEdit;
    Ed_code: TEdit;
    MemDataset1: TMemDataset;
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormShow(Sender: TObject);
  private
   query : TDataset;
  public
    w_id : longint;
    procedure load;
  end;

implementation

{$R *.lfm}

{ TF_planning_01 }

procedure TF_planning_01.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  CloseAction:=caFree;
end;

procedure TF_planning_01.FormShow(Sender: TObject);

begin
     load;
     query:=nil;
end;

procedure TF_planning_01.load;

var R : TDataSet;
    sql,s : string;
    l : longint;
    start_date,end_date : tdatetime;

begin
  Ed_code.Clear;
  Ed_lib.Clear;
  if w_id>0 then
  begin
       R:=nil;
       sql:=Maindata.getQuery('Q0014','SELECT SY_CODE, SY_FIRSTNAME, SY_LASTNAME FROM WORKER WHERE SY_ID=%id');
       sql:=sql.Replace('%id',inttostr(w_id));
       Maindata.readDataSet(R,sql,true);
       if R.RecordCount>0 then
       begin
            s:=R.Fields[0].AsString;
            Ed_code.Text:=s;
            s:=R.Fields[1].AsString+' '+R.Fields[2].asString;
            Ed_lib.Text:=s;
       end;
       R.close;
  end;
  sql:=MainData.getQuery('QPL02','SELECT SY_ID, SY_WID, SY_FORMAT, SY_START, SY_END, SY_DETAIL FROM PLANNING WHERE SY_WID=%w');
  sql:=sql.Replace('%w',inttostr(w_id));
  Maindata.readDataSet(query,sql,true);
  MemDataset1.Close;
  Memdataset1.Active:=true;
  while not query.EOF do
  begin
    l:=Query.Fields[0].AsInteger;
    s:=query.Fields[3].AsString;
    start_date:=IsoStrToDate(s);
    s:=query.Fields[4].AsString;
    end_date:=IsoStrToDate(s);
    s:=query.Fields[5].AsString;
    s:='Test';
    MemDataSet1.InsertRecord([l,start_date,end_date,s]);
    query.Next;
  end;
end;

end.

