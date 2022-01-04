unit UF_planning_01;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Buttons, DBCtrls,DateUtils,
  DBGrids, StdCtrls, ComCtrls, ExtCtrls, Grids, Menus, ListFilterEdit, W_A, DB,
  memds, DataAccess, DPlanning, DA_table,UPlanning, UPlanning_enter;

type

  { TF_planning_01 }

  TF_planning_01 = class(TW_A)
    Btn_ok: TBitBtn;
    Btn_insert: TBitBtn;
    Ed_lib: TEdit;
    Ed_code: TEdit;
    Mchange: TMenuItem;
    MPaste: TMenuItem;
    MDel: TMenuItem;
    Minsert: TMenuItem;
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
    procedure MchangeClick(Sender: TObject);
    procedure pb_plan1MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure pb_plan1Paint(Sender: TObject);
    procedure Scroll_planning_1Change(Sender: TObject);
  private
   query : TDataset;
   GPlan: TGPlanning;
   currentrow : integer;
  public
    w_id : longint;
    procedure load;
    procedure load_planning(pl_id : longint);
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
   (*  if Gplan.save(s,w,p,st,se) then
     begin
          if p>0 then
          begin
               planning.Read(q,p);
               q.Edit;
               q.fieldbyname('SY_DETAIL').AsString:=s;
               q.fieldbyname('SY_START').AsString:=Planning.ToIsoDate(st);
               q.fieldbyname('SY_END').AsString:=Planning.ToIsoDate(se);
               planning.Write(q,p);
          end else
          begin
            planning.Insert(q);
            //query.Edit;
            //
//            query.fieldbyname('SY_ID').asInteger:=max;
            q.fieldbyname('SY_WID').asInteger:=w;
            q.fieldbyname('SY_DETAIL').AsString:=s;
            q.fieldbyname('SY_START').AsString:=Planning.ToIsoDate(st);
            q.fieldbyname('SY_END').AsString:=Planning.ToIsoDate(se);
            planning.Write(q,p,um_create);
          end;
     end;
     if assigned(q) then
     begin
          q.close;
          q.free;
     end; *)
end;

procedure TF_planning_01.FormActivate(Sender: TObject);
begin
  inherited;
end;

procedure TF_planning_01.Btn_insertClick(Sender: TObject);

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

procedure TF_planning_01.FormCreate(Sender: TObject);
begin
     GPlan:= TGPlanning.create(self);
     GPlan.Parent:=self;
     GPlan.setEditMode;
     w_id:=-1;
     query:=nil;
     currentrow:=-1;
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
  caption:='W = '+inttostr(self.width)+' H = '+inttostr(self.height);
end;

procedure TF_planning_01.FormShow(Sender: TObject);

begin
     load;
end;

procedure TF_planning_01.ListSelection(Sender: TObject; aCol, aRow: Integer);

var s : shortstring;
    l : longint;

begin
  if aRow>0 then
  begin
       s:=List.Cells[0,aRow];
       if not trystrtoint(s,l) then l:=-1;
       if currentrow<>l then
       begin
          currentrow:=l;
          load_planning(l);
       end;
  end;
end;

procedure TF_planning_01.MchangeClick(Sender: TObject);

begin
 (*   EnterPlanning.Left:=pb_plan1.left + limite + selection.x*wcol;
    if EnterPlanning.Left+EnterPlanning.Width > self.width then
    begin
        EnterPlanning.Left:=pb_plan1.left + limite + (selection.x - 1)*wcol - EnterPlanning.width;
    end;
    if EnterPlanning.Left<pb_plan1.left  then EnterPlanning.Left:=pb_plan1.left;

    EnterPlanning.Top:=pb_plan1.top + header + selection.Y * hline;
    if EnterPlanning.Top + EnterPlanning.Height > self.Height then
    begin
         EnterPlanning.Top:=pb_plan1.top + header + (selection.Y - 1) * hline - EnterPlanning.Height;
         if EnterPlanning.top<(pb_plan1.top - EnterPlanning.height div 2)  then EnterPlanning.top:=(pb_plan1.top - EnterPlanning.height div 2);
    end;
    EnterPlanning.setInter(selection.x, Selection.y, mat.lines[selection.Y - 1].colums[selection.x - 1]);
    EnterPlanning.SetFocus;          *)
end;

procedure TF_planning_01.pb_plan1MouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);

var l,c : integer;

begin

end;

procedure TF_planning_01.pb_plan1Paint(Sender: TObject);

var w,h : integer;

begin

end;

procedure TF_planning_01.Scroll_planning_1Change(Sender: TObject);
begin
 // pb_plan1.Refresh;
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
  sql:=MainData.getQuery('QPL02','SELECT SY_ID, SY_WID, SY_START, SY_END FROM PLANNING WHERE SY_WID=%w ORDER BY 3,4');
  sql:=sql.Replace('%w',inttostr(w_id));
  Maindata.readDataSet(query,sql,true);
  List.Clean;
  List.RowCount:=1;
  while not query.EOF do
  begin
    l:=Query.Fields[0].AsInteger;
    start_date:=IsoStrToDate(query.Fields[2].AsString);
    end_date:=IsoStrToDate(query.Fields[3].AsString);

   // s:=query.Fields[5].AsString;
    List.InsertRowWithValues(1,[inttostr(l),formatdate(start_date),formatdate(end_date),'']);
    query.Next;
  end;
  List.Row:=1;
end;

procedure TF_planning_01.load_planning(pl_id : longint);

var st,en : tdatetime;


begin
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

