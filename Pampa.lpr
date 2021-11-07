program Pampa;

{ <description>

  Copyright (C) <2021> <lwh> <>

  This source is free software; you can redistribute it and/or modify it under
  the terms of the GNU General Public License as published by the Free
  Software Foundation; either version 2 of the License, or (at your option)
  any later version.

  This code is distributed in the hope that it will be useful, but WITHOUT ANY
  WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
  FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
  details.

  A copy of the GNU General Public License is available on the World Wide Web
  at <http://www.gnu.org/copyleft/gpl.html>. You can also obtain it by writing
  to the Free Software Foundation, Inc., 51 Franklin Street - Fifth Floor,
  Boston, MA 02110-1335, USA.
}


{$mode objfpc}{$H+}

{$DEFINE DEBUG}

uses {$IFDEF UNIX} {$IFDEF UseCThreads}
  cthreads, {$ENDIF} {$ENDIF}
  Forms, Interfaces,Dialogs, zcomponent,
  Main,
  DataAccess,

  {$IFDEF DEBUG}LazLogger,{$ENDIF}

  { you can add units after this }
  SysUtils, // une unité ajoutée pour PathDelim
  gettext, translations, datetimectrls, dworker, Ucfg_table_det, DCustomer,
  DPlanning, LWTabPage;

{$R *.res}


  procedure LCLTranslate;
  var
    PODirectory, Lang, FallbackLang: string;
  begin
    Lang := ''; // langue d'origine
    FallbackLang := ''; // langue d'origine étendue
    PODirectory := '.' + PathDelim + 'lang' + PathDelim; // répertoire de travail
    GetLanguageIDs(Lang, FallbackLang); // récupération des descriptifs de la langue
    TranslateUnitResourceStrings('LCLStrConsts',
      PODirectory + 'lclstrconsts.fr.po', Lang, FallbackLang); // traduction
  end;



begin

  {$if declared(useHeapTrace)}
  globalSkipIfNoLeaks := True; // supported as of debugger version 3.2.0
  setHeapTraceOutput('trace.log');
  {$endIf}

  RequireDerivedFormResource := True;
  LCLTranslate;
  Application.Scaled := True;
  Application.Initialize;
  Application.CreateForm(TMainData, MainData);
  Application.CreateForm(TWorker, Worker);
  Application.CreateForm(TCustomer, Customer);
  Application.CreateForm(TPlanning, Planning);
  Application.CreateForm(TMainForm, MainForm);
  Application.CreateForm(TFcfg_table_det, Fcfg_table_det);
  Application.Run;

end.
