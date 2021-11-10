unit Fru_planning;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, StdCtrls, Buttons, ExtCtrls, Graphics,
  LCLType, EditBtn,
  DB,DataAccess,
  ressourcesStrings,
  fpjson,jsonparser,
  BGRABitmap, BGRABitmapTypes,
  dw_f, DWorker, Dateutils, FSearch, DPlanning, UF_planning_01;

type

  TPlanMode = (pm_week, pm_month, pm_graphweek, pm_graphmonth);

  { TFr_planning }

  TFr_planning = class(TW_F)
    Bt_open_planning: TButton;
    Plan_pb: TPaintBox;
    SB_previous: TBitBtn;
    Ed_date: TDateEdit;

    Ed_code: TEdit;
    Ed_name: TEdit;
    //plan: TPaintBox32;
    SB_next: TBitBtn;
    ScrollBar1: TScrollBar;
    SB_rech: TSpeedButton;


    procedure Bt_open_planningClick(Sender: TObject);
    procedure Ed_dateChange(Sender: TObject);
    procedure FrameResize(Sender: TObject);
    procedure planPaintBuffer(Sender: TObject);
    procedure SB_rechClick(Sender: TObject);
    procedure SB_previousClick(Sender: TObject);
    procedure SB_nextClick(Sender: TObject);

  private
    mode : TPlanMode;
    header,hline,limite : integer;
    startdate : tdatetime;
    col : TInterventions;
    mat : TLPlanning;


  public
    function CanClose : boolean;override;
    procedure draw_week;
    function getcode : shortstring;override;
    function getinfos : shortstring;override;
    procedure init(Data: PtrInt); override;
    procedure init(p_id : longint;j : string);override;

    procedure remplir_planning;

    procedure setid(p_id : longint);
    destructor Destroy;override;
  end;

implementation

{$R *.lfm}

uses Main;

function TFr_planning.CanClose : boolean;

begin
  if id>0 then
  begin
    MainForm.HistoManager.AddHisto(self, id, 'R');
  end;
  result:=true;
end;

procedure TFr_planning.init(Data: PtrInt);

begin
  mode:=pm_week;
  Caption := rs_planning;
  startdate:=Today();
  startdate:=StartOfTheWeek(startdate);
  ed_date.date:=StartDate;
  id:=-1;
  if parent is TWincontrol then
  begin
    TWincontrol(parent).Caption := Caption;
  end;
  remplir_planning;
end;

procedure TFr_planning.init(p_id : longint;j : string);

var data,fjson : TJsonData;
    s : shortstring;
    y,m,d : integer;

begin
  mode:=pm_week;
  Caption := rs_planning;
  startdate:=Today();

  if assigned(col) then freeandnil(col);
  if j>' ' then
  begin
    try
       try
          fjson:=GetJson(j);
          data:=fjson.findPath('histo.caption');
          if assigned(data) then caption:=data.AsString;
          data:=fjson.findPath('histo.infos');
          if assigned(data) then
          begin
              s:=data.AsString;
              if copy(s,3,2)='WT' then mode:=pm_week;
              if copy(s,3,2)='MT' then mode:=pm_month;
              if copy(s,3,2)='WG' then mode:=pm_graphweek;
              if copy(s,3,2)='MG' then mode:=pm_graphmonth;
              if not trystrtodate(copy(s,6,8),startdate,'yyyymmdd') then
              begin
                if trystrtoint(copy(s,6,4),y) and
                trystrtoint(copy(s,10,2),m) and
                trystrtoint(copy(s,12,2),d) then
                begin
                  tryEncodeDateTime(y,m,d,0,0,0,0,startdate);
                end;
              end;
          end;
       except
         j:='';
       end;
    finally
      freeAndNil(fjson)
    end;
  end;
  setid(p_id);
  startdate:=StartOfTheWeek(startdate);
 // ed_date.date:=StartDate;


  if parent is TWincontrol then
  begin
    TWincontrol(parent).Caption := Caption;
  end;
  remplir_planning;
end;

procedure TFr_planning.planPaintBuffer(Sender: TObject);


var w,h : integer;

begin
  w:=plan_pb.Width;
  h:=Plan_pb.height;

  plan_pb.Canvas.Clear;
  plan_pb.Canvas.Pen.Color:=clBlack;
  plan_pb.Canvas.pen.Width:=1;
  plan_pb.Canvas.Brush.Color:=$00E6FFFF;
  plan_pb.Canvas.FrameRect(0,0,w,h);
  plan_pb.canvas.Rectangle(0,0,w,h);

  case mode of
       pm_week : draw_week;
  end;

end;

procedure TFr_planning.FrameResize(Sender: TObject);

begin
  plan_pb.Left:=0;
  plan_pb.Top:=Ed_code.top+Ed_code.height+20;
  if self.Width<720 then
  begin
       plan_pb.Width:=720;
       plan_pb.height:=self.height - plan_pb.top;
       Scrollbar1.Visible:=false;
  end else
  begin
    Scrollbar1.Visible:=true;
    plan_pb.Width:=self.Width - Scrollbar1.width - 5;
    plan_pb.height:=self.height - plan_pb.top;
    scrollbar1.Top:=plan_pb.top;
    scrollbar1.Height:=plan_pb.height;
  end;

  header:=80;
  hline:=60;
  limite:=plan_pb.Width div 4;

  ed_date.Top:=plan_pb.Top+5;
  ed_date.left:=plan_pb.left+((limite - ed_date.Width) div 2);
  sb_previous.Top:=ed_date.top;
  sb_previous.Left:=ed_date.left - sb_previous.Width - 10;
  sb_next.top :=ed_date.top;
  sb_next.Left:=ed_date.Left+ed_date.Width + 10;
  sb_next.BringToFront;
  sb_previous.bringToFront;
  ed_date.BringToFront;
end;

procedure TFr_planning.Ed_dateChange(Sender: TObject);

var start : Tdatetime;

begin
  start:=Ed_date.Date;
  start:=StartOfTheWeek(start);
  Ed_date.Date:=start;
  if start<>startdate then
  begin
    startdate:=start;
    remplir_planning;
  end;
end;

procedure TFr_planning.Bt_open_planningClick(Sender: TObject);

var f : TF_planning_01;

begin
  f:=TF_planning_01.Create(MainForm);
  f.w_id:=self.id;
  f.ShowModal;
end;

procedure TFr_planning.SB_rechClick(Sender: TObject);

var num : longint;
    start : Tdatetime;
    f,l,c : shortstring;

begin
  if not assigned(FSearch.Search) then
  begin
       FSearch.Search:= TSearch.create(MainForm);
  end;
  FSearch.Search.init(worker);
  FSearch.Search.showModal;
  Fsearch.Search.get_result(num,f,l,c);
  id:=num;
  Ed_code.Text:=c;
  ed_name.Caption:=l+' '+f;

  remplir_planning;
  if id>0 then
  begin
    Caption := rs_planning+' ('+TRIM(c)+') '+trim(l);
    MainForm.HistoManager.AddHisto(self, id, 'R');
    if parent is TWincontrol then
    begin
         TWincontrol(parent).Caption := Caption;
    end;
  end;

end;

procedure TFr_planning.SB_previousClick(Sender: TObject);
begin
  startdate:=incday(startdate,-7);
  remplir_planning;
end;

procedure TFr_planning.SB_nextClick(Sender: TObject);
begin
  startdate:=incday(startdate,7);
  remplir_planning;
end;

procedure TFr_planning.draw_week;

var w,h : integer;
  tsem : integer;
  i,l,c : integer;
  s : shortstring;
  r : trect;
  tmpdate : tdatetime;
  tstyle : TTextStyle;


begin

     w:=plan_pb.Width;
     h:=Plan_pb.height;

     tsem := (w - limite) div 7;

     //Header
     plan_pb.Canvas.Brush.color:=TColor($FFF8DC);
     plan_pb.Canvas.Brush.Style:=bsSolid;
     plan_pb.Canvas.FillRect(1,1,w-1,header);
     plan_pb.Canvas.pen.Color:=clblack;

     plan_pb.canvas.Rectangle(0,1,w-1,header-1);


     plan_pb.Canvas.pen.color:=clBlue;
     plan_pb.canvas.Line(limite,1,limite,h - 1);
     tmpdate:=startdate;
     tstyle.alignment:=taCenter;
     tstyle.Opaque:=false;
     tstyle.SingleLine:=false;
     tstyle.Wordbreak:=true;
     tstyle.Clipping:=true;
     tstyle.systemFont:=true;
     tstyle.rightToLeft:=false;
     for i:=0 to 6 do
     begin
       if i>0 then plan_pb.Canvas.Line(limite + i*tsem,1,limite+ i*tsem,h - 1);
       r.Left:=limite + i*tsem;r.right:=r.left+tsem;
       r.top:=2;r.bottom:=header;
       s:=cdays[DayOfTheWeek(tmpdate)];
       plan_pb.Canvas.TextRect(r,0,0,s,tstyle);
       r.top:=20;
       s:=datetostr(tmpdate);
       plan_pb.Canvas.TextRect(r,0,0,s,tstyle);
       tmpdate:=incday(tmpdate,1);
     end;


//     plan.Buffer.Line(0,header,w,header,color32(0,0,128,255),true);

     l:=0;
     plan_pb.Canvas.Brush.Style:=bsclear;
     if assigned(mat) then
     begin
       while (mat.lines[l].sy_id>0) and (l<mat.linescount) do
       begin
         if (l<mat.linescount - 1) and (mat.lines[l].sy_id<>mat.lines[l+1].sy_id) then
         begin
              plan_pb.canvas.Line(0,header+hline*(l+1),w,header+hline*(l+1));
         end else
         begin
              plan_pb.canvas.Line(limite,header+hline*(l+1),w,header+hline*(l+1));
         end;
         if (l=0) or (mat.lines[l].sy_id<>mat.lines[l-1].sy_id) then
         begin
              r.left:=10;r.right:=limite;
              r.bottom:=header+hline*(l+1);r.top:=r.bottom-hline;
              tstyle.Alignment:=taLeftJustify;
              c:=mat.lines[l].index;
              s:=mat.libs[c].code+' '+mat.libs[c].caption;
              plan_pb.Canvas.TextRect(r,15,5,s,tstyle);
         end;

         for c:=0 to 6 do
         begin
           if assigned(mat.lines[l].colums[c ]) then
           begin
                 s:=mat.lines[l].colums[c ].gethstart+' - '+mat.lines[l].colums[c].gethend;
                 r.Left:=limite + c*tsem;r.Top:=header+hline*(l);
                 r.Width:=tsem;r.height:=hline;
                 plan_pb.Canvas.TextRect(r,r.left+5,r.top,s,tstyle);
           end;
         end;
         inc(l);
       end;
     end;

end;

function TFr_planning.getcode : shortstring;

var code : char;

begin
//   result:='F'+copy(table.table,1,3)+'|'+intToHex(id,4);
  code:='W'; // W=Worker, C=Customer
  result:='PLN'+code;
  result:=result+'|'+intToHex(id,4);
end;

function TFr_planning.getinfos : shortstring;
begin
  result:='W'+'-'; // W=Worker, C=Customer
  case mode of
       pm_week : result:=result+'WT';
       pm_month : result:=result+'MT';
       pm_graphweek : result:=result+'WG';
       pm_graphmonth : result:=result+'MG';
  end;
  result:=result+'-';
  result:=result+FormatDateTime('YYYYMMDD',startdate);

end;



procedure TFr_planning.remplir_planning;

var  inter : Tintervention;
     enddate : tdatetime;
     l, c : integer;
     old : longint;
     query : tdataset;
     sql,s : string;

begin
   if assigned(col) then freeAndNil(col);
   query:=nil;
   old:=-1;

   ed_date.Caption:=datetostr(startdate);
   if assigned(mat) then freeandnil(mat);

   if id>0 then
   begin
     enddate:=EndOfTheWeek(startdate);
     col:=Planning.loadW(id,startdate, enddate);
     mat:=TLPlanning.create(startdate,enddate);
     mat.load(col);
   end;
   plan_pb.Refresh;
end;


procedure Tfr_planning.setid(p_id : longint);

var Query : tdataset;
    sql : string;

begin
  if id<>p_id then
  begin
    Query:=nil;
    id:=p_id;
    Caption := rs_planning;
    sql:=Maindata.getQuery('<Q0014>','SELECT SY_CODE, SY_FIRSTNAME, SY_LASTNAME FROM WORKER WHERE SY_ID=%id');
    sql:=sql.replace('%id',inttostr(id));
    MainData.readDataSet(Query,sql,true);
    if Query.RecordCount>0 then
    begin
         Ed_code.Text:=Query.Fields[0].AsString;
         ed_name.Caption:=Query.Fields[2].AsString+' '+Query.Fields[1].AsString;
         Caption := rs_planning+' ('+TRIM(Query.Fields[0].AsString)+') '+trim(Query.Fields[2].AsString);
    end;
    Query.close;
    Query.Free;
    if parent is TWincontrol then
    begin
         TWincontrol(parent).Caption := Caption;
    end;
  end;
end;

destructor TFr_planning.Destroy;

begin
  inherited;
  if assigned(col) then freeAndNil(col);
  if assigned(mat) then freeAndNil(mat);
end;

end.

