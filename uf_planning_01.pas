unit UF_planning_01;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Buttons, DBCtrls,
  DBGrids, StdCtrls, ListFilterEdit, W_A, DB, DataAccess;

type

  { TF_planning_01 }

  TF_planning_01 = class(TW_A)
    BitBtn1: TBitBtn;
    Cb_customer: TComboBox;
    DataSource1: TDataSource;
    DBGrid1: TDBGrid;
    Ed_lib: TEdit;
    Ed_code: TEdit;
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormShow(Sender: TObject);
  private
   requete : TDataset;
  public
    w_id : longint;

  end;

implementation

{$R *.lfm}

{ TF_planning_01 }

procedure TF_planning_01.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  CloseAction:=caFree;
end;

procedure TF_planning_01.FormShow(Sender: TObject);

var R : TDataSet;
    sql,s : string;
    l : longint;

begin
  Cb_customer.Items.Clear;
  Cb_customer.Clear;
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
       sql:='SELECT C.SY_ID, C.SY_CODE , C.SY_LASTNAME , C.SY_FIRSTNAME FROM PLANNING P INNER JOIN CUSTOMER C ON P.C_ID  = C.SY_ID WHERE P.W_ID =%id';
       sql:=sql.Replace('%id',inttostr(w_id));
       Maindata.readDataSet(R,sql,true);
       if R.RecordCount>0 then
       begin
          s:=R.Fields[1].AsString+' '+R.Fields[2].AsString+' '+R.Fields[3].asString;
          l:=R.Fields[0].AsInteger;
          Cb_customer.AddItem(s,TObject(intToStr(l)));
       end;
       if CB_Customer.Items.Count>0 then CB_Customer.ItemIndex:=0;
  end;
end;

end.

