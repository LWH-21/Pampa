unit Ucfg_table_det;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, DBCtrls, Buttons,
  ZDataset, UCfg_table, DB, SQLDB, DataAccess;

type

  { TFcfg_table_det }

  TFcfg_table_det = class(TForm)
    BitBtn1: TBitBtn;
    DBEdit1: TDBEdit;
    SQLQuery1: TSQLQuery;
    ZQuery1: TZQuery;
    procedure BitBtn1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);

  private

  public
      Src : TDataSource;
  end;

var
  Fcfg_table_det: TFcfg_table_det;

implementation

{$R *.lfm}


{ TFcfg_table_det }

procedure TFcfg_table_det.FormCreate(Sender: TObject);
begin

end;

procedure TFcfg_table_det.BitBtn1Click(Sender: TObject);
begin
  src.DataSet.UpdateRecord;
  if src.DataSet is TSqlQuery then TSqlquery(src.DataSet).ApplyUpdates(0) else
  if src.DataSet is TZquery then TZquery(src.DataSet).ApplyUpdates;
  if MainData.cmode='DBE' then
  begin
    TSqlTransaction(TSqlQuery(src.DataSet).Transaction).CommitRetaining ;
  end;
end;

procedure TFcfg_table_det.FormShow(Sender: TObject);
begin
  DBEdit1.DataSource:=src;
  DBEdit1.Datafield:='EXTERNAL_NAME';
end;

end.

