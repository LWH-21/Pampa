unit fru_person;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, ComCtrls, Buttons, DBCtrls, Dialogs, LCLType,
  Graphics, ExtCtrls, Menus, StdCtrls,  dw_f, FSearch,
  Forms, ZDataset,
  dworker, DA_table, DataAccess, Datapanel, SQLDB, DB,
  UException, RessourcesStrings, fpjson, jsonparser;
type

  { TFr_Person }

  TFr_Person = class(TW_F)
    Bsearch: TBitBtn;
    DBCode: TDBEdit;
    DBidentite: TDBText;
    MenuItem1: TMenuItem;
    MenuItem2: TMenuItem;
    MenuItem3: TMenuItem;
    Panel1: TPanel;
    PopupMenu1: TPopupMenu;
    Source: TDataSource;
    Query : TDataset;
    PageControl1: TPageControl;
    procedure BsearchClick(Sender: TObject);
    procedure DBCodeChange(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure PageControl1Change(Sender: TObject);
    procedure PageControl1Resize(Sender: TObject);

  private
    Json : TJSONData;
    Maction : char; // CRUD :  Create, Read, Update, Delete
    table : TDA_table;
  public
    constructor Create(AOwner: TComponent; t : TDA_table);
    function CanClose: boolean; override;
    procedure init(Data: PtrInt); override;
    procedure init(s_id : longint;j : string);override;
    procedure InitIhm;
    function IsModified: boolean; override;
    function getcode : shortstring;override;
    function getinfos : shortstring;override;
    procedure open;override;
    procedure save(Data: PtrInt); override;
    function Search(var num : longint) : integer;
    procedure delete(Data: PtrInt); override;
    procedure close;override;

  end;

implementation

uses Main;

{$R *.lfm}

constructor TFr_Person.Create(AOwner: TComponent; t : TDA_table);

var
  nom : string;
  code : string;
  js : string;


begin
  inherited create(AOwner);
  assert(assigned(t),'Table is not assigned');
  id := -2;
  table:=t;
  if MainData.cmode='ZEO' then
  begin
       query:=TZQuery.create(self);
       TZQuery(query).connection:=Maindata.ZConnection;
  end else
  begin
       query:=TSQLQuery.create(self);
       TSQLQuery(query).DataBase:=MainData.Database;
       TSQLQuery(query).transaction:=MainData.tran;
       TSQLQuery(query).Options:=[sqoKeepOpenOnCommit];
  end;
  Source.DataSet:=Query;
  nom:='Tfr_'+trim(table.table);
  nom:=uppercase(nom);
  json:=MainData.getIhm(Mainform.username,nom);

  IF json.Count=0 then
  begin
        json.Free;
        code:=table.table;
        code:=code.Substring(0,3)+'001';
        js:='{WINDOW:{ID:"'+nom+'",USR:"admin",Content:{TAB:[{CLASS:"SELF",NAME:"'+code+'",CAPTION:"Defaut:", HINT:"Defaut"}]}}}';
        json:=GetJson(js);
        MainData.SaveIhm(nom,js);
  end;
  initIhm;
end;

procedure TFr_Person.BsearchClick(Sender: TObject);

var ts : TTabSheet;

begin
  if not CanClose then
    exit;
  case Search(id) of
    mrOk:
    begin
      if id >= -1 then
      begin
        if id >= 0 then
        begin
          open;
        end
        else
        if id = -1 then
        begin
          Caption :=rs_new;
          Maction:='C';
          table.Insert(Query);
        end
        else
        begin
          if Query.RecordCount = 0 then
          begin
            Close;
            if self.Parent is TTabSheet then
            begin
                 try
                    ts := self.Parent as TTabSheet;
                    if assigned(ts) then ts.free;
                 except
                 end;
            end;
            exit;
          end;
        end;
      end;
    end;
    mrYes:
    begin
      Caption :=rs_new;
      Maction:='C';
      Query.Close;
      table.Insert(Query);
    end;
    else
    begin
      if Query.RecordCount = 0 then
      begin
        Close;
        if self.Parent is TTabSheet then
        begin
             try
                ts := self.Parent as TTabSheet;
                if assigned(ts) then ts.free;
             except
             end;
        end;
        exit;
      end;
    end;
  end;
end;

procedure TFr_Person.DBCodeChange(Sender: TObject);
begin

end;

procedure TFr_Person.FormResize(Sender: TObject);

var x : integer;

begin
     DBCode.left:=8;
     DBCode.top:=8;
     Bsearch.top := DBCode.top;
     Bsearch.left:=DBCode.left + DbCode.Width+8;
     Bsearch.Height := DBCode.Height;
     Panel1.top := DBCode.top;
     Panel1.left:=Bsearch.left + Bsearch.Width+8;
     Panel1.width := width - Panel1.left - 864;
     Panel1.height := DBCode.height;
     PageControl1.left:=0;
     PageControl1.top:=Dbcode.top + DBCode.height + 8;
     PageControl1.width:=Width - 8;
     PageControl1.height := height - PageControl1.top - 8;
     if PageControl1.PageCount>0 then
     begin
       if assigned(PageControl1.Pages[0]) then
       begin
            x:=PageControl1.Pages[0].width;
            Panel1.Width:=PageControl1.Pages[0].width - Panel1.Left;
       end;
     end else
     begin
       Panel1.Width:=PageControl1.width - Panel1.Left;
     end;
end;


procedure TFr_Person.PageControl1Change(Sender: TObject);

var ts : ttabsheet;
    t  : tcontrol;
    dp : Tdatapanel;
    j  : integer;

begin
  ts:=pagecontrol1.ActivePage;
  if assigned(ts) then
  begin
    for j:=0 to ts.ControlCount - 1 do
    begin
         t := ts.Controls[j];
         if t is Tdatapanel then
         begin
              dp := Tdatapanel(t);
              dp.left:=0;
              dp.top:=0;
              dp.width:=ts.Width;
              dp.height:=ts.Height;
         end;
    end;
  end;
end;

procedure TFr_Person.PageControl1Resize(Sender: TObject);

var ts : ttabsheet;
    t  : tcontrol;
    i,j : integer;
    dp : Tdatapanel;

begin
  try
    try
     for i:=0 to pagecontrol1.PageCount - 1 do
     begin
       ts:=pagecontrol1.pages[i];
       for j:=0 to ts.ControlCount - 1 do
       begin
         t := ts.Controls[j];
         if t is Tdatapanel then
         begin
           dp := Tdatapanel(t);
           dp.left:=0;
           dp.top:=0;
           dp.width:=ts.Width;
           dp.height:=ts.Height;
         end;
       end;
     end;
    except
      // Mute exception
    end;
  finally
    inherited;
  end;
end;

function TFr_Person.CanClose: boolean;

var
  reply: integer;

begin
  if visible then self.SetFocus else exit;
  if isModified then
  begin
    reply := QuestionDlg(rs_demande_confirmation, rs_abandonner_modif,
      mtConfirmation, [mrNo, rs_non, 'IsDefault', mrYes, rs_oui], 0);
    if reply = mrYes then
    begin
      Result := True;
    end
    else
      Result := False;
  end
  else
    Result := True;
end;

(* Close Query & Frame                                           *)
procedure TFr_Person.close;

var ts : ttabsheet;
    t  : tcontrol;
    i,j : integer;
    dp : Tdatapanel;

begin
  try
    try
     for i:=0 to pagecontrol1.PageCount - 1 do
     begin
       ts:=pagecontrol1.pages[i];
       for j:=0 to ts.ControlCount - 1 do
       begin
         t := ts.Controls[j];
         if t is Tdatapanel then
         begin
           dp := Tdatapanel(t);
           dp.setDesign(false);
         end;
       end;
     end;

     // if (DP_INTERVENANT_ETATCIVIL.designmode) then  DP_INTERVENANT_ETATCIVIL.DesignMode:=false;
      Query.close;
      Query.Active:=false;
      freeAndNil(json);

    except
      // Mute exception
    end;
  finally
    inherited;
  end;
end;


procedure TFr_Person.init(Data: PtrInt);

begin
  if id = -2 then
  begin
    BsearchClick(self);
  end else
  if id>0 then
  begin
    open;
  end;
end;

procedure TFr_Person.init(s_id : longint;j : string);

begin
  id:=s_id;
end;

procedure TFr_Person.InitIhm;

var  ts : ttabsheet;
     dp : Tdatapanel;
     data : TJsonData;
     jObject : TJSONObject;
     i,index : integer;
     sclass,sname,scaption,shint : shortstring;


begin
   while pagecontrol1.PageCount>0 do
   begin
     ts:=pagecontrol1.Pages[0];
     ts.Free;
   end;
   if not assigned(json) then exit;
   data:=Json.findPath('WINDOW.Content.TAB');
   if assigned(data) and (data.JSONType=jtarray) then
   begin
         for i:=0 to Data.Count-1 do
         begin
              sclass:='';sname:='';scaption:='';shint:='';
              jObject:=TJSONArray(Data).Objects[i];
              IF assigned(jObject) then
              begin
                index:=jObject.indexOfName('CLASS');
                if index>=0 then
                begin
                     sclass:=jObject.Items[index].asstring;
                end;
                index:=jObject.indexOfName('NAME');
                if index>=0 then
                begin
                     sname:=jObject.Items[index].asstring;
                end;
                index:=jObject.indexOfName('CAPTION');
                if index>=0 then
                begin
                     scaption:=jObject.Items[index].asstring;
                end;
                index:=jObject.indexOfName('HINT');
                if index>=0 then
                begin
                     shint:=jObject.Items[index].asstring;
                end;

                if sclass>'' then
                begin
                   ts:=pagecontrol1.AddTabSheet;
                   ts.Caption:=scaption;
                   ts.Hint:=shint;
                   if shint>' ' then ts.ShowHint:=true;
                   if sclass='SELF' then
                   begin
                        dp:=Tdatapanel.create(ts, sname);
                        dp.Left:=0;
                        dp.top:=0;
                        dp.SetDataSource(source,table.table);
                        dp.setTable(table.table, Maindata.tablesdesc);
                        dp.init(MainForm.username);
                        dp.Width:=ts.Width;
                        dp.Height:=ts.Height;
                   end;
                end;

              end;
         end;
   end;
   FormResize(self);
end;

function TFr_Person.IsModified: boolean;

begin
  if (not assigned(Query)) or (Query.IsEmpty) or (Query.RecordCount = 0) then
  begin
    Result := False;
  end
  else
  begin

    Result := Query.Modified;
  end;
end;

function TFr_Person.getcode : shortstring;

begin
  result:='F'+copy(table.table,1,3)+'|'+intToHex(id,4);
end;

function TFr_Person.getinfos : shortstring;
begin
  result:='';
end;

procedure TFr_Person.open;

begin
  assert(id>0,'ID NOT > 0');
  Maction:='R';
  try
    table.Read(Query,id);
    if query.RecordCount = 1 then
    begin
        caption:=  Query.FieldByName('SY_CODE').AsString;
        Caption := '('+TRIM(caption)+') '+Query.FieldByName('SY_LASTNAME').AsString;
        Caption:=trim(caption)+' '+Query.FieldByName('SY_FIRSTNAME').AsString;
        Caption:=trim(caption);
        MainForm.HistoManager.AddHisto(self, id, 'R');
    end;
  except
    on e : exception do Error(e, dber_system,'TFr_Person.open SY_ID='+inttostr(id));
  end;
  if parent is TWincontrol then
  begin
    TWincontrol(parent).Caption := Caption;
  end;
end;

procedure TFr_Person.save(Data: PtrInt);

var
  Result: TDbErrcode;

begin
  try
    if (assigned(Query)) and (not Query.IsEmpty) then
    begin
      self.SetFocus;
      if (Maction='R') and (Query.Modified) then Maction:='U';
      Result := table.Write(Query,id);
      if result=dber_none then
      begin
           if Maction='C' then
           begin
             table.read(Query,id);
             if query.RecordCount = 1 then
             begin
                  caption:=  Query.FieldByName('SY_CODE').AsString;
                  Caption := '('+TRIM(caption)+') '+Query.FieldByName('SY_LASTNAME').AsString;
                  Caption:=trim(caption)+' '+Query.FieldByName('SY_FIRSTNAME').AsString;
                  Caption:=trim(caption);
             end;
           end;
           if Maction='D' then BsearchClick(self);
           MainForm.HistoManager.AddHisto(self, id, Maction);
      end;
    end;
  except
    on e : exception do Error(e, dber_system,'TFr_Person.save SY_ID='+inttostr(id));
  end;
end;

procedure TFr_Person.Delete(Data: PtrInt);

var
  Result: TDbErrcode;
  reply: integer;
  b: boolean;

begin
  b := query.isempty;
  if (assigned(Query)) and (not Query.IsEmpty) then
  begin
    reply := QuestionDlg(rs_demande_confirmation, rs_supprimer,
       mtConfirmation, [mrNo, rs_non, 'IsDefault', mrYes, rs_oui], 0);
     if reply <> mrYes then exit;

    self.SetFocus;

    table.Delete(Query,id);
    Result := table.Write(Query,id);
    if result=dber_none then
    begin
      BsearchClick(self);
    end;
  end;
  MainForm.HistoManager.AddHisto(self, id, Maction);
end;

function TFr_Person.Search(var num : longint) : integer;

begin
  if not assigned(FSearch.Search) then
  begin
       FSearch.Search:= TSearch.create(MainForm);
  end;
  FSearch.Search.init(table);
  FSearch.Search.set_num_int(num);
  Result:=FSearch.Search.showModal;
  num:=FSearch.Search.get_num_int;
end;

end.
