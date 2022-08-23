unit Fru_planning;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, StdCtrls, Buttons, Graphics,
  LCLType, LMessages, Dialogs,
  DB, DataAccess,
  ressourcesStrings,
  fpjson,
  BGRABitmapTypes,
  dw_f, DWorker, DCustomer, Dateutils, FSearch, DPlanning, UF_planning_01, UPlanning;

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
    mode: char;
    period: char;
    display: char;
    startdate: tdatetime;

    GPlan: TGPlanning;


  public
    constructor Create(aowner: TComponent); override;
    function CanClose: boolean; override;
    function getcode: shortstring; override;
    function getinfos: shortstring; override;
    procedure init(Data: PtrInt); override;
    procedure init(p_id: longint; j: string); override;
    procedure load_info(sy_id: longint; kind: char);
    procedure remplir_planning;

    procedure setid(p_id: longint);
  end;

implementation

{$R *.lfm}

uses Main;

constructor TFr_planning.Create(aowner: TComponent);

begin
  inherited;
  startdate := today();
  GPlan := TGPlanning.Create(self);
  GPlan.Parent := self;
  mode := 'W';
  period := 'W';
  display := 'T';
end;

function TFr_planning.CanClose: boolean;

begin
  if id > 0 then
  begin
    MainForm.HistoManager.AddHisto(self, id, 'R');
  end;
  Result := True;
end;

procedure TFr_planning.init(Data: PtrInt);

begin
  mode := 'W';
  period := 'W';
  display := 'T';
  Caption := rs_planning;
  startdate := Today();
  startdate := StartOfTheWeek(startdate);
  id := -1;
  remplir_planning;
end;

procedure TFr_planning.init(p_id: longint; j: string);

var
  Data, fjson: TJsonData;
  s: shortstring;
  y, m, d: integer;

begin
  mode := 'W';
  period := 'W';
  display := 'T';
  Caption := rs_planning;
  startdate := Today();

  if j > ' ' then
  begin
    try
      try
        fjson := GetJson(j);
        Data := fjson.findPath('histo.caption');
        if assigned(Data) then
          Caption := Data.AsString;
        Data := fjson.findPath('histo.infos');
        if assigned(Data) then
        begin
          s := Data.AsString;
          if copy(s, 1, 1) = 'C' then
            mode := 'C';
          if copy(s, 3, 1) = '2' then
            period := '2'
          else
          if copy(s, 3, 1) = 'M' then
            period := 'M'
          else
            period := 'W';
          if copy(s, 4, 1) = 'G' then
            display := 'G'
          else
            display := 'T';
          //s = 'W-WT-20220131'
          if not trystrtodate(copy(s, 6, 8), startdate, 'yyyymmdd') then
          begin
            if trystrtoint(copy(s, 6, 4), y) and
              trystrtoint(copy(s, 10, 2), m) and
              trystrtoint(copy(s, 12, 2), d) then
            begin
              tryEncodeDateTime(y, m, d, 0, 0, 0, 0, startdate);
            end;
          end;
        end;
      except
        j := '';
      end;
    finally
      FreeAndNil(fjson)
    end;
  end;
  setid(p_id);
  remplir_planning;
end;

procedure TFr_planning.PlanningDesChanged(var Msg: TLMessage);

var
  uid: longint;

begin
  assert((Msg.wParam = 1) or (Msg.wparam = 2), 'Error Wparam');
  uid := Msg.lParam;
  if (uid > 0) then
  begin
    if Msg.wParam = 1 then
    begin
      mode := 'W';
      self.load_info(uid, mode);
    end;
    if Msg.wparam = 2 then
    begin
      mode := 'C';
      self.load_info(uid, mode);
    end;
  end;

end;

procedure TFr_planning.FrameResize(Sender: TObject);

begin
  gplan.Left := 0;
  gplan.Top := Ed_code.top + Ed_code.Height + 20;
  if self.Width < 720 then
  begin
    gplan.Width := 720;
    gplan.Height := self.Height - gplan.top;
  end
  else
  begin
    gplan.Width := self.Width - 5;
    gplan.Height := self.Height - gplan.top;
  end;
  gplan.FrameResize(self);
end;

procedure TFr_planning.Bt_open_planningClick(Sender: TObject);

var
  f: TF_planning_01;
  uid: longint;

begin
  uid := -1;
  if self.mode = 'W' then
  begin
    uid := self.id;
  end
  else
  begin
    uid := GPlan.getCurrent(self.mode);
  end;
  if uid > 0 then
  begin
    f := TF_planning_01.Create(MainForm);
    f.init(uid,-1);
    f.DefaultMonitor := dmActiveForm;
    f.ShowModal;
    GPlan.reload;
  end;
end;

procedure TFr_planning.SB_rechClick(Sender: TObject);

var
  num: longint;
  f, l, c: shortstring;

begin
  if not assigned(FSearch.Search) then
  begin
    FSearch.Search := TSearch.Create(MainForm);
  end;
  if mode = 'W' then
  begin
    FSearch.Search.init(worker);
  end
  else
  begin
    FSearch.Search.init(Customer);
  end;
  FSearch.Search.showModal;
  Fsearch.Search.get_result(num, f, l, c);
  id := num;

  self.load_info(num, mode);
  remplir_planning;

end;

procedure TFr_planning.SB_previousClick(Sender: TObject);
begin
  startdate := incday(startdate, -7);
  remplir_planning;
end;

procedure TFr_planning.SB_nextClick(Sender: TObject);
begin
  startdate := incday(startdate, 7);
  remplir_planning;
end;


function TFr_planning.getcode: shortstring;

begin
  if mode <> 'C' then
    mode := 'W';
  Result := 'PLN' + mode;
  if id>0 then  Result := Result + '|' + intToHex(id, 4) else
  result:=result+'|0000';
  assert(length(Result) = 9, 'Invalid code string');
end;

function TFr_planning.getinfos: shortstring;

begin
  if assigned(Gplan) then
  begin
    Result := GPlan.getinfos;
  end
  else
  begin
    Result := mode + '-WT-';
    Result := Result + FormatDateTime('YYYYMMDD', startdate);
  end;
  ASSERT(length(Result) = 13, 'Invalid info string');
end;

procedure TFr_planning.load_info(sy_id: longint; kind: char);

var
  query: Tdataset;
  sql: string;
  old_caption: string;

begin
  query := nil;
  ed_code.Text := '';
  ed_name.Text := '';
  old_caption := Caption;
  if kind = 'C' then
  begin
    sql := MainData.getQuery('Q0014',
      'SELECT SY_CODE, SY_FIRSTNAME, SY_LASTNAME FROM CUSTOMER WHERE SY_ID=%id');
  end
  else
  begin
    sql := MainData.getQuery(
      'Q0015', 'SELECT SY_CODE, SY_FIRSTNAME, SY_LASTNAME FROM WORKER WHERE SY_ID=%id');
  end;
  sql := sql.Replace('%id', IntToStr(sy_id));
  Maindata.readDataSet(query, sql, True);
  if query.RecordCount > 0 then
  begin
    ed_code.Caption := query.fields[0].AsString;
    ed_name.Caption := trim(query.fields[1].AsString + ' ' + query.fields[2].AsString);
    id := sy_id;
    Caption := rs_planning + ' ' + ed_name.Caption;
    if (assigned(parent)) and (Caption <> old_caption) then
      parent.Perform(LM_CAPTION_CHANGE, 0, 0);
  end;
  query.Close;
  FreeAndNil(query);
end;

procedure TFr_planning.remplir_planning;

begin
  if (mode <> 'W') and (mode <> 'C') then
    mode := 'W';
  if (period <> 'M') and (period <> '2') and (period <> 'W') then
    period := 'W';
  if (display <> 'T') and (display <> 'G') then
    display := 'T';
  if id > 0 then
  begin
    Gplan.setDateref(startdate);
    Gplan.load(id, startdate, mode, period, display);
  end;
end;


procedure Tfr_planning.setid(p_id: longint);

begin
  if id <> p_id then
  begin
    id := p_id;
    load_info(id, mode);
  end;
end;


end.
