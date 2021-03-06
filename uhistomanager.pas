unit UHistoManager;

{$mode objfpc}{$H+}

interface

uses
  {$IFDEF TESTS}
  TestUnit,
  {$ENDIF}
  SysUtils,StrUtils,DateUtils,Classes,
  DB,SQLDB,DataAccess,ZDataset,
  fpjson,jsonparser,
  Forms, Controls,ComCtrls,dw_f, Dialogs,Menus,Clipbrd;

Type

  Thmenu = record
            visible : boolean;
            dt   : shortstring;
            code : shortstring;
            rownum : integer;
            caption : shortstring;
            json : string;
           end;

  THisto = class
        code : shortstring;
        debut, fin : Tdatetime;

        constructor create(c : shortstring);
        constructor create(c : shortstring; d,f : TdateTime);
  end;

  THistoManager = class{$IFDEF TESTS}(TInterfacedObject,ITestInterface){$ENDIF}

  public
        query : Tdataset;
        hmenu : array[1..10] of Thmenu;
        changed : boolean;

        constructor create;
        procedure AddHisto(win : TW_F; id : longint; actions : shortstring);
        function getCaption(s : string) : shortstring;
        procedure getLastWindow(var code : shortstring; var j : string);
        procedure getMenuInfo(n : integer; var code, c : shortstring; var id : longint; var j : string);
        procedure save;
        procedure UpdateMainMenu;
        Procedure LoadHisto;
        procedure LoadHisto(tv : TTreeView; Node : TTreeNode; user : shortstring);
        function createjson(win : TW_F; id : longint; actions : shortstring) : string;
        destructor destroy;override;

        {$IFDEF TESTS}
        procedure TestBDD( s : TStringStream);
        procedure TestProcedures( s : TStringStream);
        {$ENDIF}

  end;

implementation

uses Main,UException,RessourcesStrings;

constructor Thisto.create(c : shortstring);

begin
     code:=c;
end;

constructor Thisto.create(c : shortstring; d,f : TdateTime);

begin
     code:=c;
     debut:=d;
     fin:=f;
end;

constructor THistoManager.create;

var sql : string;
    i : integer;

begin
  for i:=1 to 10 do
  begin
       hmenu[i].visible:=false;
       hmenu[i].code:='';
       hmenu[i].rownum:=-1;
       hmenu[i].dt:='';
       hmenu[i].json:='';
  end;
  sql:='';
  changed:=false;
  if not MainData.isConnected then exit;
  assert(MainData.isConnected,'Not connected');
  try
    try
      // Initialize Query
      query:=nil;
      LoadHisto;
    except
       on e : exception do error(e, dber_system,'THistoManager.create '+sql);
    end;
  finally

  end;
end;

procedure THistoManager.LoadHisto;

var sql, sinsert,supdate : string;
    i, num : integer;
    code : shortstring;
    exists : boolean;

begin
     if not MainData.isConnected then exit;
     try
       try

         Screen.Cursor := crHourGlass;
         for num:=1 to 10 do
         begin
             hmenu[num].visible:=false;
             hmenu[num].dt:='';
             hmenu[num].code:='';
             hmenu[num].rownum:=-1;
             hmenu[num].caption:='';
             hmenu[num].json:='';
         end;
         if assigned(query) then
         begin
            query.close;
         end;

         sql:=Maindata.getQuery('Q0006','SELECT DT, USERNAME, CODE, TIM, JSON, LASTUSER, ROWVERSION FROM LWH_HISTO WHERE USERNAME=''%u'' ORDER BY DT DESC, TIM DESC, CODE ASC');
         sinsert:=Maindata.getQuery('IN001_C');
         supdate:=Maindata.getQuery('IN001_U');

         sql:=sql.Replace('%u',Mainform.username);
         MainData.readDataSet(Query,sql,false,sinsert,'',supdate);

         i:=Query.RecordCount;
         num:=0;
         WHILE (NOT query.EOF) and (num<10) DO
         BEGIN
              exists:=false;
              code:=trim(query.FieldByName('CODE').asString);
              for i:=1 to 10 do
              begin
                   if hmenu[i].code=code then exists:=true;
              end;
              if not exists then
              begin
                inc(num);
                if (num<11) then
                begin
                     hmenu[num].visible:=true;
                     hmenu[num].dt:=trim(query.FieldByName('DT').asString);
                     hmenu[num].code:=code;
                     hmenu[num].rownum:=query.RecNo;
                     hmenu[num].caption:=getcaption(query.FieldByName('JSON').asString);
                     hmenu[num].json:=query.FieldByName('JSON').AsString;
                end;
              end;
              query.Next;
         END;
         changed:=false;
       Except
          on E: Exception do
                Error(E, dber_none, 'THistoManager.LoadHisto()');
       end;
     finally
       UpdateMainMenu;
       Screen.Cursor := crDefault;
     end;
end;

procedure THistoManager.LoadHisto(tv : TTreeView; Node: TTreeNode; user : shortstring);

var
  ANode, root: TTreeNode;
  Q : TDataSet;
  s ,sql : string;
  code,s1 : shortstring;
  i : integer;
  h : thisto;
  include_date : boolean;
  d,debut,fin : Tdatetime;
  year,month,day : word;
  fmt: TFormatSettings;

begin
     if not MainData.isConnected then exit;
     Q:=nil;
     try
       try
         save;
         Screen.Cursor := crHourGlass;
         fmt.ShortDateFormat:='yyyy-mm-dd';
         fmt.DateSeparator:='-';
         include_date:=false;
         if assigned(node) then
         begin
              node.DeleteChildren;
              if assigned(node.Data) then
              begin
                  h:= Thisto(Node.Data);
                  s:=FormatDateTime('YYYYMMDD',h.debut);
                  s1:=FormatDateTime('YYYYMMDD',h.fin);
                  sql:='SELECT DT, CODE,USERNAME,TIM,JSON FROM LWH_HISTO WHERE DT >= '+quotedStr(s)+' AND DT <= '+quotedstr(s1);
                  if user>' ' then sql:=sql+' AND  USERNAME='+quotedstr(user);
                  sql:=sql+' ORDER BY DT DESC, TIM DESC;';
                  include_date:=h.debut<>h.fin;
                  MainData.readDataSet(Q,sql,true);
                  if Q.RecordCount>0 then
                  BEGIN
                      Q.First;
                      WHILE (NOT Q.EOF) DO
                      BEGIN
                           s:=copy(Q.FieldByName('TIM').asString,1,5)+' '+getcaption(Q.FieldByName('JSON').asString);
                           if include_date then
                           begin
                                s1:=Q.FieldByName('DT').asString;
                                s1:=copy(s1,1,4)+'-'+copy(s1,5,2)+'-'+copy(s1,7,2);
                                if TryStrTodate(s1,d,fmt) then
                                begin
                                    s:=Datetostr(d)+' '+s;
                                end;
                           end;
                           if user<=' ' then
                           begin
                               s:=Q.FieldByName('USERNAME').asString+' : '+s;
                           end;
                           code:=Q.FieldByName('CODE').AsString;
                           h:=thisto.create(code);
                           Anode:=tv.Items.AddChildObject(Node,s,h);
                           Anode.ImageIndex:=14;
                           Q.Next;
                      END;
                  END ELSE
                  BEGIN
                       node.HasChildren:=false;
                  END;
                  Q.close;
                  Q.free;
              end;
         end else
         begin
              tv.Items.Clear;
              root:= tv.Items.Add (nil,rs_history);
              // Today
              debut:=Date;fin:=Date;
              h:=thisto.create('TODAY',debut,fin);
              anode:= tv.Items.AddChildObject(Root,rs_today,h);
              anode.HasChildren:=true;
              // YESTERDAY
              debut:=incday(Date,-1);fin:=debut;
              h:=thisto.create('YESTD',debut,fin);
              anode:= tv.Items.AddChildObject(Root,rs_yesterday,h);
              anode.HasChildren:=true;
              // Last 7 days
              debut:=incday(Date,-7);fin:=Date;
              h:=thisto.create('LAST7',debut,fin);
              anode:= tv.Items.AddChildObject(Root,rs_last7days,h);
              anode.HasChildren:=true;

              for i:=0 to 5 do
              begin
                   debut:=incMonth(Date,- i);
                   DecodeDate(debut,Year,month,day);
                   debut:=encodeDate(year,month,1);
                   fin:=incmonth(debut,1);
                   fin:=incday(fin,-1);
                   s:=FormatDateTime(rs_monthyear,debut);
                   h:=thisto.create(s,debut,fin);
                   anode:= tv.Items.AddChildObject(root,s,h);
                   anode.HasChildren:=true;
              end;
              root.Expanded:=true;
         end;
       except
          on E: Exception do
             Error(E, dber_none, 'LoadHisto(tv,Node,'+user+')');
       end;
     finally
       Screen.Cursor := crDefault;
     end;
end;

function THistoManager.createJson(win : TW_F; id : longint; actions : shortstring) : string;

var histo,obj : TJSONObject;

begin
  if not MainData.isConnected then exit;
  try
    histo:=TJsonObject.Create;
    histo.Add('date',FormatDateTime('YYYYMMDD HH:MM',now));
    histo.Add('windows',win.getCode);
    histo.Add('class',win.className);
    histo.Add('id',intTOStr(id));
    histo.Add('username',MainForm.username);
    histo.Add('caption',win.caption);
    histo.Add('actions',actions);
    histo.Add('infos',win.getinfos);
    obj:=TJsonObject.Create;
    obj.Add('histo',histo);
    result:=obj.FormatJson([foSingleLineArray,foSingleLineObject,foDoNotQuoteMembers,foUseTabchar,foSkipWhiteSpace],1);
  finally
    FreeAndNil(obj);
  end;
end;

function THistoManager.getCaption(s : string) : shortstring;

var data,fjson : TJsonData;

begin
    fjson:=GetJson(s);
    data:=fjson.findPath('histo.caption');
    if assigned(data) then result:=data.AsString;
    freeAndNil(fjson);
end;

procedure THistoManager.getLastWindow(var code : shortstring; var j : string);

var sql : string;
    Q : Tdataset;
    num : integer;

begin
     Q:=nil;
     sql:=Maindata.getQuery('Q0016','SELECT CODE, JSON FROM LWH_HISTO WHERE USERNAME=''%u'' ORDER BY DT DESC, TIM DESC, CODE ASC LIMIT 1');
     sql:=sql.Replace('%u',Mainform.username);
     MainData.readDataSet(Q,sql,true);
     if Q.RecordCount=0 then
     begin
          sql:=Maindata.getQuery('Q0016','SELECT CODE, JSON FROM LWH_HISTO WHERE USERNAME=''%u'' ORDER BY DT DESC, TIM DESC, CODE ASC LIMIT 1');
          sql:=sql.Replace('%u',Mainform.username);
          MainData.readDataSet(Q,sql,true);
     end;
     num:=0;
     WHILE (NOT query.EOF) and (num<1) DO
     BEGIN
          code:=trim(Q.FieldByName('CODE').asString);
          j:=Q.FieldByName('JSON').AsString;
          inc(num);
          Q.Next;
     END;
     Q.Close;
     freeandNil(Q);
end;

procedure THistoManager.getMenuInfo(n : integer; var code, c : shortstring; var id : longint; var j : string);

var p : integer;
    s : string;

begin
  code:='';
  c:='';
  id:=-1;
  if (n>0) and (n<11) then
  begin
       if hmenu[n].visible then
       begin
            code:=hmenu[n].code;
            j:=hmenu[n].json;
            p:=pos('|',code);
            if p>0 then
            begin
                 c:=leftstr(code,p - 1);
                 s:='$'+copy(code,p + 1, 5);
                 if not tryStrToInt(s,id) then
                 begin
                     c:='';code:='';id:=-1;
                 end;
            end;
       end;
  end;
end;

procedure THistoManager.AddHisto(win : TW_F; id : longint; actions : shortstring);

var key,dt : shortstring;
    new,find : boolean;
    i : integer;
    s : string;
    f : Tfield;
    tmp1, tmp2 : THMenu;


begin
     if not MainData.isConnected then exit;
     if not query.Active then loadhisto;
     try
       try
         key:=win.getcode;
         dt:=FormatDateTime('YYYYMMDD',now);

         query.first;
         new:=true;
         while (new) and (not query.eof) do
         begin
              s:=trim(query.FieldByName('CODE').asString);
              if (s=key) and (trim(query.FieldByName('DT').asString)=dt) then
              begin
                   new:=false;
              end else query.Next;
         end;
         if (new) then
         begin
              query.append;
              query.FieldByName('DT').asString:=dt;
              query.FieldByName('CODE').asString:=key;
              query.FieldByName('USERNAME').asString:=MainForm.username;
              query.FieldByName('TIM').asString:=FormatDateTime('hh:mm:ss',now);
              query.FieldByName('JSON').asString:=CreateJson(win,id,actions);
              f:=query.FindField('LASTUSER');
              if assigned(f) then f.AsString:=Mainform.username;
              f:=query.FindField('ROWVERSION');
              if assigned(f) then f.AsDateTime:=now;
         end
         else
         begin
             query.edit;
             query.FieldByName('JSON').asString:=CreateJson(win,id,actions);
             Query.FieldByName('TIM').asString:=FormatDateTime('hh:mm:ss',now);
             f:=query.FindField('LASTUSER');
             if assigned(f) then f.AsString:=Mainform.username;
             f:=query.FindField('ROWVERSION');
             if assigned(f) then f.AsDateTime:=now;
         end;
         for i:=1 to 10 do if hmenu[i].code=key then
         begin
           hmenu[i].visible:=false;
           hmenu[i].code:='';
           hmenu[i].rownum:=-1;
           hmenu[i].caption:='';
         end;
         tmp1.visible:=true;
         tmp1.code:=key;
         tmp1.rownum:=query.recno;
         tmp1.caption:=win.Caption;
         tmp1.json:=query.FieldByName('JSON').asString;
         i:=1;find:=false;
         while (i<11) and (not find) do
         begin
              if not hmenu[i].visible then find:=true;
              tmp2:=hmenu[i];
              hmenu[i]:=tmp1;
              if not find then
              begin
                tmp1:=tmp2;
                inc (i);
              end;
         end;
       except
          on E: Exception do
             Error(E, dber_none, 'HistoManager.AddHisto');
       end;
     finally
          UpdateMainMenu;
          changed:=true;
     end;
end;

(* Storage of history in the database.
In the event of an error (several users connected with the same login), do nothing.*)
procedure THistoManager.save;

begin
  assert(assigned(Query),'Query not assigned');
  if not MainData.isConnected then exit;
  if not changed then exit;
  if (Query.FieldCount<=0) then
  begin
      loadhisto;
      exit;
  end;
  Screen.Cursor := crHourGlass;
  MainForm.StatusBar1.Panels[0].Text := rs_savehisto;
  try
    if MainData.WriteDataSet(Query,'THistoManager.save') then
    begin
      changed:=false;
      if (Query.FieldCount<=0) then
      begin
        loadhisto;
      end;
    end;
  finally
    Screen.Cursor := crDefault;
    MainForm.StatusBar1.Panels[0].Text := rs_ready;
  end;
end;

procedure THistoManager.UpdateMainMenu;

var m : TmenuItem;
    i,j : integer;


begin
  for i:=1 to Mainform.MHisto.Count - 1 do
  begin
       m:=Mainform.MHisto.items[i];
       if leftstr(m.Name,6)='Mhisto' then
       begin
          m.Visible:=false;
          if trystrToInt(copy(m.Name,7,2),j) then
          begin
            if hmenu[j].visible then
            begin
              m.Visible:=true;
              IF hmenu[j].caption>' ' then
              begin
                   m.Caption:=hmenu[j].caption;
              end else m.Caption:=hmenu[j].code;
              m.tag:=j;
            end;
          end;
       end;
  end;
  Mainform.MHistoN2.visible:=hmenu[1].visible;
end;

destructor THistoManager.destroy;


begin
  if changed then save;
  if assigned(query) then
  begin
    query.Close;
    query.active:=false;
  end;
  freeandnil(query);
  inherited;
end;

{$IFDEF TESTS}
procedure THistoManager.TestBDD( s : TStringStream);

var sql,temp : string;
    sl : TStringList;

begin
  s.WriteString('Test BDD THistoManager'+LineEnding);
  // Test if queries exists
  sl:=TStringList.Create;
  sl.Add('IN001_C');
  sl.Add('IN001_U');
  sl.Add('Q0006');
  for temp in sl do
  begin
       sql:=Maindata.getQuery(temp,'');
       if sql<=' ' then  s.WriteString(temp+' missing'+LineEnding);
  end;
  sl.Free;
end;

procedure THistoManager.TestProcedures( s : TStringStream);
begin
  s.WriteString('Test procedures THistoManager'#10);
end;
{$ENDIF}

end.

