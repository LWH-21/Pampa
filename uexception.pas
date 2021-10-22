unit UException;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Buttons;



type

  TDbErrcode = (dber_none,cber_nothing, dber_cfg,dber_crc,dber_sql,dber_system, dberr_interface);


  { TFException }

  TFException = class(TForm)
    Bt_halt: TBitBtn;
    Edit1: TEdit;
    Edit2: TEdit;
    Edit3: TEdit;
    Memo1: TMemo;
    procedure Bt_haltClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private

  public
        procedure affiche(E : Exception; c : TDbErrcode; msg : string);
  end;

var
  FException: TFException;

procedure Error (E : Exception; c : TDbErrcode; msg : string);

implementation

uses Main;

{$R *.lfm}

procedure Error(E : Exception; c : TDbErrcode; msg : string);

begin
     if not assigned(FException) then Application.CreateForm(TFException, FException);
     FException.affiche(E,c,msg);
end;

procedure TFException.FormCreate(Sender: TObject);
begin

end;

procedure TFException.Bt_haltClick(Sender: TObject);
begin
     Application.Terminate;
//     Application.MainForm.Close;
end;

procedure TFException.affiche(E : Exception; c : TDbErrcode; msg : string);

var
  Report: string;

begin
     Screen.Cursor:=crDefault;
     Report := 'Program exception! ' + LineEnding +  'Stacktrace:' + LineEnding + LineEnding;
     if E <> nil then
     begin
         Report := Report + 'Exception class: ' + E.ClassName + LineEnding +'Message: ' + E.Message + LineEnding;
     end;
   {  Report := Report + BackTraceStrFunc(ExceptAddr);
     Frames := ExceptFrames;
     for I := 0 to ExceptFrameCount - 1 do
         Report := Report + LineEnding + BackTraceStrFunc(Frames[I]);}

     Edit1.Text:=e.Message;
     Memo1.Text:=Report;
     edit2.Text:=msg;
     edit3.Text:='';
     MainForm.setMicroHelp(e.Message,5);
     MainForm.log(e.ToString);
     showmodal;
end;

end.

