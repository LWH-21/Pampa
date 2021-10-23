unit INTERVENANT;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,DataAccess;

type
  TINTERVENANT = class(TDataModule)
  private
       main:  TMainData;
  public
    procedure init(M:TMainData);

  end;

var
  INTERVENANT: TINTERVENANT;

implementation

{$R *.lfm}

procedure TINTERVENANT.init(M:TMainData);
begin
  main:=TMainData;
end;

end.
