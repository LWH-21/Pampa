unit FSearch;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls,
  Buttons, DBGrids, ZDataset,  DA_table, dworker,  DB, SQLDB, DataAccess,
  W_A, Classes;

type

  { TSearch }

  TSearch = class(TW_A)
    Button1: TButton;
    B_create: TBitBtn;
    B_ok: TBitBtn;
    B_Cancel: TBitBtn;
    Bsearch: TButton;
    DataSource1: TDataSource;
    Critere: TEdit;
    Grid: TDBGrid;
    procedure BNewClick(Sender: TObject);
    procedure BsearchClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure B_CancelClick(Sender: TObject);
    procedure B_createClick(Sender: TObject);
    procedure B_okClick(Sender: TObject);
    procedure CritereChange(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction); override;
    procedure FormCreate(Sender: TObject);
    function FormHelp(Command: Word; Data: PtrInt; var CallHelp: Boolean
      ): Boolean;
    procedure FormShow(Sender: TObject);
    procedure GridDblClick(Sender: TObject);

  private
    num_int : integer;
    last_name, first_name, code : shortstring;

    oldcrit : string;
    table : TDA_table;
    requete : TDataset;
  public
    procedure init(t : TDa_table);
    procedure set_num_int(i : longint);
    function get_num_int : longint;
    procedure get_result(var i : longint; var f,l,c : shortstring);
  end;

var
  Search: TSearch;

implementation

uses Main,UException;

{$R *.lfm}

{ TSearch }

procedure TSearch.init(t : Tda_table);

var s : string;

begin
    if table<>t then
    begin
         table:=t;
         Critere.text:='';
         s:=Critere.text;
         s:=trim(s);
         table.search(s,Requete);
         if Requete.isempty=false then Requete.RecNo:=1;
         oldcrit:=s;
    end;
end;

procedure TSearch.FormShow(Sender: TObject);

var nb : integer;

begin
   nb:=0;
   try
     IF assigned(Grid.DataSource.DataSet) then
     if Grid.DataSource.DataSet.Active then nb:=Grid.DataSource.DataSet.RecordCount;
     IF nb<=0 then
     begin
        oldcrit:=oldcrit+'/';
        BsearchClick(self);
     end;
   except
     on E: Exception do Error(e, dber_system,'TSearch.FormShow');
   end;
end;

procedure TSearch.GridDblClick(Sender: TObject);
begin
    B_okClick(Sender);
end;

procedure TSearch.set_num_int(i: longint);
begin
     num_int:=i;
end;

function TSearch.get_num_int: longint;

begin
  get_num_int:=num_int;
end;

procedure TSearch.get_result(var i : longint; var f,l,c : shortstring);

begin
  i:=num_int;
  f:=first_name;
  l:=last_name;
  c:=code;
end;

procedure TSearch.BsearchClick(Sender: TObject);

VAR S : string;

begin
   if not assigned(table) then exit;
   s:=Critere.text;
   s:=trim(s);
   if oldcrit<>s then
   begin
        oldcrit:=s;
        table.search(s,Requete);
        if Requete.isempty=false then Requete.RecNo:=1;
   end;
end;

procedure TSearch.Button1Click(Sender: TObject);

var e : exception;
begin
  raise e.create('test');
end;

procedure TSearch.B_CancelClick(Sender: TObject);
begin
      ModalResult:=mrCancel;
end;

procedure TSearch.B_createClick(Sender: TObject);
begin
  ModalResult:=mrYes;
end;

procedure TSearch.BNewClick(Sender: TObject);
begin
    num_int:=-1;
    last_name:=''; first_name:=''; code:='';
    close;
end;

procedure TSearch.B_okClick(Sender: TObject);

begin
     try
       if Requete.RecordCount>0 then
       begin
            num_int:=Requete.FieldByName('SY_ID').AsInteger;
            last_name:=Requete.FieldByName('SY_LASTNAME').AsString;
            first_name:=Requete.FieldByName('SY_FIRSTNAME').AsString;
            code:=Requete.FieldByName('SY_CODE').AsString;
            if num_int>0 then
            begin
                 ModalResult:=mrOk;
            end;
       end;
     except
       on E: Exception do Error(e, dber_sql,'TSearch.B_okClick');
     end;
end;

procedure TSearch.CritereChange(Sender: TObject);
begin
     Bsearchclick(self);
end;

procedure TSearch.FormClose(Sender: TObject;
  var CloseAction: TCloseAction);
begin
  CloseAction:=caHide;
  MainForm.FormActivate(nil);
end;

procedure TSearch.FormCreate(Sender: TObject);

begin
  oldcrit:='LWH';
  num_int:=-1;
  MainData.readDataSet(Requete,'',true);
  DataSource1.DataSet:=Requete;
 (* for i:=0 to Grid.Columns.Count-1 do
  begin
     grid.Columns[i].Title.Alignment := taCenter;
  end;   *)
end;

function TSearch.FormHelp(Command: Word; Data: PtrInt;
  var CallHelp: Boolean): Boolean;
begin
  showmessage('help');
  callhelp:=true;
  result:=true;
end;

end.

