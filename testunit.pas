unit TestUnit;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

type
  ITestInterface = interface
    procedure TestBDD;
    procedure TestProcedures;
  end;

procedure TestBDD;

implementation

uses UHistoManager;

procedure TestBDD;

var o : ItestInterface;

begin
     o:=THistoManager.create;
     o.TestBDD;
     freeAndNil(o);

end;

end.

