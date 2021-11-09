unit UPlanning_enter;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, StdCtrls, EditBtn, ExtCtrls, Buttons,
  MaskEdit, W_A, DPlanning, DateUtils;

type

  { TFPlanning_enter }

  TFPlanning_enter = class(TFrame)
    Btn_apply: TBitBtn;
    Edit1: TEdit;
    EndTime: TTimeEdit;
    Panel1: TPanel;
    StartTime: TTimeEdit;
    procedure Btn_applyClick(Sender: TObject);
    procedure FrameExit(Sender: TObject);
    procedure StartTimeChange(Sender: TObject);
  private
    planning : TW_A;
  public
        procedure init(aparent : TW_A);
        procedure setinter(col,line : integer;inter : TIntervention);
  end;

implementation

{$R *.lfm}

{ TFPlanning_enter }

procedure TFPlanning_enter.init(aparent : TW_A);

begin
     planning:=aparent;
end;

procedure TFPlanning_enter.setinter(col,line : integer;inter : TIntervention);

var dt_start, dt_end : tdatetime;
  y,m,d,h,mi,s,ms : word;

begin
     visible:=true;
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
end;

procedure TFPlanning_enter.FrameExit(Sender: TObject);
begin
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

