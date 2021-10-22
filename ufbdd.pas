unit UFbdd;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, SQLDB, DB, odbcconn, Forms, Controls, Graphics, Dialogs,
  StdCtrls, Buttons, DBGrids, ComCtrls, SynEdit, SynHighlighterSQL,INIFiles;

type

  { TFbdd }

  TFbdd = class(TForm)
    Bexec: TButton;
    DataSource1: TDataSource;
    DBGrid1: TDBGrid;
    ODBC: TODBCConnection;
    SQLConnector: TSQLConnector;
    SQLQuery: TSQLQuery;
    Editor: TSynEdit;
    SynSQLSyn1: TSynSQLSyn;
    Tran: TSQLTransaction;
    TreeView1: TTreeView;
    procedure BexecClick(Sender: TObject);
    procedure BitBtn1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private

  public

  end;

var
  Fbdd: TFbdd;

implementation

{$R *.lfm}

{ TFbdd }

procedure TFbdd.BitBtn1Click(Sender: TObject);
begin

end;

procedure TFbdd.BexecClick(Sender: TObject);
begin
  SQlquery.close;
  SqlQuery.SQL.Text:=Editor.Lines.Text;
  SqlQuery.open;
end;

procedure TFbdd.FormCreate(Sender: TObject);

VAR Rubrique : string;
    s : String;
    ini : Tinifile;
    ConnectorType : string;

begin
   ini:=Tinifile.create('Pampa.ini');
   Rubrique:=INI.ReadString('DEFAULT','CNX','');
   if Rubrique='' then
   begin
        ini.WriteString('DEFAULT','CNX','CNX01');
        ini.WriteString('CNX01','CONNECTORTYPE','SQLite3');
        ini.WriteString('CNX01','SQLSYNTAX','SQLITE');
        ini.WriteString('CNX01','DATABASENAME','SqlLite\Pampa.db');
        Rubrique:='CNX01';
   end;
   try
      ConnectorType:=Ini.Readstring(Rubrique,'CONNECTORTYPE','');
      if connectorType='ODBC' then
      begin
        ODBC.Driver:=Ini.Readstring(Rubrique,'DRIVER','');
        ODBC.FileDSN:=Ini.Readstring(Rubrique,'FILEDSN',''); ;
        ODBC.Params.text:=Ini.Readstring(Rubrique,'PARAMS','');
        ODBC.UserName:=Ini.Readstring(Rubrique,'USERNAME','');
        ODBC.Password:=Ini.Readstring(Rubrique,'PASSWORD','');
        ODBC.CharSet:=Ini.Readstring(Rubrique,'CHARSET','');
      end else
      begin
        SQLConnector.ConnectorType:=Ini.Readstring(Rubrique,'CONNECTORTYPE','');
        SQLConnector.DatabaseName:=Ini.Readstring(Rubrique,'DATABASENAME','');
        SQLConnector.Hostname:=Ini.Readstring(Rubrique,'HOSTNAME','');
        SQLConnector.Charset:=Ini.Readstring(Rubrique,'CHARSET','');
        SQLConnector.UserName:=Ini.Readstring(Rubrique,'USERNAME','');
        SQLConnector.Password:=Ini.Readstring(Rubrique,'PASSWORD','');
        SQLConnector.Params.text:=Ini.Readstring(Rubrique,'PARAMS','');
      end;

      s:=Ini.Readstring(Rubrique,'LOGINPROMT','');
      s:=uppercase(s);
      if s='TRUE' then SQLConnector.LoginPrompt:=True else SQLConnector.LoginPrompt:=False;
      SQLConnector.Role:=Ini.Readstring(Rubrique,'ROLE','');
   except
       on e : Exception do
       showmessage('Paramètres de connexion : '+e.message);
   end;
   try
     try
        if connectortype='ODBC' then
        begin
            ODBC.Connected:=true;
            Tran.Options:=[];
            Tran.DataBase:=ODBC;
            SQLQuery.DataBase:=ODBC;
            SQLQuery.Transaction:=Tran;
        end else
        begin
             SQLConnector.connected:=true;
             Tran.Options:=[];
             Tran.DataBase:=SQLConnector;
             SQLQuery.DataBase:=SQLConnector;
             SQLQuery.Transaction:=Tran;
        end;
     except
         on e : Exception do
         showmessage('Problème connexion : '+e.message);
     end;
   finally
    ini.Free;
   end;

end;

end.

