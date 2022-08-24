unit UF_planning_01;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Buttons, DBCtrls,DateUtils,
  DBGrids, StdCtrls, ComCtrls, ExtCtrls, Grids, Menus, ListFilterEdit, W_A, DB,
  memds, DataAccess, DPlanning, DA_table,UPlanning, UPlanning_enter,ressourcesStrings;

type

  { TF_planning_01 }

  TF_planning_01 = class(TW_A)
    Btn_ok: TBitBtn;
    Btn_insert: TBitBtn;
    Ed_lib: TEdit;
    Ed_code: TEdit;
    MNewEmpty: TMenuItem;
    MCopy: TMenuItem;
    Planning_menu: TPopupMenu;
    List: TStringGrid;
    procedure Btn_insertClick(Sender: TObject);
    procedure Btn_okClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure ListSelection(Sender: TObject; aCol, aRow: Integer);
    procedure MNewEmptyClick(Sender: TObject);
  private
   query : TDataset;
   GPlan: TGPlanning;
   currentrow : integer;
   w_id : longint;
   pl_id: longint;
  public

    procedure init(w,p : longint);
    procedure load;
    procedure load_planning(p: longint);
  end;

implementation

{$R *.lfm}

{ TF_planning_01 }

procedure TF_planning_01.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  CloseAction:=caFree;
end;

procedure TF_planning_01.Btn_okClick(Sender: TObject);

var s : string;
    st,se : tdatetime;
    w,p : longint;
    q : Tdataset;

begin
     q:=nil;
     Gplan.save();
end;



procedure TF_planning_01.FormActivate(Sender: TObject);
begin
  inherited;
end;

procedure TF_planning_01.Btn_insertClick(Sender: TObject);

var dt : tdatetime;
    s : string;

begin
  (*query.Active:=true;
  query.edit;
  query.Insert;
  dt:=now();
  s:=formatdate(dt);
  List.InsertRowWithValues(1,['New',s,'???','']);
  List.Row:=1;
  ListSelection(self,1,1);*)
  MNewEmpty.visible:=true;
  MCopy.visible:=true;
  Planning_menu.PopUp;
end;

procedure TF_planning_01.FormCreate(Sender: TObject);
begin
     GPlan:= TGPlanning.create(self);
     GPlan.Parent:=self;
     GPlan.setEditMode;
     w_id:=-1;
     query:=nil;
     currentrow:=-2;
     FormResize(self);
end;

procedure TF_planning_01.FormDestroy(Sender: TObject);
begin
  if assigned(query) then
  begin
    query.close;
    query.free;
  end;
end;

procedure TF_planning_01.FormResize(Sender: TObject);
begin
  GPlan.Left:=8;
  GPlan.top:=176;
  GPlan.height:=Self.height -GPlan.top - 50;
  GPlan.width := Self.width - 20;
  Btn_ok.Top := GPlan.top + GPlan.height + 10;
  Btn_insert.Top := Btn_ok.top;
  caption:='W = '+inttostr(self.width)+' H = '+inttostr(self.height);
end;

procedure TF_planning_01.FormShow(Sender: TObject);

begin
     load;
end;

procedure TF_planning_01.ListSelection(Sender: TObject; aCol, aRow: Integer);

var s : shortstring;
    l,t,oldrow : longint;
    i : integer;
    change : boolean;

begin
  if aRow>0 then
  begin
       change:=true;
       s:=List.Cells[0,aRow];
       if not trystrtoint(s,l) then l:=-1;
       if currentrow<>l then
       begin
          if Gplan.ismodified then
          begin
             case QuestionDlg(rs_confirm,rs_savechange,mtConfirmation,[mrNo, rs_no,mrYes,rs_yes,'IsDefault',mrCancel,'&Annuler'],0) of
                mrYes : begin
                             change:=GPlan.save;
                        end;
                mrNo  : change:=true;
                mrCancel : change:=false
             else
               change:=false;
             end;
          end;
          if change then
          begin
               currentrow:=l;
               load_planning(l);
          end else
          begin
               oldrow:=-1;
               for i:=0 to List.RowCount - 1 do
               begin
                    if trystrtoint(List.Cells[0,i],t) then
                    begin
                       if t=currentrow then
                       begin
                            oldrow:=i;
                            break;
                       end;
                    end;
               end;
               if oldrow>=0 then
               begin
                    List.Row:=oldrow;
               end;
          end;
       end;
  end;
end;

procedure TF_planning_01.MNewEmptyClick(Sender: TObject);

var dt : tdatetime;
    s : string;

begin
  query.Active:=true;
  query.edit;
  query.Insert;
  dt:=now();
  s:=formatdate(dt);
  List.InsertRowWithValues(1,['New',s,'???','']);
  List.Row:=1;
  ListSelection(self,1,1);
end;

procedure TF_planning_01.init(w,p : longint);

begin
  w_id:=w;
  pl_id:=p;
end;

procedure TF_planning_01.load;

var R : TDataSet;
    sql,s : string;
    row,i: integer;
    l : longint;
    start_date,end_date : tdatetime;

begin
  Ed_code.Clear;
  Ed_lib.Clear;
  if w_id>0 then
  begin
       R:=nil;
       sql:=Maindata.getQuery('Q0015','SELECT SY_CODE, SY_FIRSTNAME, SY_LASTNAME FROM WORKER WHERE SY_ID=%id');
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
  sql:=MainData.getQuery('QPL02','SELECT SY_ID, SY_WID, SY_START, SY_END FROM PLANNING WHERE SY_WID=%w ORDER BY 3,4');
  sql:=sql.Replace('%w',inttostr(w_id));
  Maindata.readDataSet(query,sql,true);
  List.Clean;
  while List.RowCount>1 do List.DeleteRow(1);
  row:=1;
  while not query.EOF do
  begin
    l:=Query.Fields[0].AsInteger;
    start_date:=IsoStrToDate(query.Fields[2].AsString);
    end_date:=IsoStrToDate(query.Fields[3].AsString);
    List.InsertRowWithValues(1,[inttostr(l),formatdate(start_date),formatdate(end_date),'']);
    query.Next;
  end;
  for i:=0 to List.RowCount-1 do
  begin
    if TryStrToInt(List.Cells[0,i],l) then
    begin
         if l=pl_id then
         begin
              row:=i;
              break;
         end;
    end;
  end;
  if (List.RowCount>1) then
  begin
    if row>List.RowCount then row:=1;
    List.Row:=row;
    ListSelection(self,0,row);
  end else
  begin
  end;
end;

procedure TF_planning_01.load_planning(p : longint);

var st,en : tdatetime;


begin
  pl_id:=p;
  if (pl_id>0) then
  begin
       Gplan.load(pl_id);
  end else
  begin
    st:=now();
    en:=encodedate(2499,12,31);
    GPlan.load('',w_id,pl_id,st,en);
  end;
end;

end.

