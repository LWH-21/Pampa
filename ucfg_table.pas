unit UCfg_table;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, DBGrids,
  ComCtrls, DBCtrls, Buttons, W_A, DataAccess, UException, DB, BufDataset,
  SQLDB;

type

  { TFCfg_Table }

  TFCfg_Table = class(TW_A)
    Btn_del: TBitBtn;
    Btn_add: TBitBtn;
    Btn_close: TBitBtn;
    Btn_modify: TBitBtn;
    BufDataset1: TBufDataset;
    CB_table: TComboBox;
    DataSource1: TDataSource;
    DataSource2: TDataSource;
    DBCheckBox1: TDBCheckBox;
    DBColname: TDBEdit;
    DBCollen: TDBEdit;
    DBEdit1: TDBEdit;
    DBEdit2: TDBEdit;
    DBPrecis: TDBEdit;
    DBExternal_name: TDBEdit;
    DBGrid1: TDBGrid;
    DBLookupComboBox1: TDBLookupComboBox;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    PageControl1: TPageControl;
    TabSheet1: TTabSheet;
    procedure Btn_modifyClick(Sender: TObject);
    procedure CB_tableChange(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure StrGridSelection(Sender: TObject; aCol, aRow: Integer);
  private
    Query : TDataSet;
  public

  end;


implementation

{$R *.lfm}

uses Ucfg_table_det;

{ TFCfg_Table }

procedure TFCfg_Table.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
     closeAction:=caFree;
end;

procedure TFCfg_Table.CB_tableChange(Sender: TObject);

var
    sql : string;
    t : shortstring;
begin
     t:=trim(CB_table.Text);
     if length(t)>1 then
     begin
       sql:=Maindata.getQuery('QCF02','SELECT DISTINCT ID,COLNAME, EXTERNAL_NAME,SYSCOL,TYPE_COL, COLLEN, PRECIS,MASK,CHARCASE,DEFVAL,CTRL,JSON, LASTUSER, ROWVERSION FROM LWH_COLUMNS WHERE TABLE_NAME = ''%t'' ORDER BY 1');
       sql:=StringReplace(sql,'%t',t,[rfReplaceAll]);
       MainData.readDataSet(Query,sql,true);
       Query.First;
       Datasource1.DataSet:=Query;
       DBGrid1.Refresh;
     end;
end;

procedure TFCfg_Table.Btn_modifyClick(Sender: TObject);

var det : TFcfg_table_det;

begin
     det:=TFcfg_table_det.Create(self);
     det.Src:=Datasource1;
     det.ShowModal;
end;

procedure TFCfg_Table.FormCreate(Sender: TObject);

var query1 : TDataset;
    sql,s : string;

begin
   try
     try
       BufDataset1.close;
       BufDataset1.CreateDataSet;
       BufDataset1.Open;
       BufDataset1.AppendRecord(['CHAR','Chaine de caractères']);
       BufDataset1.AppendRecord(['NUM','Nombre']);
       BufDataset1.AppendRecord(['DATE','Date']);
       BufDataset1.AppendRecord(['TIME','Heure']);
       BufDataset1.AppendRecord(['BOOL','Oui/Non']);

       Query:=nil;
       MainData.readDataSet(Query,'',false);
       DataSource1.Dataset:=Query;

       CB_table.Items.Clear;

       sql:=Maindata.getQuery('QCF01','SELECT DISTINCT TABLE_NAME FROM LWH_COLUMNS ORDER BY 1');
       Query1:=nil;
       MainData.readDataSet(Query1,sql,true);
       query1.First;
       while not query1.EOF do
       begin
            s:=(query1.Fields[0].asString).ToUpper;
            CB_table.AddItem(s,nil);
            query1.next;
       end;
       if CB_table.Items.Count>0 then
       begin
            CB_table.Text:=CB_table.Items[0];
            CB_tableChange(self);
       end;
       query1.close;
     except
       on E: Exception do
             Error(E, dber_sql, sql);
     end;
   finally
     query1.free;
   end;

end;

procedure TFCfg_Table.StrGridSelection(Sender: TObject; aCol, aRow: Integer);


begin

     //edit1.Text:=s;
end;

end.

(*




DROP TABLE LWH_COLUMNS_1;
CREATE TABLE LWH_COLUMNS_1(
	[ID] INTEGER PRIMARY KEY,
	[TABLE_NAME] TEXT NOT NULL,
	[COLNAME] TEXT NOT NULL,
	[EXTERNAL_NAME] TEXT NOT NULL,
	[SYSCOL] INT DEFAULT 'N' NOT NULL,
	[TYPE_COL] TEXT DEFAULT 'CHAR' NOT NULL,
	[COLLEN] INT NULL,
	[PRECIS] INT NULL,
	[MASK] TEXT NULL,
	[CHARCASE] TEXT DEFAULT 'A' NULL,
	[DEFVAL] TEXT NULL,
	[CTRL] TEXT NULL,
	[VALLIST] TEXT NULL,
	[LASTUSER] VARCHAR(50),
	[ROWVERSION] DATETIME DEFAULT CURRENT_TIMESTAMP);

INSERT INTO LWH_COLUMNS_1
(ID, TABLE_NAME, COLNAME, EXTERNAL_NAME, SYSCOL,
TYPE_COL, COLLEN, PRECIS, MASK, CHARCASE,
DEFVAL, CTRL, VALLIST, LASTUSER, ROWVERSION)
SELECT
ID,TABLE_NAME,COLNAME,EXTERNAL_NAME,'Y',
TYPE_COL,COLLEN,PRECIS,'','A',
'','','','',NULL
FROM LWH_COLUMNS;

UPDATE LWH_COLUMNS_1 SET TYPE_COL='CHAR' WHERE TYPE_COL ='VARCHAR';
UPDATE LWH_COLUMNS_1 SET TYPE_COL='NUM' WHERE TYPE_COL ='INT';
UPDATE LWH_COLUMNS_1 SET CHARCASE='N', PRECIS=0 WHERE TYPE_COL ='NUM';

UPDATE LWH_COLUMNS_1  SET COLNAME='SY_'|| COLNAME;



select * from LWH_COLUMNS_1 lc

*)

(*

"ID","TABLE_NAME","COLNAME","EXTERNAL_NAME","SYSCOL","TYPE_COL","COLLEN","PRECIS","MASK","CHARCASE","DEFVAL","CTRL","VALLIST","LASTUSER","ROWVERSION"
1,INTERVENANT,SY_ID,IDENTIFIANT DE L INTERVENANT,Y,NUM,,0,"",N,"","","","",
2,INTERVENANT,SY_CODE,Code de l'intervenant,Y,CHAR,7,,"",A,"","","","",
3,INTERVENANT,SY_CRC,CRC,Y,NUM,,0,"",N,"","","","",
4,INTERVENANT,SY_LASTNAME,Nom de l'intervenant,Y,CHAR,50,,"",A,"","","","",
5,INTERVENANT,SY_FIRSTNAME,Prénom de l'intervenant,Y,CHAR,50,,"",A,"","","","",
6,INTERVENANT,SY_EXTERNALCODE,Code externe de l'intervenant,Y,CHAR,50,,"",A,"","","","",




*)




