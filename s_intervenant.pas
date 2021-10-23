unit S_intervenant;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, ComCtrls,
  DBCtrls, StdCtrls, Buttons, FRechIntervenant, DB, SQLDB, DIntervenant,
  W_A, LWDataPanel,DataAccess;

type

  { TFS_INTERVENANT }

  TFS_INTERVENANT = class(TW_A)
    bSearch: TButton;
    Button1: TButton;
    DataSource1: TDataSource;
    DBEdit1: TDBEdit;
    DBPRENOM: TDBEdit;
    DBCODE: TDBEdit;
    DBID: TDBEdit;
    DBNOM: TDBEdit;
    LWDataPanel1: TLWDataPanel;
    PageControl1: TPageControl;
    SQLQuery1: TSQLQuery;
    SQLTransaction: TSQLTransaction;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    procedure bSearchClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure LWDataPanel1DragDrop(Sender, Source: TObject; X, Y: Integer);
    procedure LWDataPanel1DragOver(Sender, Source: TObject; X, Y: Integer;State: TDragState; var Accept: Boolean);
    procedure LWDataPanel1EndDrag(Sender, Target: TObject; X, Y: Integer);
    procedure LWDataPanel1save(Sender: Tobject; code, json: string);

  private
   num_int : integer;
   procedure prepare_form(base : Twincontrol);
  public
  procedure setIntervenant(n : integer);
  function getIntervenant : integer;
  end;


implementation

{$R *.lfm}

{ TFS_INTERVENANT }


procedure TFS_INTERVENANT.FormActivate(Sender: TObject);
begin
   if num_int=-2 then
   begin
    bSearchClick(self);
    num_int:=RechIntervenant.get_num_int();
    if num_int>=0 then
    begin
        Intervenant.SelectIntervenant(num_int,SqlQuery1);
    end;
   end;
   inherited;
end;

procedure TFS_INTERVENANT.bSearchClick(Sender: TObject);

VAR i : integer;

begin
   case RechIntervenant.showmodal of
        mrOk : begin
                i:=RechIntervenant.get_num_int();
                if i>=-1 then
                begin
                     num_int:=i;
                     if num_int>=0 then
                     begin
                          Intervenant.SelectIntervenant(num_int,SqlQuery1);
                     end else
                     if num_int=-1 then
                     begin
                          Intervenant.NewIntervenant(SqlQuery1);
                     end else
                     begin
                       if SqlQuery1.recordCount=0 then
                       begin
                        close;
                        exit;
                       end;
                     end;
                end;
               end;
        mrYes: begin
                    Intervenant.NewIntervenant(SqlQuery1);
               end;
        else   begin
                  if SqlQuery1.recordCount=0 then
                  begin
                       close;
                       exit;
                  end;
               end;
   end;
   inherited FormActivate(nil);
end;

procedure TFS_INTERVENANT.Button1Click(Sender: TObject);

var s : string;

begin
   if Intervenant.Test(SqlQuery1,s) then
   begin
     Intervenant.update(Sqlquery1);
     //sqlquery1.ApplyUpdates(0);
   end else showmessage(s);
end;

procedure TFS_INTERVENANT.Button2Click(Sender: TObject);


begin
  LWDataPanel1.setDesign(not LWDataPanel1.designmode);
end;

procedure TFS_INTERVENANT.Button3Click(Sender: TObject);

var s: string;
    nom : string;

begin



end;

procedure TFS_INTERVENANT.FormCreate(Sender: TObject);

var nom, s : string;

begin
  inherited;
  num_int:=-2;
  SqlTransaction.DataBase:=MainData.DataBase;
  SqlQuery1.DataBase:=MainData.Database;
  Prepare_form(self);

  nom:= LWDataPanel1.GetInternalName;

  LWDataPanel1.setTable('INTERVENANT',Maindata.tablesdesc);
  if assigned( maindata.ihm) then
  begin
       MainData.ihm.TryGetValue(nom,s);
       if (not LWDataPanel1.designmode) and (s>' ') then LWDataPanel1.modify(s);
  end;

end;

procedure TFS_INTERVENANT.LWDataPanel1DragDrop(Sender, Source: TObject; X,
  Y: Integer);
begin
   showmessage('drag drop '+sender.classname+' '+source.classname) ;
end;

procedure TFS_INTERVENANT.LWDataPanel1DragOver(Sender, Source: TObject; X,
  Y: Integer; State: TDragState; var Accept: Boolean);
begin
  ACCEPT:=true;
end;

procedure TFS_INTERVENANT.LWDataPanel1EndDrag(Sender, Target: TObject; X,
  Y: Integer);
begin
  showmessage('end drag') ;
end;

procedure TFS_INTERVENANT.LWDataPanel1save(Sender: Tobject; code,json: string);
begin
  Maindata.SaveIhm(code,json);
end;

procedure TFS_INTERVENANT.Prepare_form(base : Twincontrol);

{var i,j : integer;
    c : TTableDesc;
    Str: TStringList;
    trouve : boolean;
    ed : Tdbedit;

    procedure search(b :  TControl);

    var wc : Twincontrol;
        k : integer;

    begin
         if LeftStr(b.name,2)='DB' then str.add(b.name);
         if (b is TwinControl) then
         begin
             wc := (b as Twincontrol);
             for k:=0 to wc.ControlCount-1 do
             begin
               search(wc.Controls[k]);
             end;
         end;
    end;}

begin
{     Assert(assigned(Intervenant.Data.tablesdesc),'Pas de données de description de la table INTERVENANT');
     i:=0;
     Str := TStringList.Create;
     search(base);
     while i<Intervenant.Data.tablesdesc.count do
     begin
       c:=Intervenant.Data.tablesdesc[i];
       if (c.table='INTERVENANT') and (c.visible) then
       begin
           trouve:=false;j:=0;
           while (not trouve) and (j<Str.count) do
           begin
                 if str[j]='DB'+c.nom_col then
                 begin
                     trouve:=true;
                 end;
                 inc(j);
           end;
           if not trouve then
           begin
               ed:=Tdbedit.create(self);
               with ed do
               begin
                   top:=10;
                   left:=300;
                   height:=50;
                   width:=100;
                   DataSource:=DataSource1;
                   DataField:=c.nom_col;
                   parent:=Tabsheet1;
                   visible:=true;
                   ed.bringToFront;
                   ed.Update;
                   ed.show;
                   ed.name:='DB'+c.nom_col;
               end;
           end;
       end;
       inc(i);
     end;
     freeAndNil(str);}
end;

procedure TFS_INTERVENANT.setIntervenant(n : integer);
begin
    assert(n>= -2 ,'Valeur hors limite');
    num_int:=n;
end;

function TFS_INTERVENANT.getIntervenant : integer;
begin
     getIntervenant:=num_int;
end;

end.

