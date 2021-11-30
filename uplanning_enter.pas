unit UPlanning_enter;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, StdCtrls, EditBtn, ExtCtrls, Buttons,
  MaskEdit, W_A, UPlanning, DPlanning, DateUtils;

type

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
    EndTime: TTimeEdit;
    Label1: TLabel;
    Panel1: TPanel;
    StartTime: TTimeEdit;
    procedure Btn_applyClick(Sender: TObject);
    procedure FrameExit(Sender: TObject);
    procedure StartTimeChange(Sender: TObject);
  private
    planning : TW_A;

  public
        col, line : integer;
        procedure init(aparent : TW_A);
        procedure setinter(c,l : integer;inter : TIntervention);
  end;

implementation

uses UF_planning_01;

{$R *.lfm}

{ TFPlanning_enter }

procedure TFPlanning_enter.init(aparent : TW_A);

begin
     planning:=aparent;
end;

procedure TFPlanning_enter.setinter(c,l : integer;inter : TIntervention);

var dt_start, dt_end : tdatetime;
  y,m,d,h,mi,s,ms : word;

begin
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
  if planning is (TF_planning_01) then
  begin
     TF_planning_01(planning).modify;
  end;
  visible:=false;
end;

procedure TFPlanning_enter.StartTimeChange(Sender: TObject);
begin

end;

procedure TFPlanning_enter.Btn_applyClick(Sender: TObject);
begin
  self.visible:=false;
end;

end.

