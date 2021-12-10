unit UPlanning_enter;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms,dialogs, LCLType,Controls, StdCtrls, EditBtn, ExtCtrls, Buttons,
  MaskEdit, W_A, DPlanning, DateUtils;

type

  TLongint  = class
       val : longint;
       constructor create(v : longint);
       destructor destroy; override;
  end;

  { TFPlanning_enter }

  TFPlanning_enter = class(TFrame)
    Btn_apply: TBitBtn;
    Btn_cancel: TBitBtn;
    Ckb_monday: TCheckBox;
    Ckb_tuesday: TCheckBox;
    Ckb_thursday: TCheckBox;
    Ckb_wednesday: TCheckBox;
    Ckb_friday: TCheckBox;
    Ckb_saturday: TCheckBox;
    Ckb_sunday: TCheckBox;
    CB_user: TComboBox;
    EndTime: TTimeEdit;
    Label1: TLabel;
    Panel1: TPanel;
    SP_add: TSpeedButton;
    StartTime: TTimeEdit;
    procedure Btn_applyClick(Sender: TObject);
    procedure Btn_cancelClick(Sender: TObject);
    procedure FrameExit(Sender: TObject);
    procedure SP_addClick(Sender: TObject);
    procedure StartTimeChange(Sender: TObject);
  private
    planning : TFrame;
    inter : TIntervention;

  public
        col, line : integer;
        procedure init(aparent : TFrame);
        procedure refresh(l : Tlibs);
        procedure reset;
        procedure setinter(l,c : integer; i : TIntervention);
        function test() : boolean;
        function warning() : boolean;
        destructor destroy; override;
  end;

implementation

uses UF_planning_01,UPlanning,FSearch,Main,DCustomer;

{$R *.lfm}

constructor TLongint.create(v : longint);

begin
  val := v;
end;

destructor TLongint.destroy;

begin
  //inherited;
end;

{ TFPlanning_enter }

procedure TFPlanning_enter.init(aparent : TFrame);

begin
     if aparent is TGPlanning then
     begin
          planning:=aparent;
     end;
end;

procedure TFPlanning_enter.reset;

var dt : tdatetime;

begin
  Ckb_monday.Checked:=false;
  Ckb_tuesday.Checked:=false;
  Ckb_wednesday.Checked:=false;
  Ckb_thursday.checked:=false;
  Ckb_friday.checked:=false;
  Ckb_saturday.checked:=false;
  Ckb_sunday.checked:=false;
  TryEncodeDateTime(0,0, 0,8,0,0,0,dt);
  Starttime.Time:=dt;
  TryEncodeDateTime(0,0, 0,9,0,0,0,dt);
  EndTime.Time:=dt;
  CB_user.ItemIndex:=0;
end;

procedure TFPlanning_enter.setinter(l,c : integer; i : TIntervention);

var dt_start, dt_end : tdatetime;
  y,m,d,h,mi,s,ms : word;
  s1 : string;
  o : Tobject;

begin
     reset();
     inter:=i;
     visible:=true;
     col:=c;line:=l;
     dt_start:=StartTime.Time;
     DecodeDatetime(dt_start,y,m,d,h,mi,s,ms);
     if assigned(inter) then
     begin
          h:=inter.h_start div 100;
          mi:=inter.h_start mod 100;
          s:=0;
          ms:=0;
          if not TryEncodeDateTime(y,m, d,h,mi,s,ms,dt_start) then
          begin
               h:=8;mi:=0;
               TryEncodeDateTime(y,m, d,h,mi,s,ms,dt_start);
          end;
          case inter.week_day of
               1 : Ckb_monday.Checked:=true;
               2 : Ckb_tuesday.Checked:=true;
               3 : Ckb_wednesday.Checked:=true;
               4 : Ckb_thursday.checked:=true;
               5 : Ckb_friday.checked:=true;
               6 : Ckb_saturday.checked:=true;
               7 : Ckb_sunday.checked:=true;
          end;
          h:=inter.h_end div 100;
          mi:=inter.h_end mod 100;
          s:=0;
          ms:=0;
          if not TryEncodeDateTime(y,m, d,h,mi,s,ms,dt_end) then
          begin
               h:=9;mi:=0;
               TryEncodeDateTime(y,m, d,h,mi,s,ms,dt_end);
          end;
          for l:=0 to Cb_user.Items.count -1 do
          begin
               o:=Cb_user.Items.Objects[l];
               if o is Tlongint then
               begin
                    if (o as Tlongint).val = inter.c_id then
                    begin
                        CB_user.ItemIndex:=l;
                        break;
                    end;

               end;
          end;
     end else
     begin
       h:=8;mi:=0;
       TryEncodeDateTime(y,m, d,h,mi,s,ms,dt_start);
       h:=9;mi:=0;
       TryEncodeDateTime(y,m, d,h,mi,s,ms,dt_end);
       Ckb_monday.checked := (col=1);
       Ckb_tuesday.checked := (col=2);
       Ckb_wednesday.checked := (col=3);
       Ckb_thursday.checked := (col=4);
       Ckb_friday.checked := (col=5);
       Ckb_saturday.checked := (col=6);
       Ckb_sunday.checked := (col=7);
     end;
     StartTime.Time:=dt_start;
     EndTime.Time:=dt_end;

end;

function TFPlanning_enter.test() : boolean;

var h1,m1,h2,m2 : word;

begin
     result:=true;
     h1:=HourOf(StartTime.time);m1:= MinuteOf(StartTime.time);
     h2:=HourOf(EndTime.time);m2:= MinuteOf(EndTime.time);
     if (h1*60+m1)>=(h2*60+m2) then
     begin
          showmessage('erreur heure');
          result:=false;
          exit;
     end;
     if CB_user.Items.Count<=0 then
     begin
       showmessage('erreur aucun user');
       result:=false;
       exit;
     end;
     if CB_user.ItemIndex<0 then
     begin
       showmessage('erreur numero user');
       result:=false;
       exit;
     end;
     h1:=0;
     if Ckb_monday.checked then inc(h1);
     if Ckb_tuesday.checked then inc(h1);
     if Ckb_thursday.checked then inc(h1);
     if Ckb_wednesday.checked then inc(h1);
     if Ckb_friday.checked then inc(h1);
     if Ckb_saturday.checked then inc(h1);
     if Ckb_sunday.checked then inc(h1);
     if (h1=0) then
     begin
       showmessage('aucun jour sélectionné');
       result:=false;
       exit;
     end;
end;

function TFPlanning_enter.warning() : boolean;

var h1 : integer;
  reply : integer;

begin
    result:=true;
    h1:=0;
    if Ckb_monday.checked then inc(h1);
    if Ckb_tuesday.checked then inc(h1);
    if Ckb_thursday.checked then inc(h1);
    if Ckb_wednesday.checked then inc(h1);
    if Ckb_friday.checked then inc(h1);
    if Ckb_saturday.checked then inc(h1);
    if Ckb_sunday.checked then inc(h1);
    if (h1>1) then
    begin
         Reply := Application.MessageBox('Plusieurs jours sélectionnés. Confirmez', 'attention', MB_ICONQUESTION + MB_YESNO);
         if Reply <> IDYES then result:=false;
    end;
end;

procedure TFPlanning_enter.FrameExit(Sender: TObject);
begin
 { if planning is (TGPlanning) then
  begin
     TF_planning_01(planning).modify;
  end;}
  visible:=false;
end;

procedure TFPlanning_enter.SP_addClick(Sender: TObject);

var num : longint;
    f,l,c : shortstring;
    k : integer;
    found : boolean;

begin
     if not assigned(FSearch.Search) then
     begin
          FSearch.Search:= TSearch.create(MainForm);
     end;
     num:=0;
     if CB_user.ItemIndex>=0 then
     begin
          k:= CB_user.ItemIndex;
          if assigned(CB_user.Items.Objects[k]) then
          begin
               if (CB_user.Items.Objects[k] is TLongint) then
               num:=TLongint(CB_user.Items.Objects[k]).val;
          end;
     end;

     FSearch.Search.init(customer);
     FSearch.Search.set_num_int(num);
     if FSearch.Search.showModal=mrOk then
     begin
       num:=FSearch.Search.get_num_int;
       FSearch.Search.get_result(num,f,l,c);
       found:=false;
       for k:=0 to  CB_user.Items.count-1 do
       begin
         if assigned(CB_user.Items.Objects[k]) then
         begin
              if CB_user.Items.Objects[k] is TLongint then
              if TLongint(CB_user.Items.Objects[k]).val=num  then
              begin
                   found:=true;
                   break;
              end;
         end;
       end;
       if not found then
       begin
            CB_user.AddItem(f+' '+l, TLongint.create(num));
            CB_user.ItemIndex:=CB_user.Items.Count - 1;
       end;
     end;
end;

procedure TFPlanning_enter.refresh(l : Tlibs);

var i,j : integer;
    s : string;

    function find(id : longint) : boolean;

    var k : integer;
    begin
      result:=false;
      for k:=0 to  CB_user.Items.count-1 do
      begin
        if assigned(CB_user.Items.Objects[k]) then
        begin
             if CB_user.Items.Objects[k] is TLongint then
             if TLongint(CB_user.Items.Objects[k]).val=id  then
             begin
                  result:=true;
                  exit;
             end;
        end;
      end;
    end;

begin
     j:=length(l);
     for i:=0 to j-1 do
     begin
          if (l[i].id>0) then
          begin
               s:=inttostr(l[i].id);
               if not find(l[i].id) then CB_user.AddItem(l[i].caption, TLongint.create(l[i].id));
          end;
     end;
     CB_user.ItemIndex:=0;
end;

procedure TFPlanning_enter.StartTimeChange(Sender: TObject);
begin

end;



procedure TFPlanning_enter.Btn_applyClick(Sender: TObject);

var days : shortstring;
    dt : Tdatetime;
    y,m,d,h,mi,s,ms : word;
    hs,he : word;
    num : longint;

begin
   assert(parent is TGPlanning,'Parent Error');
   if (test()) and (warning()) then
   begin
      if Ckb_monday.checked then days:='M' else days:='_';
      if Ckb_tuesday.checked then days:=days+'T' else days:=days+'_';
      if Ckb_wednesday.checked then days:=days+'W' else days:=days+'_';
      if Ckb_thursday.checked then days:=days+'H' else days:=days+'_';
      if Ckb_friday.checked then days:=days+'F' else days:=days+'_';
      if Ckb_saturday.checked then days:=days+'S' else days:=days+'_';
      if Ckb_sunday.checked then days:=days+'U' else days:=days+'_';

      dt:=StartTime.Time;
      DecodeDatetime(dt,y,m,d,h,mi,s,ms);
      hs:=h*100+mi;

      dt:=EndTime.Time;
      DecodeDatetime(dt,y,m,d,h,mi,s,ms);
      he:=h*100+mi;

      if CB_user.ItemIndex>=0 then
      begin
          s:= CB_user.ItemIndex;
          if assigned(CB_user.Items.Objects[s]) then
          begin
               if (CB_user.Items.Objects[s] is TLongint) then
               num:=TLongint(CB_user.Items.Objects[s]).val;
          end;
     end;

      TGPlanning(parent).Modify(num,days,hs,he,inter);
      self.visible:=false;
   end;
end;

procedure TFPlanning_enter.Btn_cancelClick(Sender: TObject);
begin
   reset;
   self.visible:=false;
end;

destructor TFPlanning_enter.destroy;

var k : integer;
    o : TObject;

begin
  for k:=0 to CB_user.Items.count-1 do
  begin
    if assigned(CB_user.items.Objects[k]) then
    begin
         (CB_user.Items.Objects[k] as TLongint).Free;
    end;
  end;
//  CB_user.Items.free;
  CB_user.Clear;
  inherited;
end;


end.

