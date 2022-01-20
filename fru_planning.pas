unit Fru_planning;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, StdCtrls, Buttons, Graphics,
  LCLType,LMessages,Dialogs,
  DB,DataAccess,
  ressourcesStrings,
  fpjson,
  BGRABitmapTypes,
  dw_f, DWorker, DCustomer,Dateutils, FSearch, DPlanning, UF_planning_01, UPlanning;

type

  //TPlanMode = (pm_week, pm_month, pm_graphweek, pm_graphmonth);

  { TFr_planning }

  TFr_planning = class(TW_F)
    Bt_open_planning: TButton;

    Ed_code: TEdit;
    Ed_name: TEdit;
    SB_rech: TSpeedButton;


    procedure Bt_open_planningClick(Sender: TObject);
    procedure FrameResize(Sender: TObject);
    procedure PlanningDesChanged(var Msg: TLMessage); message LM_PLANNING_DEST_CHANGE;
    procedure SB_rechClick(Sender: TObject);
    procedure SB_previousClick(Sender: TObject);
    procedure SB_nextClick(Sender: TObject);


  private
    mode : char;
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
    procedure load_info(sy_id : longint; kind : char);
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
  mode:='W';
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
  mode:='W';
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

procedure TFr_planning.PlanningDesChanged(var Msg: TLMessage);

var uid : longint;

begin
  assert((Msg.wParam=1) or (Msg.wparam=2),'Error Wparam');
  uid:=Msg.lParam;
  if (id>0) then
  begin
    if Msg.wParam=1 then
    begin
         mode:='W';
         self.load_info(uid,mode);
    end;
    if Msg.wparam=2 then
    begin
      mode:='C';
      self.load_info(uid,mode);
    end;
  end;

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

procedure TFr_planning.Bt_open_planningClick(Sender: TObject);

var f : TF_planning_01;

begin
  f:=TF_planning_01.Create(MainForm);
  f.w_id:=self.id;
  f.DefaultMonitor:=dmActiveForm;
  f.ShowModal;
  GPlan.reload;
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
  if mode='W' then
  begin
    FSearch.Search.init(worker);
  end else
  begin
       FSearch.Search.init(Customer);
  end;
  FSearch.Search.showModal;
  Fsearch.Search.get_result(num,f,l,c);
  id:=num;

  self.load_info(num,mode);
  remplir_planning;



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
  result:=mode+'-'; // W=Worker, C=Customer
  result:=result+'WT';
  (*case mode of
       pm_week : result:=result+'WT';
       pm_month : result:=result+'MT';
       pm_graphweek : result:=result+'WG';
       pm_graphmonth : result:=result+'MG';
  end;        *)
  result:=result+'-';
  result:=result+FormatDateTime('YYYYMMDD',startdate);

end;

procedure TFr_planning.load_info(sy_id : longint; kind : char);

var query : Tdataset;
    sql : string;

begin
  query:=nil;
  ed_code.text:='';
  ed_name.text:='';
  if kind='C' then
  begin
    sql:='SELECT SY_CODE, SY_FIRSTNAME, SY_LASTNAME FROM CUSTOMER WHERE SY_ID=%id';
  end else
  begin
       sql:=MainData.getQuery('Q0014','SELECT SY_CODE, SY_FIRSTNAME, SY_LASTNAME FROM WORKER WHERE SY_ID=%id');
  end;
  sql:=sql.Replace('%id',inttostr(sy_id));
  Maindata.readDataSet(query,sql,true);
  if query.RecordCount>0 then
  begin
       ed_code.caption:=query.fields[0].asString;
       ed_name.caption:=query.fields[1].asString+' '+query.fields[2].asString;
  end;
  query.close;
  freeAndNil(query);
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

