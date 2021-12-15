unit UF_planning_01;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Buttons, DBCtrls,DateUtils,
  DBGrids, StdCtrls, ComCtrls, ExtCtrls, Grids, Menus, ListFilterEdit, W_A, DB,
  memds, DataAccess, DPlanning, UPlanning, UPlanning_enter;

type

  { TF_planning_01 }

  TF_planning_01 = class(TW_A)
    Btn_ok: TBitBtn;
    Btn_ok1: TBitBtn;
    Ed_lib: TEdit;
    Ed_code: TEdit;
    Mchange: TMenuItem;
    MPaste: TMenuItem;
    MDel: TMenuItem;
    Minsert: TMenuItem;
    MCopy: TMenuItem;
    Planning_menu: TPopupMenu;
    List: TStringGrid;
    procedure Btn_ok1Click(Sender: TObject);
    procedure Btn_okClick(Sender: TObject);
    procedure DBGrid1CellClick(Column: TColumn);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure ListSelection(Sender: TObject; aCol, aRow: Integer);
    procedure MchangeClick(Sender: TObject);
    procedure MinsertClick(Sender: TObject);
    procedure pb_plan1Click(Sender: TObject);
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
    procedure draw_planning_1;
    procedure load;
    procedure load_planning(pl_id : longint);
    procedure modify;
    procedure scrollbar_show;
    procedure selquery(r : longint);
  end;

implementation

{$R *.lfm}

{ TF_planning_01 }

procedure TF_planning_01.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  CloseAction:=caFree;
end;

procedure TF_planning_01.DBGrid1CellClick(Column: TColumn);
begin

end;

procedure TF_planning_01.Btn_okClick(Sender: TObject);

var s : string;
    st,se : tdatetime;

begin
     selquery(currentrow);
     if Gplan.save(s,st,se) then
     begin
          query.Edit;
          query.fieldbyname('SY_DETAIL').AsString:=s;
          query.fieldbyname('SY_START').AsString:=Planning.ToIsoDate(st);
          query.fieldbyname('SY_END').AsString:=Planning.ToIsoDate(se);
          MainData.WriteDataSet(query,'TF_planning_01');
     end;
end;

procedure TF_planning_01.Btn_ok1Click(Sender: TObject);

var max : longint;
    dt : tdatetime;
    s : string;

begin
  max:=Planning.getNextId;
  query.Active:=true;
  query.edit;
  query.Insert;
  dt:=now();
  s:=Planning.ToIsoDate(dt);
  query.fields[0].AsInteger:=max;
  query.fields[1].asInteger:=w_id;
  query.fields[3].asString:=s;
  query.fields[4].asString:=s;
  List.InsertRowWithValues(1,[inttostr(max),s,s,'']);
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
    s1 : string;
    l : longint;

begin
  if aRow>0 then
  begin
       s:=List.Cells[0,aRow];
       if trystrtoint(s,l) then
       begin
           if currentrow<>l then
           begin
               currentrow:=l;
               selquery(l);
               s1:=List.Cells[0,aRow];
               if TryStrToInt(s1,l) then load_planning(l);
           end;
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

procedure TF_planning_01.MinsertClick(Sender: TObject);



begin

end;

procedure TF_planning_01.modify;


begin

end;

procedure TF_planning_01.pb_plan1Click(Sender: TObject);
begin

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

procedure TF_planning_01.draw_planning_1;

begin
end;

procedure TF_planning_01.load;

var R : TDataSet;
    sql,s : string;
    l : longint;
    start_date,end_date : shortstring;

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
  List.Clean;
  List.RowCount:=1;
  while not query.EOF do
  begin
    l:=Query.Fields[0].AsInteger;
    start_date:=query.Fields[3].AsString;
    end_date:=query.Fields[4].AsString;

    s:=query.Fields[5].AsString;
    List.InsertRowWithValues(1,[inttostr(l),start_date,end_date,s]);
    query.Next;
  end;
  List.Row:=1;
end;

procedure TF_planning_01.load_planning(pl_id : longint);

var s : string;
    l : longint;
    st,en : tdatetime;


begin
  query.First;
  while not query.eof do
  begin
       l:=query.Fields[0].AsInteger;
       if l=pl_id then
       begin
         s:=query.Fields[3].AsString;
         st:=IsoStrToDate(s);
         s:=query.Fields[4].AsString;
         en:=IsoStrToDate(s);
         s:=query.Fields[5].AsString;
         GPlan.load(s,st,en);
         exit;
       end;
       query.Next;
  end;
end;

procedure TF_planning_01.scrollbar_show;

var h : integer;

begin
  {   h:=pb_plan1.Height;
     if nblines>((h-header) div hline) then
     begin
          Scroll_planning_1.Enabled:=true;
          Scroll_planning_1.Max:=nblines;
     end else
     begin
          Scroll_planning_1.Max:=0;
          Scroll_planning_1.enabled:=false;
     end;   }
end;

procedure TF_planning_01.selquery(r : longint);

var found : boolean;
    l : longint;

begin
     assert(assigned(query),'Dataset not assigned');
     assert(r>0,'Invalid parameter');
     query.First;
     found:=false;
     while (not found) and (not query.eof) do
     begin
       l:=query.Fields[0].AsInteger;
       found:=(r = l);
       if not found then query.next;
     end;
     assert(l=r,'Record not found');
end;

end.

