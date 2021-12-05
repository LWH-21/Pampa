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
  dw_f, DWorker, Dateutils, FSearch, DPlanning, UF_planning_01, UPlanning;

type

  TPlanMode = (pm_week, pm_month, pm_graphweek, pm_graphmonth);

  { TFr_planning }

  TFr_planning = class(TW_F)
    Bt_open_planning: TButton;

    Ed_code: TEdit;
    Ed_name: TEdit;
    SB_rech: TSpeedButton;


    procedure Bt_open_planningClick(Sender: TObject);
    procedure CheckBox1Change(Sender: TObject);
    procedure CheckBox1Click(Sender: TObject);
    procedure Ed_dateChange(Sender: TObject);
    procedure FrameResize(Sender: TObject);
    procedure GPlanResize(Sender: TObject);
    procedure planPaintBuffer(Sender: TObject);
    procedure SB_rechClick(Sender: TObject);
    procedure SB_previousClick(Sender: TObject);
    procedure SB_nextClick(Sender: TObject);

  private
    mode : TPlanMode;
    header,hline,limite : integer;
    startdate : tdatetime;


    GPlan: TGPlanning;


  public
    constructor create(aowner: TComponent); override;
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

constructor TFr_planning.create(aowner: TComponent);

begin
  inherited;
  startdate:=today();
  GPlan:= TGPlanning.create(self);
  GPlan.Parent:=self;
end;

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

  //if assigned(col) then freeandnil(col);
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



  if parent is TWincontrol then
  begin
    TWincontrol(parent).Caption := Caption;
  end;
  remplir_planning;
end;

procedure TFr_planning.planPaintBuffer(Sender: TObject);


var w,h : integer;

begin
{  w:=plan_pb.Width;
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
      }
end;

procedure TFr_planning.FrameResize(Sender: TObject);

begin
  gplan.Left:=0;
  gplan.Top:=Ed_code.top+Ed_code.height+20;
  if self.Width<720 then
  begin
       gplan.Width:=720;
       gplan.height:=self.height - gplan.top;
  end else
  begin
    gplan.Width:=self.Width - 5;
    gplan.height:=self.height - gplan.top;
  end;
  gplan.FrameResize(self);
  header:=80;
  hline:=60;


 // limite:=plan_pb.Width div 4;


end;

procedure TFr_planning.GPlanResize(Sender: TObject);
begin

end;

procedure TFr_planning.Ed_dateChange(Sender: TObject);

var start : Tdatetime;

begin

end;

procedure TFr_planning.Bt_open_planningClick(Sender: TObject);

var f : TF_planning_01;

begin
  f:=TF_planning_01.Create(MainForm);
  f.w_id:=self.id;
  f.DefaultMonitor:=dmActiveForm;
  f.ShowModal;
end;

procedure TFr_planning.CheckBox1Change(Sender: TObject);
begin

end;

procedure TFr_planning.CheckBox1Click(Sender: TObject);
begin

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
   if id>0 then
   begin
     enddate:=EndOfTheWeek(startdate);
     Gplan.load(id,startdate);
   end;
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
 // if assigned(col) then freeAndNil(col);

end;

end.

