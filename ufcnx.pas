unit UFcnx;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Buttons,
  DBGrids, DBCtrls, DataAccess, UHistoManager, DB, BufDataset, SQLDB,
  odbcconn,w_a;

type

  { TFCnx }

  TFCnx = class(TW_A)
    Btn_test: TBitBtn;
    BitBtn_ok: TBitBtn;
    DBCboxConnectortype: TDBComboBox;
    DBCboxSyntax: TDBComboBox;
    DBEd_driver: TDBEdit;
    DBEd_Params: TDBEdit;
    DBEd_FileDsn: TDBEdit;
    DBEd_Hostname: TDBEdit;
    DBEd_Databasename: TDBEdit;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    MData: TBufDataset;
    CB_cnx: TComboBox;
    Source: TDataSource;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    procedure BitBtn_okClick(Sender: TObject);
    procedure Btn_testClick(Sender: TObject);
    procedure CB_cnxChange(Sender: TObject);
    procedure CB_SyntaxChange(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
  private
    function test_cnx : string;
    procedure Load;
  public

  end;



implementation

uses Main, UException;

{$R *.lfm}

{ TFCnx }

procedure TFCnx.FormCreate(Sender: TObject);

begin
     load;
end;

procedure TFCnx.CB_cnxChange(Sender: TObject);

var s,n : string;
    trouve : boolean;

begin
     s:=CB_cnx.Text;
     trouve:=false;
     Mdata.First;
     while (not trouve) and (not MData.EOF) do
     begin
          n:=Mdata.FieldByName('NAME').AsString;
          if n=s then
          begin
               trouve:=true
          end else
          begin
               MData.Next;
          end;
     end;
end;

procedure TFCnx.CB_SyntaxChange(Sender: TObject);
begin

end;

procedure TFCnx.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  MData.close;
  CloseAction:=caFree;
end;

procedure TFCnx.BitBtn_okClick(Sender: TObject);

var s : string;
    i : integer;
    ident,value : shortstring;

begin
  MainForm.HistoManager.save;
  if test_cnx<=' ' then
  begin
    try
      MainForm.closeAll;
      MainData.Logoff;
      s:=CB_cnx.Text;
      MainData.ini.WriteString('DEFAULT','CNX',s);
      for i:=2 to Mdata.FieldCount do
      begin
           ident:=Mdata.FieldDefs.Items[i - 1].Name;
           value:=Mdata.FieldByName(ident).AsString;
           MainData.ini.WriteString(s,ident,value);
      end;
      MainData.Logon;
      MainForm.HistoManager.LoadHisto;
    except
      on e : Exception do Error (e, dber_cfg,'TFCnx.BitBtn_okClick');
    end;
  end;
end;

procedure TFCnx.Btn_testClick(Sender: TObject);

var r : string;

begin
  r:=test_cnx;
  if r>' ' then
  begin
    showmessage('Erreur connexion '+r);
  end else
  begin
       showmessage('Connexion ok');
  end;
end;

function TFCnx.test_cnx : String;

var ConnectorType : ShortString;
    Syntax: ShortString;
    driver: ShortString;
    Params: ShortString;
    FileDsn: ShortString;
    Hostname: ShortString;
    Databasename: ShortString;
    ODBCCnx: TODBCConnection;
    SQLCnx: TSQLConnector;

begin
  try
      result:='Err';
      ODBCCnx:=nil;
      SQLCnx:=nil;
      ConnectorType:=DBCboxConnectortype.Text;
      Syntax:=DBCboxSyntax.Text;
      Driver:=DBEd_driver.Text;
      Params:=DBEd_Params.Text;
      FileDsn:=DBEd_FileDsn.Text;
      Hostname:=DBEd_Hostname.Text;
      Databasename:=DBEd_Databasename.Text;
      try
        if ConnectorType='ODBC' then ODBCCnx:= TODBCConnection.create(self) else
        SQLCnx:=TSQLConnector.Create(self);
        if ConnectorType='ODBC' then
        begin
             ODBCCnx.Driver:=Driver;
             ODBCCnx.FileDSN:=FileDSN;
             ODBCCnx.Params.text:=Params;
             ODBCCnx.HostName:=HostName;
             ODBCCnx.DatabaseName:=DataBaseName;
             ODBCCnx.LoginPrompt:=true;
             try
                ODBCCnx.Connected:=true;
                result:='';
             except
                on e : Exception do
                begin
                     result:=e.Message;
                end;
             end;
        end else
        begin
           SQLCnx.ConnectorType:=ConnectorType;
           SQLCnx.DatabaseName:=Databasename;
           SQLCnx.Hostname:=Hostname;
           SQLCnx.Charset:='UTF-8';
           SQLCnx.LoginPrompt:=True;
           SQLCnx.Params.text:=Params ;
           try
              SQLCnx.Connected:=true;
              result:='';
           except
              on e : Exception do
              begin
                  result:=e.Message;
              end;
           end;
        end;
    except
      on e : Exception do
      begin
        Error (e, dber_cfg,'TFCnx.test_cnx');
        result:=e.Message;
      end;
    end;
  finally
    if assigned(ODBCCnx) then ODBCCnx.Free;
    if assigned(SQLCnx) then SQLCnx.Free;
  end;
end;

procedure TFCnx.Load;

var s,r,v: String;
    ts : TStringList;
    i : integer;

begin
     try
       try
       MData.close;
       Mdata.CreateDataSet;
       MData.Open;
       CB_cnx.Clear;
       ts:=TStringList.Create;
       Maindata.ini.ReadSections(ts);
       for s in ts do
       begin
            if s<>'DEFAULT' then
            begin
                 CB_cnx.AddItem(s,nil);
                 Mdata.Append;
                 MData.Edit;
                 Mdata.FieldByName('NAME').Value:=s;
                 for i:=2 to Mdata.FieldCount do
                 begin
                      r:=Mdata.FieldDefs.Items[i - 1].Name;
                      v:=MainData.ini.ReadString(s,r,'');
                      Mdata.FieldByName(r).Value:=v;
                 end;
                 Mdata.Post;
            end;
        end;
        s:=Maindata.ini.ReadString('DEFAULT','CNX','???');
        CB_cnx.Text:=s;
        CB_cnxChange(self);
        except
          on e : Exception do Error (e, dber_system,'TFCnx.Load');
        end;
     finally
       freeAndNil(ts);
     end;
end;

end.

