unit ufhistosup;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, MaskEdit,
  DataAccess,
  DateUtils,
  EditBtn, Buttons, W_A;

type

  { TFHistoSup }

  TFHistoSup = class(TW_A)
    BitBtn1: TBitBtn;
    ComboBox1: TComboBox;
    DateEdit1: TDateEdit;
    TimeEdit1: TTimeEdit;
    procedure BitBtn1Click(Sender: TObject);
    procedure ComboBox1Change(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private

  public

  end;


implementation

{$R *.lfm}

uses Main;

{ TFHistoSup }

procedure TFHistoSup.ComboBox1Change(Sender: TObject);
begin

end;

procedure TFHistoSup.FormCreate(Sender: TObject);

var t : Tdatetime;

begin
  t:=EncodeTime(HourOf(time),0,0,0);
  DateEdit1.Date:=now;
  TimeEdit1.Time:=t;
end;

procedure TFHistoSup.BitBtn1Click(Sender: TObject);

var s : string;
    op,op1 : string;


begin
     op1:='>';
     if Combobox1.ItemIndex=1 then op1:='<';
     op:=MainData.getSyntax('CONCAT','+');
     s:=FormatDateTime('YYYYMMDD',DateEdit1.date)+FormatDateTime('HH:nn:ss',TimeEdit1.Time);
     s:='DELETE FROM LWH_HISTO WHERE DT '+op+' TIM '+op1+' '+quotedstr(s);
     showmessage(s);
     MainForm.HistoManager.LoadHisto;
end;

end.

