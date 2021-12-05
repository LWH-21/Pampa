unit UPlanning_enter;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, StdCtrls, EditBtn, ExtCtrls, Buttons,
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
        procedure setinter(i : TIntervention);
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

procedure TFPlanning_enter.setinter(i : TIntervention);

var dt_start, dt_end : tdatetime;
  y,m,d,h,mi,s,ms : word;
  c,l : integer;
  s1 : string;
  o : Tobject;

begin
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
     end;
     StartTime.Time:=dt_start;
     EndTime.Time:=dt_end;

    Ckb_monday.checked := (col=1);
    Ckb_tuesday.checked := (col=2);
    Ckb_thursday.checked := (col=3);
    Ckb_wednesday.checked := (col=4);
    Ckb_friday.checked := (col=5);
    Ckb_saturday.checked := (col=6);
    Ckb_sunday.checked := (col=7);

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
begin
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

