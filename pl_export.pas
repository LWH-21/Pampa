unit PL_export;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, DateUtils,
  Dialogs,
  fpspreadsheet,fpstypes,fpsallformats,
  Main,RessourcesStrings,DPlanning, Uplanning;


procedure export_planning(mat : TLPlanning; style : TPlanning_kind);

implementation

procedure xlsexport(mat : TLPlanning; stype : TPlanning_kind; fname : string);

var MyWorkBook : TsWorkBook;
    MyWorkSheet : TsWorkSheet;
    l,c : integer;
    inter : TIntervention;
    s : string;
    dt : tdatetime;
    BgColor : TsColor;

begin
  if fileexists(fname) then
  begin
    if not deletefile(fname) then
    begin
      showmessage('impossible de modifier le fichier '+fname);
      exit;
    end;
  end;
  Myworkbook:=TsWorkBook.Create;
  MyWorkSheet:=MyWorkBook.AddWorksheet('Planning');
  dt:=mat.start_date;
  for l:=0 to mat.linescount - 1 do
  begin
       s:=mat.libs[mat.lines[l].index].code;
       MyWorkSheet.WriteText(l+2,1,s);
       s:=mat.libs[mat.lines[l].index].caption;
       BgColor:=mat.libs[mat.lines[l].index].color.ToColor;
       MyWorkSheet.WriteText(l+2,2,s);
       MyWorkSheet.WriteBorders(l+2,2,[cbNorth, cbWest, cbEast, cbSouth]);
       for c:=0 to mat.colscount-1 do
       begin
            if (l=0) then
            begin
              MyWorkSheet.WriteDateTime(l+1,c+3,incday(dt,c),nfShortDate);
            end;
            inter:=mat.lines[l].colums[c];
            if assigned(inter) then
            begin
                 s:=inter.gethstart+' - '+inter.gethend;
                 MyWorkSheet.WriteBackground(l+2,c+3,fsSolidFill,scTransparent,BgColor);
                 MyWorkSheet.WriteText(l+2,c+3,s);
            end;
       end;
  end;
  MyWorkBook.WriteToFile(fname);
  MyWorkBook.free;

end;

procedure txtexport(mat : TLPlanning; style : TPlanning_kind; fname : string);

var  strm: TFileStream;
     l,c : integer;
     size : integer;
     s,s1 : string;
     scol : integer;
     sfirst : integer;
     dt : tdatetime;
     inter : Tintervention;
     lst : Tinterventions;

begin
     strm := TFileStream.Create(fname, fmCreate);
     sfirst:=50;
     scol:=14;
     s:=space(sfirst)+'|';
     dt:=mat.start_date;
     for c:=0 to mat.colscount - 1 do
     begin
          s1:=formatdate(dt);
          if length(s1)<scol then
          begin
               s1:=space((scol-length(s1)) div 2)+s1;
          end;
          s1:=s1+space(scol);
          s:=s+s1.Substring(1,scol)+'|';
          dt:=incday(dt);
     end;
     size:=length(s);
     s:=s+LineEnding;
     s1:=StringOfChar('-',size)+LineEnding;
     strm.Write(s1[1],length(s1));
     strm.Write(s[1],length(s));
     strm.Write(s1[1],length(s1));

     for l:=0 to mat.linescount -1 do
     begin
          if mat.lines[l].index>=0 then
          begin
               if (l=0) or (mat.lines[l].index<>mat.lines[l-1].index) then
               s:=mat.libs[mat.lines[l].index].caption else s:='';
          end else
          begin
               s:='';
          end;
          s:=s+space(sfirst);
          s:=s.substring(0,sfirst)+'|';
          for c:=0 to mat.colscount-1 do
          begin
               if assigned(mat.lines[l].colums[c]) then
               begin
                    inter:=mat.lines[l].colums[c];
                    s1:=inter.gethstart+' - '+inter.gethend;
                    if length(s1)>scol then s1:=space((scol-length(s1)) div 2)+s1;
               end else s1:='';
               s1:=s1+space(scol);
               s:=s+s1.Substring(0,scol)+'|';
          end;
          s:=s+LineEnding;
          strm.Write(s[1],length(s));
          if (l<mat.linescount -1) and (mat.lines[l].index=mat.lines[l+1].index) then
          begin
                    s:=space(sfirst)+'|'+StringOfChar('-',size);

          end else
          begin
                    s:=StringOfChar('-',size);
          end;
          s:=s.substring(0,size)+LineEnding;
          strm.Write(s[1],length(s));
     end;

     s:=lineEnding;
     strm.write(s[1],length(s));

     s:=StringOfChar('-',59)+LineEnding;
     strm.write(s[1],length(s));

     lst:=mat.getInterventions;

     while lst.Count>0 do
     begin
          inter:=lst.ExtractIndex(0);
          s:=formatdate(inter.dt)+space(20);
          s:=s.Substring(0,12);
          s1:='';
          for c:=0 to length(mat.lines)-1 do
          begin
               if mat.libs[c].id=inter.c_id then
               begin
                 s1:=mat.libs[c].caption;
                 break;
               end;
          end;
          s:=s+s1+space(20);
          s:=s.substring(0,40)+'|';
          s:=s+' '+inter.gethstart+' - '+inter.gethend+space(3)+'|';
          s:=s+lineEnding;
          strm.write(s[1],length(s));
     end;
     lst.DeleteRange(0,lst.Count);
     lst.Clear;
     lst.free;

     strm.free;
end;

procedure export_planning(mat : TLPlanning; style : TPlanning_kind);

var
  saveDialog: TSaveDialog;


begin
  assert(assigned(mat),'Mat not assigned');
  saveDialog := TSaveDialog.Create(Mainform);
  if assigned(savedialog) then
  begin
    saveDialog.Title := rs_export;
    saveDialog.InitialDir := GetCurrentDir;
    saveDialog.Filter :=
      'Text file|*.txt|Classeur Excel|*.xlsx';
    saveDialog.DefaultExt := 'csv';
    saveDialog.FilterIndex := 1;
    savedialog.options := [ofOverwritePrompt, ofViewDetail, ofAutopreview,
      ofPathMustExist, ofForceShowHidden];
    if saveDialog.Execute then
    begin
         case savedialog.FilterIndex of
          1 : txtexport(mat,style,savedialog.FileName );
          2 : xlsexport(mat,style,savedialog.FileName);
         end;
    end;
    saveDialog.Free;
  end;
end;

end.

