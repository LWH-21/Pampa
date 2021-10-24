unit Main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Menus, ExtCtrls,StrUtils,
  ComCtrls, Buttons, ActnList,
  Generics.Collections,
  W_A, dw_f, Dataaccess,
  DWorker, DCustomer,DPlanning,
  UHistoManager,UFbdd, ufhistosup,
  Fru_person,UTW_Tab,UFCustomDp,UFbookmark,UCfg_table,
  UFcnx,
  {$IFDEF WINDOWS}Windows,{$ENDIF}
  Types,
  {$IFDEF DEBUG}LazLogger,{$ENDIF}
  RessourcesStrings, Fru_planning, UFr_histo;

type

  TNotify = (no_open, no_close, no_intab, no_inwindow);
  TNotifySet = set of TNotify;
  TFenList = specialize TList <TW_F>;

  { TMainForm }

  TMainForm = class(TW_A)
    Act_customer: TAction;
    Act_cnx: TAction;
    Arr_TileHorizontal: TAction;
    Arr_Cascade: TAction;
    Act_affhisto: TAction;
    Act_planning: TAction;
    Act_export: TAction;
    Act_new_intervenant: TAction;
    Act_insert: TAction;
    Act_delete: TAction;
    Act_unbookmark: TAction;
    Act_bookmark: TAction;
    Act_refresh: TAction;
    Act_towindow: TAction;
    Act_closetab: TAction;
    Act_Save: TAction;
    Act_worker: TAction;
    Fr_Histo1: TFr_Histo;
    IdleTimer: TIdleTimer;
    Images: TImageList;
    Mconnection: TMenuItem;
    MDisplay: TMenuItem;
    MBookmark: TMenuItem;
    MClosetab: TMenuItem;
    MDelHisto: TMenuItem;
    MenuItem1: TMenuItem;
    MBDD: TMenuItem;
    MCascade: TMenuItem;
    MenuItem3: TMenuItem;
    MI_table: TMenuItem;
    MMark: TMenuItem;
    MLHisto: TMenuItem;
    MLBookMark: TMenuItem;
    MW09: TMenuItem;
    MW10: TMenuItem;
    MW07: TMenuItem;
    MW08: TMenuItem;
    MW05: TMenuItem;
    MW06: TMenuItem;
    MW03: TMenuItem;
    MW04: TMenuItem;
    MW01: TMenuItem;
    MW02: TMenuItem;
    N2: TMenuItem;
    Mwindows: TMenuItem;
    MPlanning: TMenuItem;
    MExport: TMenuItem;
    MNewIntervenant: TMenuItem;
    MInsert: TMenuItem;
    MenuItem2: TMenuItem;
    Mhisto9: TMenuItem;
    Mhisto7: TMenuItem;
    Mhisto8: TMenuItem;
    Mhisto5: TMenuItem;
    Mhisto6: TMenuItem;
    Mhisto3: TMenuItem;
    Mhisto4: TMenuItem;
    Mhisto1: TMenuItem;
    Mhisto2: TMenuItem;
    MHistoN2: TMenuItem;
    MShowHisto: TMenuItem;
    MToWindow: TMenuItem;
    N1: TMenuItem;
    MSave: TMenuItem;
    MRefresh: TMenuItem;
    MPanel: TMenuItem;
    MToolbars: TMenuItem;
    MHelp: TMenuItem;
    MTools: TMenuItem;
    MenuItem4: TMenuItem;
    Mbenef: TMenuItem;
    Mimport: TMenuItem;
    MIntervenant: TMenuItem;
    NewDB: TMenuItem;
    Act_exit: TAction;
    ActionList1: TActionList;
    MainMenu1: TMainMenu;
    MFile: TMenuItem;
    MEdit: TMenuItem;
    MNew: TMenuItem;
    MOpen: TMenuItem;
    Onglet: TPageControl;
    SB_save: TSpeedButton;
    SB_quit: TSpeedButton;
    SB_planning: TSpeedButton;
    Splitter: TSplitter;
    SP_insert: TSpeedButton;
    SP_Delete: TSpeedButton;
    SP_refresh: TSpeedButton;
    SP_towindow: TSpeedButton;
    SP_closetab: TSpeedButton;
    Timer1: TTimer;
    ToolBar1: TToolBar;
    MHisto: TMenuItem;
    MExit: TMenuItem;
    StatusBar1: TStatusBar;
    ToolButton1: TToolButton;
    ToolButton2: TToolButton;
    SB_bookmark: TToolButton;


    procedure Act_bookmarkExecute(Sender: TObject);
    procedure Act_cnxExecute(Sender: TObject);
    procedure Act_customerExecute(Sender: TObject);
    procedure Arr_CascadeExecute(Sender: TObject);
    procedure Act_affhistoExecute(Sender: TObject);
    procedure Act_deleteExecute(Sender: TObject);
    procedure Act_exportExecute(Sender: TObject);
    procedure Act_planningExecute(Sender: TObject);
    procedure Act_refreshExecute(Sender: TObject);
    procedure Arr_TileHorizontalExecute(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: boolean);
    procedure FormShow(Sender: TObject);
    procedure IdleTimerTimer(Sender: TObject);
    procedure MBDDClick(Sender: TObject);
    procedure MDelHistoClick(Sender: TObject);
    procedure MDisplayClick(Sender: TObject);
    procedure MCascadeClick(Sender: TObject);
    procedure MhistoClick(Sender: TObject);
    procedure MI_tableClick(Sender: TObject);
    procedure MWindowClick(Sender: TObject);
    procedure MwindowsClick(Sender: TObject);
    procedure OngletChange(Sender: TObject);
    procedure OngletDragDrop(Sender, Source: TObject; X, Y: Integer);
    procedure OngletDragOver(Sender, Source: TObject; X, Y: Integer;
      State: TDragState; var Accept: Boolean);
    procedure Page0ContextPopup(Sender: TObject; MousePos: TPoint;
      var Handled: boolean);
    procedure SplitterMoved(Sender: TObject);
    function TabClose(Sender: TObject) : boolean;
    procedure TabToWindow(Sender: TObject);
    procedure Act_SaveExecute(Sender: TObject);
    procedure Act_workerExecute(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormResize(Sender: TObject);
    procedure MFileClick(Sender: TObject);
    procedure MimportClick(Sender: TObject);
    procedure Act_exitExecute(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure TS_indContextPopup(Sender: TObject; MousePos: TPoint;
      var Handled: Boolean);


  private
    FenList : TFenList;
    Fencount : integer;
    MWin : array[1..10] of TW_F;
    LateralPanel : shortstring;
    tmicrohelp : integer;
    activated : boolean;
    {$IFDEF DEBUG}logstream : TfileStream;{$ENDIF}

    procedure updateWindowMenu;


  public
    HistoManager: THistoManager;
    username: string;
    procedure HandleException(Sender: TObject; E: Exception);
    procedure closeAll;
    procedure OpenFrame(F: TW_F; mode : char);
    procedure notify(Sender : Tcomponent; ev :TNotifySet);
    procedure log (msg : string);
    procedure OpenWindow(code : shortstring;json : string='');
    procedure setMicroHelp(s : shortstring; t : integer = 3);
    procedure updatePanel(sender : Tform);
  end;

var
  MainForm: TMainForm;



implementation

uses UException;

{$R *.lfm}


function GetTabIndex(APageControl:TPageControl;X, Y: Integer): Integer;
var TabRect: TRect;
begin
  {Le résultat de cette fonction
  nous donne l'index de l'onglet qui se trouve aux coordonnées X,Y
  (le repère de référence étant la fenêtre du TPageControl)}
  Result := APageControl.IndexOfTabAt(X,Y);
  // Si la souris se trouve au dessus d'un onglet
  if Result>-1 then
  begin
    // On récupère le rectangle de l'onglet visé
    TabRect:=APageControl.TabRect(Result);
    // Si on est dans la partie droite de ce rectangle
    if x>((TabRect.Left+TabRect.Right) div 2)
    // Alors l'index d'insertion est (Index de l'onglet visé)+1
    then Inc(Result);
  end;
end;

{ TMainForm }


procedure TMainForm.FormCreate(Sender: TObject); (* ************************* *)

var
  MyItem: TMenuItem;


begin
  onglet.visible:=false;
  activated:=false;
  StatusBar1.Panels[0].Text := DateTimeToStr(Now);
  StatusBar1.Panels[1].Text := '?';
  StatusBar1.Panels[2].Text := '';
  Fr_histo1.show(false);
  username := 'admin';
  LateralPanel:='None';
  logstream:=nil;
  Application.OnException := @HandleException;
  {$IFDEF DEBUG}
  logstream:=TFileStream.Create('Pampa.log',fmCreate);
  log('Open');
  {$ENDIF}
  Application.ProcessMessages;

  FenList:=TFenList.CREATE;
  Fencount:=1;


  // Menu popup de l'onglet

  Onglet.PopupMenu := TPopupMenu.Create(self);
  Onglet.PopupMenu.Parent := Onglet;
  MyItem := TMenuItem.Create(Self);
  MyItem.Action := ActionList1.ActionByName('Act_closetab');
  MyItem.Name := 'Mclose';
  Onglet.PopupMenu.Items.Add(MyItem);
  MyItem := TMenuItem.Create(Self);
  MyItem.Action := ActionList1.ActionByName('Act_towindow');
  MyItem.Name := 'MFenetre';
  Onglet.PopupMenu.Items.Add(MyItem);


end;

procedure TMainForm.closeAll;

var tab: TTabSheet;
    i : integer;
    f : Tframe;
    fo : Tform;

begin
  try
    i:=onglet.PageCount;
    while (i>0) do
    begin
      tab:=onglet.ActivePage;
      if assigned(tab) then tab.Free;
      i:=onglet.PageCount;
    end;
  Except
    on e : exception do log(e.ToString);
  end;
  try
    for f in FenList do
    begin
         if assigned(f.parent) then
         begin
           if f.parent is TForm then
           begin
                fo:=f.parent as Tform;
                fo.Close;
           end;
         end;
    end;
  except
    on e : exception do log(e.ToString);
  end;
end;

procedure TMainForm.HandleException(Sender: TObject; E: Exception);

begin
  Error (e, dber_system,'Uncatched Exception');
end;

procedure TMainForm.Timer1Timer(Sender: TObject);
begin
  if tmicrohelp>0 then
  begin
    dec(tmicrohelp);
    if tmicrohelp=0 then StatusBar1.Panels[0].Text :=rs_ready;
  end;
  if not MainData.isConnected then
  begin
      Act_affhisto.Enabled:=false;
      Act_bookmark.Enabled:=false;
      Act_delete.Enabled:=false;
      Act_Export.Enabled:=false;
      Act_insert.Enabled:=false;
      Act_worker.Enabled:=false;
      Act_new_intervenant.Enabled:=false;
      Act_planning.Enabled:=false;
      Act_refresh.Enabled:=false;
      act_save.Enabled:=false;
      Act_towindow.Enabled:=false;
  end;
end;

procedure TMainForm.TS_indContextPopup(Sender: TObject; MousePos: TPoint;
  var Handled: Boolean);
begin

end;

procedure TMainForm.updatePanel(sender : Tform);

var s : string;
    tab: TTabSheet;
    i : integer;

begin
  s:='';
  if sender=self then
  begin
    s:=self.name;
    tab := onglet.ActivePage;
    if assigned(tab) then
    begin
      i := 0;
      while (i < tab.ControlCount) do
      begin
        if tab.Controls[i] is TW_F then
        begin
          s:=s+':'+tab.Controls[i].classname;
          if tab.caption>' ' then s:=s+' ['+tab.Caption+']';
          break;
        end;
        Inc(i);
      end;
    end;
  end else
  begin
    s:=sender.ClassName;
    i := 0;
     while (i < sender.ControlCount) do
     begin
       if sender.Controls[i] is TW_F then
       begin
         s:=s+':'+sender.Controls[i].classname;
         if sender.caption>' ' then s:=s+' ['+sender.Caption+']';
         break;
       end;
       Inc(i);
     end;
  end;
  MainForm.StatusBar1.Panels[2].Text := s;
end;

procedure TMainForm.updateWindowMenu;

var m : TMenuItem;
    f : TW_F;
    i,j,nbwindows : integer;

begin
  for i:=1 to 10 do MWin[i]:=nil;
  Mainform.N2.visible:=false;
  i:=1;
  nbwindows:=0;
  for f in FenList do
  begin
       if assigned(f.parent) then
       begin
         if f.parent is TForm then
         begin
              inc(nbwindows);
              if i<10 then
              begin
                   inc(i);
                   MWin[i]:=f;
              end;
         end;
       end;
  end;
  if nbwindows>0 then
  begin
       Arr_Cascade.Enabled:=true;
       Arr_TileHorizontal.Enabled:=true;
  end else
  begin
       Arr_Cascade.Enabled:=false;
       Arr_TileHorizontal.Enabled:=false;
  end;

  for i:=1 to Mainform.MWindows.Count - 1 do
  begin
       m:=Mainform.MWindows.items[i];
       if leftstr(m.Name,2)='MW' then
       begin
          m.Visible:=false;
          if trystrToInt(copy(m.Name,3,2),j) then
          begin
            if assigned(MWin[j]) then
            begin
              m.Visible:=true;
              m.Caption:=MWin[j].Caption;
              m.tag:=j;
              Mainform.N2.visible:=true;
            end else
            begin
              m.visible:=false;
              M.tag:=-1;
            end;
          end;
       end;
  end;
end;

function TMainForm.TabClose(Sender: TObject) : boolean;

var
  tab: TTabSheet;
  Frame: TW_F;
  i: integer;
  canclose: boolean;

begin
  result:=false;
  canclose := True;
  tab := onglet.ActivePage;
  if assigned(tab) then
  begin
    i := 0;
    frame := nil;
    while (not assigned(frame)) and (i < tab.ControlCount) do
    begin
      if tab.Controls[i] is TW_F then
      begin
        frame := TW_F(tab.Controls[i]);
      end
      else
        Inc(i);
    end;
    if assigned(frame) and (frame.Visible) then
    begin
      canclose := frame.CanClose;
    end;
    if canclose then
    begin
      if assigned(frame) then frame.close;
      tab.Free;
      result:=true;
    end else result:=false;
  end;
end;

procedure TMainForm.Act_refreshExecute(Sender: TObject);
begin
  // todo : LWH. relire dans la BDD
end;



procedure TMainForm.FormActivate(Sender: TObject);


var Fplanning : TFr_planning;

begin
  if (not activated) and (not IdleTimer.Enabled) and (not Timer1.Enabled) and (not MainData.isConnected) then
  begin
    activated:=true;
    Application.ProcessMessages;
    try
       MainData.Logon;
    except
    end;
    try
       HistoManager := THistoManager.Create;
    except
    end;
    if MainData.isConnected then
    begin
      Worker.init(MainData);
      Customer.init(MainData);
      Planning.init(MainData);
    end;

    // Fenetre planning par défaut
    if MainData.isConnected then
    begin
      onglet.Visible:=true;
      Fplanning := TFr_planning.Create(self);
      OpenFrame(Fplanning,'N');
    end;

    //IdleTimer
    IdleTimer.Enabled:=true;
    // Timer
    Timer1.Enabled:=true;

  end;

  updatepanel(self);
end;

procedure TMainForm.FormCloseQuery(Sender: TObject; var CanClose: boolean);

var tab: TTabSheet;


begin
    tab := onglet.ActivePage;
    while assigned(tab) do
    begin
         if not tabClose(self) then
         begin
           CanClose:=false;
           exit;
         end;
         tab := onglet.ActivePage;
    end;
    CanClose:=true;
end;

procedure TMainForm.FormShow(Sender: TObject);

begin
  if (screen.Width<(self.Width*1.1)) or (screen.Height<(self.Height*1.1)) then
  begin
    self.WindowState:=wsMaximized;
  end;
end;

procedure TMainForm.IdleTimerTimer(Sender: TObject);
begin
   if assigned(histoManager) then
   begin
     try
        histomanager.save;
     except
        on e : exception do log(e.ToString);
     end;
   end;
   StatusBar1.Panels[1].Text := MainData.getInfoConnect;
   setMicrohelp(rs_idle);
end;

procedure TMainForm.MBDDClick(Sender: TObject);

begin
  if assigned(Fbdd) then
  begin
    Fbdd.show;
  end else
  begin
      FBdd:=TFbdd.create(self);
      FBdd.Show;
  end;
end;

procedure TMainForm.MDelHistoClick(Sender: TObject);

var f : TFHistoSup;

begin
  f:=TFHistoSup.Create(self);
  f.ShowModal;

end;

procedure TMainForm.Act_deleteExecute(Sender: TObject);

var
  tab: TTabSheet;
  Frame: TW_F;
  i: integer;

begin
  tab := onglet.ActivePage;
  if assigned(tab) then
  begin
    i := 0;
    frame := nil;
    while (not assigned(frame)) and (i < tab.ControlCount) do
    begin
      if tab.Controls[i] is TW_F then
      begin
        frame := TW_F(tab.Controls[i]);
      end
      else
        Inc(i);
    end;
    if assigned(frame) then
    begin
      Application.QueueAsyncCall(@frame.delete, 0);
    end;
  end;

end;

procedure TMainForm.Act_affhistoExecute(Sender: TObject);
begin
  if not assigned(HistoManager) then exit;
  if Width<300 then LateralPanel:='H';
  case LateralPanel[1] of
       'N' : begin
                LateralPanel:='Histo';
                Fr_histo1.show(true);
                Act_affhisto.Checked:=true;
             end;
       'H' : begin
                LateralPanel:='None';
                Fr_histo1.show(false);
                Act_affhisto.Checked:=false;
             end;
       'B' : begin
                LateralPanel:='Histo';
                Fr_histo1.show(true);
                Act_affhisto.Checked:=true;
             end;
  end;
  self.DoOnResize;
end;

procedure TMainForm.Arr_CascadeExecute(Sender: TObject);

var f :  TW_F;
    r : Trect;
    i,h : integer;

begin
   r:=self.BoundsRect;
   {$IFDEF WINDOWS} //  see https://www.freepascal.org/docs-html/prog/progap7.html#x316-331000G
   h := GetSystemMetrics(SM_CYCAPTION);
   {$ELSE}
   h:=25;
   {$ENDIF}
   if (h<10) then h:=25;
   r.top:=r.top + h * 2;
   i:=1;
   for f in FenList do
   begin
       if (f.Parent is TForm) and (i*h < r.width) and (i*h < r.height) then
       begin
         TForm(F.parent).BringToFront;
         TForm(F.parent).WindowState:=wsNormal;
         F.parent.Left:=r.left+(i*h);
         F.parent.Top:=r.top+(i*h);
         F.parent.Width:=r.Width - (i * h);
         F.parent.Height:=r.height - (i * h);
         inc(i);
       end;
     end;
end;

procedure TMainForm.Act_bookmarkExecute(Sender: TObject);

var f :  TFBookmark;

begin
  f:=TFBookmark.create(self);
  f.ShowModal;
end;

procedure TMainForm.Act_cnxExecute(Sender: TObject);

var
  FCnx: TFCnx;

begin
  FCnx:=TFcnx.Create(self);
  Fcnx.ShowModal;
  if MainData.isConnected then
  begin
      Act_affhisto.Enabled:=true;
      Act_bookmark.Enabled:=true;
      Act_delete.Enabled:=true;
      Act_Export.Enabled:=true;
      Act_insert.Enabled:=true;
      Act_worker.Enabled:=true;
      Act_new_intervenant.Enabled:=true;
      Act_planning.Enabled:=true;
      Act_refresh.Enabled:=true;
      act_save.Enabled:=true;
      Act_towindow.Enabled:=true;
  end;
end;

procedure TMainForm.Act_customerExecute(Sender: TObject);

var
  FPerson: TFr_Person;

begin
  FPerson := TFr_Person.Create(self,customer);
  OpenFrame(FPerson,'N');
end;

procedure TMainForm.Arr_TileHorizontalExecute(Sender: TObject);
var f :  TW_F;
    r : Trect;
    i,h,he: integer;

begin
   r:=self.BoundsRect;
   {$IFDEF WINDOWS} //  see https://www.freepascal.org/docs-html/prog/progap7.html#x316-331000G
   he := GetSystemMetrics(SM_CYCAPTION);
   {$ELSE}
   he:=25;
   {$ENDIF}
   if (he<10) then he:=25;
   r.top:=r.top + he * 3;
   i:=0;
   for f in FenList do
   begin
       if (f.Parent is TForm) then
       begin
         inc(i);
       end;
    end;
    h:=r.height div i;
    if h<he then h:=he;

    for f in FenList do
    begin
        if (f.Parent is TForm) and (r.Height>= he)  then
        begin
             TForm(F.parent).BringToFront;
             TForm(F.parent).WindowState:=wsNormal;
             F.parent.Left:=r.left;
             F.parent.Top:=r.top;
             F.parent.Width:=r.Width;
             F.parent.Height:=h;
             r.top:=r.top + h;
        end;
     end;
end;

procedure TMainForm.Act_exportExecute(Sender: TObject);
begin
  MainData.exporter;
end;

procedure TMainForm.Act_planningExecute(Sender: TObject);

var Fplanning : TFr_planning;

begin
  Fplanning := TFr_planning.Create(self);
  OpenFrame(Fplanning,'N');
end;

procedure TMainForm.MDisplayClick(Sender: TObject);
begin

end;

procedure TMainForm.MCascadeClick(Sender: TObject);
begin

end;


procedure TMainForm.OpenWindow(code : shortstring;json : string='');

var  find : boolean;
     f : TW_F;
     id : longint;

begin
   find:=false;
   for f in FenList do
   begin
     if f.getcode=code then
     begin
         find:=true;
         if f.Parent is TTabSheet then
         begin
            onglet.ActivePage:=TTabSheet(f.parent);
         end else
         if f.Parent is TForm then
         begin
           TForm(F.parent).BringToFront;
           TForm(F.parent).WindowState:=wsNormal;
           F.parent.Left:=self.left+50;
           F.parent.Top:=self.top+50;
         end;
     end;
   end;

   if not find then
   begin
     if (copy(code,1,4)='FWOR') or (copy(code,1,4)='FCUS') or (copy(code,1,3)='PLN') then
     begin
       try
         id:=Hex2Dec(copy(code,6,10));
         if id>=0 then
         begin
           if copy(code,1,4)='FWOR' then F := TFr_Person.Create(self, worker) else
           if copy(code,1,4)='FCUS' then F := TFr_Person.Create(self, customer) else
           if copy(code,1,3)='PLN' then F := TFr_Planning.Create(self);
           F.init(id,json);
           OpenFrame(F,' ');
         end;
       except
          on e : exception do log(e.ToString);
       end;
     end;
   end;
end;

procedure TMainForm.MhistoClick(Sender: TObject);

var n : integer;
    cl,code : shortString;
    id : longint;
    j : string;



begin
     assert(assigned(histomanager),'HistoManager not assigned');
     code:='';
     cl:='';
     id:=0;
     If assigned(histomanager) and (sender is TMenuItem) then
     begin
       if leftstr(TMenuItem(sender).Name,6)='Mhisto' then
       begin
         if trystrToInt(copy(TMenuItem(sender).Name,7,2),n) then
         begin
           HistoManager.getMenuInfo(n,code,cl,id,j);
           openwindow(code,j);
         end;
       end;
     end;
end;

procedure TMainForm.MI_tableClick(Sender: TObject);

var FCfg_Table: TFCfg_Table;

begin
     FCfg_Table:= TFCfg_Table.Create(self);
     FCfg_Table.ShowModal;
end;

procedure TMainForm.MWindowClick(Sender: TObject);

var s : shortstring;
    j : integer;

begin
  if Sender is TMenuItem then
  begin
       s:=TMenuItem(Sender).name;
       if leftstr(s,2)='MW' then
       begin
          if trystrToInt(copy(s,3,2),j) then
          begin
               if (j>0) and (j<10) then
               begin
                    if assigned(MWin[j]) and (MWin[j] is TW_F) then
                    begin
                      if MWin[j].Parent is TForm then
                      begin
                           TForm(MWin[j].parent).BringToFront;
                           TForm(MWin[j].parent).WindowState:=wsNormal;
                           MWin[j].parent.Left:=self.left+50;
                           MWin[j].parent.Top:=self.top+50;
                      end;
                    end;
               end;
          end;
       end;
  end;
end;

procedure TMainForm.MwindowsClick(Sender: TObject);
begin
  updateWindowMenu;
end;

procedure TMainForm.OngletChange(Sender: TObject);
begin
  UpdatePanel(self);
end;

procedure TMainForm.OngletDragDrop(Sender, Source: TObject; X, Y: Integer);


var TargetIndex, SourceIndex : integer;
    ATabSheet:TTabSheet;


begin
  if (source = onglet) and (sender is TPageControl) and (onglet.PageCount>1) then ;
  begin
     TargetIndex:=GetTabIndex(onglet,x,y);
     if TargetIndex<>-1 then
     begin
          SourceIndex:=Onglet.ActivePage.PageIndex;
          ATabSheet:=onglet.Pages[SourceIndex];
          if (TargetIndex>Onglet.ActivePage.PageIndex) then dec(TargetIndex);
          ATabSheet.PageIndex:=TargetIndex;
       end;
    {
    const TCM_GETITEMRECT = $130A;
    var i: Integer;
        SourceIndex,TargetIndex:Integer;
        ATabSheet:TTabSheet;
    begin
       if Sender=Source
       // Si le glissé-déposé concerne un TPageControl sur lui même
       then begin
               {On détermine la nouvelle valeur d'index de l'onglet que l'on dépose}
               TargetIndex:=GetTabIndex(Sender,x,y);
               {Si on ne le dépose pas "dans le vide"}
               if (TargetIndex>-1)
               {L'onglet déposé, celui qui est actif (ActivePage), prend sa nouvelle
                valeur d'index (PageIndex)}
               then begin
                      // Si le nouvel index est supérieur à l'ancien index,
                      // on le décrémente, sinon l'onglet est "mal déplacé"
                      if (TargetIndex>Sender.ActivePage.PageIndex) then dec(TargetIndex);
                      Sender.ActivePage.PageIndex:=TargetIndex;
                    end;
            end
       // Si le glissé-déposé s'effectue entre deux TPageControl différents...
       else begin
               {On détermine l'index de l'onglet que l'on dépose}
               SourceIndex:=Source.ActivePage.PageIndex;
               {On détermine la nouvelle valeur d'index de l'onglet que l'on dépose}
               TargetIndex:=GetTabIndex(Sender,x,y);
               {Si on ne le dépose pas "dans le vide"}
               if TargetIndex>-1 then
               begin
                  // On récupère la référence de notre onglet
                  ATabSheet:=Source.Pages[SourceIndex];
                  // On l'affecte à son nouveau TPageControl
                  ATabSheet.PageControl:=Sender;
                  // Et on lui assigne son nouvel index
                  ATabSheet.PageIndex:=TargetIndex;
               end;
            end;
    }
  end;
end;

procedure TMainForm.OngletDragOver(Sender, Source: TObject; X, Y: Integer;
  State: TDragState; var Accept: Boolean);
begin
  if source = onglet then  accept:=true;
end;

procedure TMainForm.Page0ContextPopup(Sender: TObject; MousePos: TPoint;
  var Handled: boolean);
begin

end;

procedure TMainForm.setMicroHelp(s : shortstring; t : integer = 3);

begin
  StatusBar1.Panels[0].Text :=s;
  tmicrohelp:=t;
  Application.ProcessMessages;
end;

procedure TMainForm.SplitterMoved(Sender: TObject);
begin
  self.DoOnResize;
end;

procedure TMainForm.TabToWindow(Sender: TObject);

var
  tab: TTabSheet;
  Frame: TW_F;
  i: integer;
  w: TW_Tab;

begin
  try
    tab := onglet.ActivePage;
    if assigned(tab) then
    begin
      //tab.Hide;
      i := 0;
      frame := nil;
      {TODO : LWH. Possible memory leak }
      while (not assigned(frame)) and (i < tab.ControlCount) do
      begin
        if tab.Controls[i] is TW_F then
        begin
          frame := TW_F(tab.Controls[i]);
        end
        else
          Inc(i);
      end;
      if assigned(frame) then
      begin
        w := TW_Tab.Create(self);
        w.addFrame(frame);
        w.Width := tab.Width;
        w.Height := tab.Height;
        w.ShowInTaskBar := stAlways;
        w.origine:='O';
        w.DefaultMonitor:=dmMainForm;
        if (Screen.MonitorCount=1) then w.DefaultMonitor:=dmPrimary;
        w.Left:=self.left+50;
        w.top:=self.top+50;
        w.Show;
      end;
      i:=tab.ControlCount;
      freeAndNil(tab);
    end;
  except
    on E: Exception do
         UException.Error(E, dberr_interface, 'TMainForm.TabToWindow');
  end;
end;


procedure TMainForm.Act_exitExecute(Sender: TObject); (* ********************* *)

begin
  StatusBar1.Panels[0].Text := rs_fermeture;
  Close;
end;

procedure TMainForm.FormResize(Sender: TObject); (* ************************* *)
begin
  try
    StatusBar1.Panels[0].Width := round(self.Width / 2);
    StatusBar1.Panels[1].Width := round(self.Width / 4);
    StatusBar1.Panels[2].Width := round(self.Width / 4);
    onglet.Top:=Toolbar1.height;
    onglet.height:=self.ClientHeight - Toolbar1.height - StatusBar1.height;
    Splitter.top:=Toolbar1.height;
    Splitter.height := Onglet.height;
    if splitter.left<150 then splitter.left:=150;
    Fr_histo1.top:=Toolbar1.height;
    if Fr_histo1.visible then
    begin
       Splitter.visible:=true;
       Splitter.BringToFront;
       if (splitter.left<100) or (splitter.left>width - 100 ) then
       begin
            Splitter.Left:=width div  4;
       end;
       Fr_histo1.Left:=0;
       Fr_histo1.Width:=Splitter.left-2;
       onglet.Left:=Splitter.left+6;
       onglet.width:=width - onglet.Left;
    end else
    begin
      Splitter.visible:=false;
      onglet.Left:=0;
      onglet.Width:=Width;
    end;
  except
    on E: Exception do
         UException.Error(E, dberr_interface, 'TMainForm.FormResize');
  end;
end;

procedure TMainForm.MFileClick(Sender: TObject);
begin

end;

procedure TMainForm.MimportClick(Sender: TObject);
begin

end;

procedure TMainForm.Act_workerExecute(Sender: TObject);

var
  FPerson: TFr_Person;

begin
  FPerson := TFr_Person.Create(self,worker);
  OpenFrame(FPerson,'N');
end;

procedure TMainForm.Act_SaveExecute(Sender: TObject);

var
  tab: TTabSheet;
  Frame: TW_F;
  i: integer;

begin
  try
     tab := onglet.ActivePage;
     if assigned(tab) then
     begin
        i := 0;
        frame := nil;
        while (not assigned(frame)) and (i < tab.ControlCount) do
        begin
          if tab.Controls[i] is TW_F then
          begin
            frame := TW_F(tab.Controls[i]);
          end
          else Inc(i);
        end;
        if assigned(frame) then
        begin
          Application.QueueAsyncCall(@frame.save, 0);
        end;
     end;
  except
    on E: Exception do
             UException.Error(E, dberr_interface, 'TMainForm.Act_SaveExecute');
  end;
end;

{Ouvre une nouvelle fenêtre dans l'onglet principal}
procedure TMainForm.OpenFrame(F: TW_F; mode : char);

var
  tab: TTabSheet;

begin
  try
    tab := onglet.AddTabSheet;
    if assigned(tab) then
    begin
      tab.Caption := 'New';
      if assigned(F) then
      begin
        inc(Fencount);
        F.Name := F.Name + IntToHex(Fencount, 4);
        F.setParent(tab);
        F.Align := alClient;
        tab.Caption := F.Caption;
        if mode='N' then Application.QueueAsyncCall(@F.init, 0);
      end;
      onglet.ActivePage := tab;
    end;
  except
    on E: Exception do
       UException.Error(E, dberr_interface, 'TMainForm.OpenFrame(F,'+mode+')');
  end;
  updatePanel(self);
end;

procedure TMainForm.notify(Sender : Tcomponent; ev : TNotifySet);

begin
  if assigned(Sender) and (Sender is TW_F) and assigned(FenList) then
  begin
    if no_open in ev then FenList.Add(TW_F(Sender));
    if no_close in ev then
    begin
      FenList.Extract(TW_F(Sender));
    end;
    updateWindowMenu;
  end;
end;

procedure TMainForm.log(msg : string);

begin
  {$IFDEF DEBUG}
  try
    msg:=DateTimeToStr(Now)+'  '+msg+LineEnding;
    if assigned(logstream) then
    BEGIN
      logstream.Write(msg[1],length(msg));
    END;
  Except
  end;
  {$ENDIF}
end;

{Fermeture de l'application.
Dernière vérification Memory Leaks : 30/07/2021
}
procedure TMainForm.FormClose(Sender: TObject; var CloseAction: TCloseAction);

var f: TFCustomDP;

begin
  MainForm.setMicroHelp(rs_quit);
  if assigned(IdleTimer) then IdleTimer.Enabled:=false;
  Timer1.Enabled:=false;
  Fr_histo1.show(false);
  // Save and Free HistoManager
  if assigned(HistoManager) then
  begin
    {todo : lwh. sometimes fail }
    HistoManager.Free;
  end;
   // Close transaction
  MainData.Tran.Rollback;
  MainData.Tran.Active:=false;
  // DisConnect
  MainData.Logoff;
  FreeAndNil(MainData);
  freeAndNil(logstream);
  if assigned(Fenlist) then FreeAndNil(FenList);
  // Close FCustomize (if open)
  f := TFCustomDP.get;
  FreeAndNil(f);
  if assigned(FCustomDP) then freeAndNil(FCustomDP);
  CloseAction := caFree;
end;



end.