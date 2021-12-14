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
    Ed_lib: TEdit;
    Ed_code: TEdit;
    Mchange: TMenuItem;
    MPaste: TMenuItem;
    MDel: TMenuItem;
    Minsert: TMenuItem;
    MCopy: TMenuItem;
    Planning_menu: TPopupMenu;
    List: TStringGrid;
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
          MainData.WriteDataSet(query,'TF_planning_01');
     end;
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

var i,j,k : integer;

begin
{  assert(selection.y>0,'Incorrect line');
  j:=selection.y;
  i:=mat.linescount;
  if (i<2) or (not mat.isLineEmpty(i - 2)) then
  begin
       mat.add_line;
       i:=mat.linescount;
  end;
  for i:=mat.linescount-1 downto j do
  begin
    mat.lines[i].sy_id:=mat.lines[i-1].sy_id;
    mat.lines[i].index:=mat.lines[i-1].index;
    for k:=0 to mat.colscount-1 do mat.lines[i].colums[k]:=mat.lines[i-1].colums[k] ;
  end;
  for i:=0 to mat.colscount - 1 do
  begin
    mat.lines[j].colums[i]:=nil;
  end;
  pb_plan1.Refresh;   }
end;

procedure TF_planning_01.modify;

var inter : TIntervention;

begin
 {   inter:=mat.lines[EnterPlanning.line - 1].colums[EnterPlanning.col - 1];
    if not assigned(inter) then
    begin
         inter:=TIntervention.create(EnterPlanning.col,0,0,0,w_id,mat.lines[EnterPlanning.line - 1].sy_id);
         mat.lines[EnterPlanning.line - 1].colums[EnterPlanning.col - 1]:=inter;
    end;
    if assigned(inter) then
    begin
         inter.h_start:=HourOf(EnterPlanning.StartTime.Time)*100 + MinuteOf(EnterPlanning.StartTime.Time);
         inter.h_end:=HourOf(EnterPlanning.EndTime.Time)*100 + MinuteOf(EnterPlanning.EndTime.Time);
    end;
    pb_plan1.Refresh;    }
end;

procedure TF_planning_01.pb_plan1Click(Sender: TObject);
begin

end;

procedure TF_planning_01.pb_plan1MouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);

var l,c : integer;

begin
   {  assert(wcol>0,'Col width equals to 0');
     assert(hline>0,'Line height equals to 0');
     EnterPlanning.Visible:=false;
     if x<limite then
     begin
         c:=0;
     end else
     begin
       c:= x - limite;
       c:= (c div wcol) + 1;
     end;
     if y<header then
     begin
         l:=0;
     end else
     begin
       l:= y - header;
       l:=(l div hline) + 1;
     end;
     selection.x:=c;
     selection.Y:=l;
     pb_plan1.Refresh;
     if Button=mbRight then
     begin
         Planning_menu.PopUp;
     end; }
end;

procedure TF_planning_01.pb_plan1Paint(Sender: TObject);

var w,h : integer;

begin
 {   w:=pb_plan1.Width;
    h:=pb_plan1.height;

    pb_plan1.Canvas.Clear;
    pb_plan1.Canvas.Pen.Color:=clBlack;
    pb_plan1.Canvas.pen.Width:=1;
    pb_plan1.Canvas.Brush.Color:=$00E6FFFF;
    pb_plan1.Canvas.FrameRect(0,0,w,h);
    pb_plan1.canvas.Rectangle(0,0,w,h);

    draw_planning_1;  }
end;

procedure TF_planning_01.Scroll_planning_1Change(Sender: TObject);
begin
 // pb_plan1.Refresh;
end;

procedure TF_planning_01.draw_planning_1;

var w,h : integer;
  i,l,c,index : integer;
  s : shortstring;
  r : trect;
  tmpdate : tdatetime;
  tstyle : TTextStyle;
  decal : integer;


begin
 //    w:=pb_plan1.Width;
   //  h:=pb_plan1.height;

     {if nblines>((h-header) div hline) then
     begin
          Scroll_planning_1.Visible:=true;
          Scroll_planning_1.Max:=nblines;
     end else
     begin
       Scroll_planning_1.visible:=false;
     end;}

     //Header
{     pb_plan1.Canvas.Brush.color:=TColor($FFF8DC);
     pb_plan1.Canvas.Brush.Style:=bsSolid;
     pb_plan1.Canvas.FillRect(1,1,w-1,header);
     pb_plan1.Canvas.pen.Color:=clblack;

     pb_plan1.canvas.Rectangle(0,1,w-1,header-1);

     decal:=Scroll_planning_1.Position;

     pb_plan1.Canvas.pen.color:=clBlue;
     pb_plan1.canvas.Line(limite,1,limite,h - 1);
     tstyle.alignment:=taCenter;
     tstyle.Opaque:=false;
     tstyle.SingleLine:=false;
     tstyle.Wordbreak:=true;
     tstyle.Clipping:=true;
     tstyle.systemFont:=true;
     tstyle.rightToLeft:=false;
     for i:=0 to 6 do
     begin
       if i>0 then pb_plan1.Canvas.Line(limite + i*wcol,1,limite+ i*wcol,h - 1);
       r.Left:=limite + i*wcol;r.right:=r.left+wcol;
       r.top:=2;r.bottom:=header;
       s:=cdays[i + 1];
       pb_plan1.Canvas.TextRect(r,0,0,s,tstyle);
     end;

     l:=0;
     index:=decal;
     pb_plan1.Canvas.Brush.Style:=bsclear;
     if assigned(mat) then
     begin
       while (index<mat.linescount) and (mat.lines[index].sy_id>0)  do
       begin
         l:=index - decal;
         if (l<mat.linescount - 1) and (mat.lines[index].sy_id<>mat.lines[index+1].sy_id) then
         begin
              pb_plan1.canvas.Line(0,header+hline*(l+1),w,header+hline*(l+1));
         end else
         begin
              pb_plan1.canvas.Line(limite,header+hline*(l+1),w,header+hline*(l+1));
         end;
         if (l=0) or (mat.lines[index].sy_id<>mat.lines[index-1].sy_id) then
         begin
              r.left:=10;r.right:=limite;
              r.bottom:=header+hline*(l+1);r.top:=r.bottom-hline;
              tstyle.Alignment:=taLeftJustify;
              c:=mat.lines[index].index;
              s:=mat.libs[c].code+' '+mat.libs[c].caption;
              pb_plan1.Canvas.TextRect(r,15,5,s,tstyle);
         end;

         r.Top:=header+hline*(l);
         r.height:=hline;
         r.Left:=limite;
         r.Width:=wcol;
         for c:=0 to 6 do
         begin
           if (selection.y=index+1) and (selection.x = c+1) then
           begin
                pb_plan1.Canvas.Brush.Color:=clred;
                pb_plan1.Canvas.FillRect(r);
           end;

           if assigned(mat.lines[index].colums[c ]) then
           begin
                 s:=mat.lines[index].colums[c ].gethstart+' - '+mat.lines[index].colums[c].gethend;
                 pb_plan1.Canvas.TextRect(r,r.left+5,r.top,s,tstyle);
           end;
           r.Left:=r.Left+wcol;
           r.Right :=R.left+wcol;
         end;
         inc(index);
       end;
     end;  }

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

