unit UF_planning_01;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Buttons, DBCtrls,
  DBGrids, StdCtrls, ComCtrls, ExtCtrls, ListFilterEdit, W_A, DB, memds,
  DataAccess, DPlanning;

type

  { TF_planning_01 }

  TF_planning_01 = class(TW_A)
    BitBtn1: TBitBtn;
    DataSource1: TDataSource;
    DBGrid1: TDBGrid;
    Ed_lib: TEdit;
    Ed_code: TEdit;
    MemDataset1: TMemDataset;
    pb_plan1: TPaintBox;
    Plannings: TPageControl;
    Planning_1: TTabSheet;
    Scroll_planning_1: TScrollBar;
    procedure DBGrid1CellClick(Column: TColumn);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure pb_plan1Paint(Sender: TObject);
  private
   query : TDataset;
   header,hline,limite : integer;
   mat :   TLPlanning;
  public
    w_id : longint;
    procedure draw_planning_1;
    procedure load;
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
  showmessage('ok');
end;

procedure TF_planning_01.FormCreate(Sender: TObject);
begin
     mat:=TLPlanning.create;
     w_id:=-1;
     query:=nil;
     header:=40;
     hline:=30;
     limite:=pb_plan1.Width div 6;
end;

procedure TF_planning_01.FormDestroy(Sender: TObject);
begin
  if assigned(mat) then
  begin
    mat.reset;
    freeAndNil(mat);
  end;
  if assigned(query) then
  begin
    query.close;
    query.free;
  end;
end;

procedure TF_planning_01.FormResize(Sender: TObject);
begin
  limite:=pb_plan1.Width div 6;
end;

procedure TF_planning_01.FormShow(Sender: TObject);

begin
     load;
end;

procedure TF_planning_01.pb_plan1Paint(Sender: TObject);

var w,h : integer;

begin
    w:=pb_plan1.Width;
    h:=pb_plan1.height;

    pb_plan1.Canvas.Clear;
    pb_plan1.Canvas.Pen.Color:=clBlack;
    pb_plan1.Canvas.pen.Width:=1;
    pb_plan1.Canvas.Brush.Color:=$00E6FFFF;
    pb_plan1.Canvas.FrameRect(0,0,w,h);
    pb_plan1.canvas.Rectangle(0,0,w,h);

    draw_planning_1;
end;

procedure TF_planning_01.draw_planning_1;

var w,h : integer;
  tsem : integer;
  i,l,c : integer;
  s : shortstring;
  r : trect;
  tmpdate : tdatetime;
  tstyle : TTextStyle;


begin

     w:=pb_plan1.Width;
     h:=pb_plan1.height;

     tsem := (w - limite) div 7;

     //Header
     pb_plan1.Canvas.Brush.color:=TColor($FFF8DC);
     pb_plan1.Canvas.Brush.Style:=bsSolid;
     pb_plan1.Canvas.FillRect(1,1,w-1,header);
     pb_plan1.Canvas.pen.Color:=clblack;

     pb_plan1.canvas.Rectangle(0,1,w-1,header-1);


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
       if i>0 then pb_plan1.Canvas.Line(limite + i*tsem,1,limite+ i*tsem,h - 1);
       r.Left:=limite + i*tsem;r.right:=r.left+tsem;
       r.top:=2;r.bottom:=header;
       s:=cdays[i + 1];
       pb_plan1.Canvas.TextRect(r,0,0,s,tstyle);
     end;

     l:=0;
     pb_plan1.Canvas.Brush.Style:=bsclear;
     if assigned(mat) then
     begin
       while (mat.lines[l].sy_id>0) and (l<mat.linescount) do
       begin
         if (l<mat.linescount - 1) and (mat.lines[l].sy_id<>mat.lines[l+1].sy_id) then
         begin
              pb_plan1.canvas.Line(0,header+hline*(l+1),w,header+hline*(l+1));
         end else
         begin
              pb_plan1.canvas.Line(limite,header+hline*(l+1),w,header+hline*(l+1));
         end;
         if (l=0) or (mat.lines[l].sy_id<>mat.lines[l-1].sy_id) then
         begin
              r.left:=10;r.right:=limite;
              r.bottom:=header+hline*(l+1);r.top:=r.bottom-hline;
              tstyle.Alignment:=taLeftJustify;
              c:=mat.lines[l].index;
              s:=mat.libs[c].code+' '+mat.libs[c].caption;
              pb_plan1.Canvas.TextRect(r,15,5,s,tstyle);
         end;

         for c:=0 to 6 do
         begin
           if assigned(mat.lines[l].colums[c ]) then
           begin
                 s:=mat.lines[l].colums[c ].gethstart+' - '+mat.lines[l].colums[c].gethend;
                 r.Left:=limite + c*tsem;r.Top:=header+hline*(l);
                 r.Width:=tsem;r.height:=hline;
                 pb_plan1.Canvas.TextRect(r,r.left+5,r.top,s,tstyle);
           end;
         end;
         inc(l);
       end;
     end;

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
  sql:=MainData.getQuery('QPL02','SELECT SY_ID, SY_WID, SY_FORMAT, SY_START, SY_END, SY_DETAIL FROM PLANNING WHERE SY_WID=%w');
  sql:=sql.Replace('%w',inttostr(w_id));
  Maindata.readDataSet(query,sql,true);
  MemDataset1.Close;
  Memdataset1.Active:=true;
  while not query.EOF do
  begin
    l:=Query.Fields[0].AsInteger;
    s:=query.Fields[3].AsString;
    start_date:=IsoStrToDate(s);
    s:=query.Fields[4].AsString;
    end_date:=IsoStrToDate(s);
    s:=query.Fields[5].AsString;
    mat.load(s);
    s:=copy(s,1,500);
    MemDataSet1.InsertRecord([l,start_date,end_date,s]);
    query.Next;
  end;
  draw_planning_1;
end;

end.

