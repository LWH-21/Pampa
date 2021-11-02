unit DataAccess;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, SQLite3Conn, SQLDB, pqconnection, IBConnection, UFLogin,
  odbcconn, mysql57conn, mysql40conn, Laz2_DOM, laz2_XMLRead, laz2_XMLUtils,
  MSSQLConn, dialogs, DB, INIFiles, lwdata, LCLType,
  {$IFDEF WINDOWS}
  win32proc,
  {$ENDIF}
  dos, Generics.Collections, Clipbrd, Controls, Forms, Zconnection, ZDataset,ZSqlUpdate,
  ZSqlProcessor, ZPgEventAlerter, ZSqlMonitor, ZSqlMetadata, ZConnectionGroup,
  ZGroupedConnection, ZIBEventAlerter, fpjson, jsonparser;

type

   Tsyntax = (sy_default,sy_mysql,sy_sqlserver,sy_postgress,sy_sqlite);
   TIhm = specialize TDictionary<string,string>;

  { TMainData }

  TMainData = class(TDataModule)
    ODBC: TODBCConnection;
    OpenDialog1: TOpenDialog;
    SQLConnector: TSQLConnector;
    Tran: TSQLTransaction;
    ZConnection: TZConnection;


    procedure DataModuleCreate(Sender: TObject);
    procedure CnxAfterConnect(Sender: TObject);
    procedure SQLConnectorAfterConnect(Sender: TObject);
    procedure SQLConnectorAfterDisconnect(Sender: TObject);
    procedure SQLConnectorLog(Sender: TSQLConnection; EventType: TDBEventType;
      const Msg: String);
    procedure SQLScript1Exception(Sender: TObject; Statement: TStrings; TheException: Exception; var Continue: boolean);


  private
    cnx : boolean;
    ConnectorType : string;
    sqlsyntaxfile : shortstring;
    XmlDoc: TXMLDocument;
    xmlSyntax :  TDOMNode;
    ihm : TIhm;
    q : tzquery;

    function Login : boolean;
    procedure LoadDeff;

  public
    syntax : shortstring;
    cmode : shortString;
    tablesdesc : TTableDesc;
    ini : Tinifile;

    Database : TDatabase;
    function doScript(script : string):boolean;
    function getIhm(l,c : string) : TJSonData;
    function getInfoConnect : string;
    function isSyntaxFile(f : shortstring):boolean;
    function IsNullOrEmpty(s : string) : boolean;
    function isConnected : boolean;
    function getSyntax(topic : string; def : string) : string;
    function getTimestamp : shortstring;
    function getQuery(topic : string; def : string = '') : string;
    function readDataSet(var R: Tdataset; sql : string ; readonly : boolean; sinsert : string = ''; sdelete : string = ''; supdate : string='') : boolean;
    procedure SaveIhm(code,json : string);
    procedure Logon;
    procedure Logoff;
    procedure Export_script(s : tstream; modele : shortstring);
    procedure export_data_toStream(s : tstream; table : string; xml : TDOMNode);
    procedure Exporter;
    function WriteDataSet(var R: Tdataset) : boolean;
    destructor Destroy; override;

  end;

var
  MainData: TMainData;

implementation

uses Main,UException,RessourcesStrings;

{$R *.lfm}



{ TMainData }


destructor TMainData.destroy;(* ********************************************* *)

begin
     freeandnil(ini);
     freeandnil(Ihm);
     freeAndNil(tablesdesc);
     freeAndNil(XmlDoc);
     Logoff;
     inherited;
end;

procedure TMainData.export_data_toStream(s : tstream; table : string; xml : TDOMNode);

var insert : string;
    sql    : string;
    i : integer;
    fieldtype : TFieldType;
    nom_col, type_col,cle_primaire : shortstring;
    longueur, precis : integer;
    primaire,nullable : integer;
    requete : TDataSet;
    lineend,comment,go : shortstring;
    node,n :  TDOMNode;

    procedure export_cpl(base : TDOMNode; rubrique : shortstring);

    var   l,l1 : TDOMNodeList;
          m,o :  TDOMNode;
          i,j : integer;
          sql : string;
    begin
      if assigned(base) then
      begin
           l:=base.ChildNodes;
           for i:= 0 to l.Count - 1 do
           begin
                  m:=l[i];
                  if m.NodeName=rubrique then
                  begin
                       j := m.GetChildCount;
                       if j>=1 then
                       begin
                            l1:=m.ChildNodes;
                            for j:=0 to l1.count - 1 do
                            begin
                                o:=l1[j];
                                while o.HasChildNodes do o:=o.FirstChild;
                                sql:=trim(o.NodeValue);
                                if sql>' ' then
                                begin
                                   sql:=sql+LineEnding;
                                   s.Write(sql[1],length(sql));
                                   if go>' ' then
                                   begin
                                        sql:=go+lineEnding;
                                        s.Write(sql[1],length(sql));
                                   end;
                                end;
                            end;
                       end else
                       begin
                        sql:=trim(m.NodeValue);
                        if sql>' ' then
                        begin
                           sql:=sql+LineEnding;
                           s.Write(sql[1],length(sql));
                           if go>' ' then
                           begin
                             sql:=go+lineEnding;
                             s.Write(sql[1],length(sql));
                           end;
                        end;
                       end;
                  end;

                  {if m.NodeName=rubrique then
                  begin
                       j := m.GetChildCount;
                       while m.HasChildNodes do m:=m.FirstChild;
                       sql:=trim(m.NodeValue);
                       if sql>' ' then
                       begin
                          sql:=sql+LineEnding;
                          s.Write(sql[1],length(sql));
                       end;
                  end;}
           end;
      end;
    end;

    procedure table_structure;

    var lsql : string;
        s1,s2 : string;
        i : integer;
        n,m : TDOMNode;
        find : boolean;

    begin
      // Comment Line
      lsql:=''+lineEnding; ;
      if comment>' ' then lsql:=comment+' '+table+' Structure'+lineEnding; ;
      s.Write(lsql[1],length(lsql));
      // Drop statement
      n:=xml.FindNode('DROPTABLE');
      if assigned(n) then
      begin
         if (n.GetChildCount>0) then lsql:=N.FirstChild.NodeValue else lsql:='';
      end else lsql:='DROP TABLE %t';
      lsql:=trim(StringReplace(lsql,'%t',table,[rfReplaceAll, rfIgnoreCase]))+lineend+LineEnding;
      s.Write(lsql[1],length(lsql));
      n:=xml.FindNode(table);
      find:=false;
      if assigned(n) then
      begin
          m:=n.FindNode('TABLE');
          if assigned(m) and (m.GetChildCount>0) then
          begin
            lsql:=trim(m.FirstChild.NodeValue)+LineEnding;
            s.Write(lsql[1],length(lsql));
            find:=true;
          end;
      end;
      if not find then
      begin
           n:=xml.FindNode('CREATETABLE');
           if assigned(n) and (n.GetChildCount>0) then lsql:=N.FirstChild.NodeValue else lsql:='CREATE TABLE %t';
           lsql:=StringReplace(lsql,'%t',table,[rfReplaceAll, rfIgnoreCase]);
           i:=0;
           cle_primaire:='';
           s1:='';
           while not requete.EOF do
           begin
                  inc(i);
                  if i>1 then s1:=s1+',';
                  s1:=s1+LineEnding;
                  nom_col:=Requete.Fields[0].asString;
                  type_col:=Requete.Fields[1].asString;
                  longueur:=Requete.Fields[2].AsInteger;
                  precis:=Requete.Fields[3].AsInteger;
                  if (nom_col = 'SY_ID') then primaire:=1 else primaire:=0;
                  if ((nom_col='SY_ID') or (nom_col='SY_CODE')) then nullable:=0 else nullable:=1;
                  s1:=s1+space(5)+nom_col;
                  // Numerics Data Type
                  IF (type_col='NUM') and (precis=0) then type_col:='INT';
                  if (type_col='NUM') and (precis>0) and (longueur>0) then type_col:='DECI';
                  n:=xml.FindNode('TYPE'+type_col);
                  if assigned(n) and (n.GetChildCount>0) then s2:=n.FirstChild.NodeValue else s2:=type_col;
                  s2:=StringReplace(s2,'%l',inttostr(longueur),[rfReplaceAll, rfIgnoreCase]);
                  s2:=StringReplace(s2,'%d',inttostr(precis),[rfReplaceAll, rfIgnoreCase]);
                  s1:=s1+' '+s2;
                  n:=xml.FindNode('NULLABLE');
                  if assigned(n) and (n.GetChildCount>0) then s2:=n.FirstChild.NodeValue else s2:='';
                  if nullable=1 then s1:=s1+' '+s2;
                  n:=xml.FindNode('NOTNULLABLE');
                  if assigned(n) and (n.GetChildCount>0) then s2:=n.FirstChild.NodeValue else s2:='NOT NULL';
                  if nullable=0 then s1:=s1+' '+s2;
                  n:=xml.FindNode('IDENTITY');
                  {if assigned(n) and (n.GetChildCount>0) then s2:=n.FirstChild.NodeValue else s2:='AUTO_INCREMENT';
                  if (autocol=1) then s1:=s1+' '+s2;}
                  if primaire=1 then
                  begin
                    if length(cle_primaire)>1 then cle_primaire:=cle_primaire+', ';
                    cle_primaire:=cle_primaire+nom_col;
                  end;
                  requete.Next;
           end;
           lsql:=StringReplace(lsql,'%p',cle_primaire,[rfReplaceAll, rfIgnoreCase]);
           lsql:=StringReplace(lsql,'%def',s1,[rfReplaceAll, rfIgnoreCase])+lineend+LineEnding;
           s.Write(lsql[1],length(lsql));
      end;
      if go>' ' then
      begin
           sql:=go+lineEnding;
           s.Write(sql[1],length(sql));
      end;
      n:=xml.FindNode(table);
      if assigned(n) then
      begin
         export_cpl(n,'GRANT');
         export_cpl(n,'INDEX');
         export_cpl(n,'CHECK');
         export_cpl(n,'REFERENCE');
      end;
    end;

begin
  Node:=xml.FindNode('LINEEND');
  Requete:=nil;
  if assigned(Node) then
  begin
       if (Node.GetChildCount>0) then LineEnd:=Node.FirstChild.NodeValue else lineend:='';
  end else lineend:=';';
  Node:=xml.FindNode('COMMENT');
  if assigned(Node) then
  begin
       if (Node.GetChildCount>0) then Comment:=Node.FirstChild.NodeValue else comment:='';
  end else comment:='--';
  Node:=xml.FindNode('GO');
  if assigned(Node) then
  begin
       if (Node.GetChildCount>0) then go:=Node.FirstChild.NodeValue else go:='';
  end else go:='COMMIT;';

  sql:=comment+' Table '+table+' ';
  if length(sql)<80 then sql:=sql+StringOfChar('*',80 - Length(sql));
  sql:=sql+lineEnding;
  s.Write(sql[1],length(sql));

  // Table Structure export
  sql:=getQuery('QCF03','SELECT COLNAME, TYPE_COL, COLLEN, PRECIS from LWH_COLUMNS where TABLE_NAME=''%t'' ');
  sql:=sql.Replace('%t',table);
  ReadDataset(requete,sql,true);
  table_structure;


  // Data Export
  Requete.close;
  sql:=getQuery('QCF04','SELECT * from %t ORDER BY 1');
  sql:=sql.Replace('%t',table);
  ReadDataset(requete,sql,true);
  sql:=' '+lineEnding;
  if requete.RecordCount>0 then
  begin
    if comment>' ' then sql:=comment+' '+table+' Data'+lineEnding;
    s.Write(sql[1],length(sql));
    insert:='INSERT INTO '+table+' (';
    for i := 0 to Requete.FieldCount - 1 do
    begin
      if i>0 then insert:=insert+', ';
      insert := insert+Requete.fields[i].FieldName;
    end;
    insert:=insert+') VALUES (';

    while not Requete.EOF do
    begin
         sql:=insert;
         for i := 0 to Requete.FieldCount - 1 do
         begin
           if i>0 then sql:=sql+', ';
           FieldType:= Requete.Fields[i].DataType;
           case Requete.Fields[i].DataType of

           ftString,ftMemo,ftWideString,ftfixedchar :
           begin

                if requete.Fields[i].IsNull then sql:=sql+'NULL' else
                sql:=sql + quotedstr(Requete.Fields[i].asString);
           end;
           ftAutoInc,ftLargeInt,ftSmallint, ftInteger, ftWord, ftFloat :
           begin
                if requete.Fields[i].IsNull then sql:=sql+'NULL' else
                sql:=sql+Requete.Fields[i].asString;
           end;
           ftTimestamp :
           begin
                if requete.Fields[i].IsNull then sql:=sql+'NULL' else
                sql:=sql+quotedstr(Requete.Fields[i].asString);
           end;
           ftDateTime :
           begin
                if requete.Fields[i].IsNull then sql:=sql+'NULL' else
                sql:=sql+quotedstr(FORMATDATETIME('YYYY-MM-DD HH:MM:SS.ZZZ',Requete.Fields[i].asDatetime));
           end
           else
           begin
               { todo : lwh- message eddeur }

               showmessage(Requete.fields[i].FieldName);
           end;

    {       TFieldType = (ftUnknown, ftString, ftSmallint, ftInteger, ftWord,
      ftBoolean, ftFloat, ftCurrency, ftBCD, ftDate,  ftTime, ftDateTime,
      ftBytes, ftVarBytes, ftAutoInc, ftBlob, ftMemo, ftGraphic, ftFmtMemo,
      ftParadoxOle, ftDBaseOle, ftTypedBinary, ftCursor, ftFixedChar,
      ftWideString, ftLargeint, ftADT, ftArray, ftReference,
      ftDataSet, ftOraBlob, ftOraClob, ftVariant, ftInterface,
      ftIDispatch, ftGuid, ftTimeStamp, ftFMTBcd, ftFixedWideChar, ftWideMemo);}
           end;
         end;
         sql:=sql+')'+lineend + LineEnding;
         s.Write(sql[1],length(sql));

         Requete.next;
    end;
    if (go>' ') then
    begin
       sql:=go+lineEnding;
       s.Write(sql[1],length(sql));
    end;
  end; // if requete.RecordCount>0 then
  // Triggers
  n:=xml.FindNode(table);
  export_cpl(n,'TRIGGERS');
  export_cpl(n,'INIT');

  Requete.close;
  Requete.free;
end;


procedure TMainData.Export_script(s : tstream; modele : shortstring);

var Doc: TXMLDocument;
    BDDNode: TDOMNode;
    requete : TDataSet;
    sql : string;

begin
    try
      try
        Screen.Cursor := crHourGlass;
        Requete:=nil;
        sql:='';
        ReadXMLFile(Doc, sqlsyntaxfile,[]);
        if assigned(Doc) then
        begin
           BDDNode:=Doc.DocumentElement.FindNode(modele);
        end;

        export_data_toStream(s, 'LWH_BKDIR',BDDNode);
        export_data_toStream(s, 'LWH_CFG',BDDNode);
        export_data_toStream(s, 'LWH_COLUMNS',BDDNode);
        export_data_toStream(s, 'LWH_HISTO',BDDNode);
        export_data_toStream(s, 'LWH_ID',BDDNode);
        export_data_toStream(s, 'LWH_IHM',BDDNode);

        // TODo : mettre une priorité pour les contraites référentielles
        sql:=Maindata.getQuery('QC001','SELECT DISTINCT TABLE_NAME FROM LWH_COLUMNS');
        ReadDataSet(Requete,sql,true);

        while not Requete.EOF do
        begin
            export_data_toStream(s,Requete.Fields[0].asString,BDDNode);
            Requete.next;
        end;
        Requete.close;
      except
        on e : exception do Error (e, dber_system,'TMainData.Export_script ('+modele+') '+sql);
      end;
    finally
     Requete.free;
     Doc.free;
     Screen.Cursor := crDefault;
    end;
end;

procedure TMainData.exporter;

var
  saveDialog: TSaveDialog;
  strm: TFileStream;

begin
  saveDialog := TSaveDialog.Create(self);
  if assigned(savedialog) then
  begin
    saveDialog.Title := 'Export des données';
    saveDialog.InitialDir := GetCurrentDir;
    saveDialog.Filter :=
      'Script MySql|*.sql|Script SQLite|*.sql|Script SQL Server|*.sql|Script Access |*.sql|Script Firebird|*.sql|Script MariaDB |*.sql|Script PostgreSQL|*.sql|Classeur Excel|*.xlsx';
    saveDialog.DefaultExt := 'csv';
    saveDialog.FilterIndex := 1;
    savedialog.options := [ofOverwritePrompt, ofViewDetail, ofAutopreview,
      ofPathMustExist, ofForceShowHidden];
    if saveDialog.Execute then
    begin
         strm := TFileStream.Create(savedialog.FileName, fmCreate);

         case savedialog.FilterIndex of
          1 : Export_script(strm,'MYSQL');
          2 : Export_script(strm,'SQLITE');
          3 : Export_script(strm,'SQLSERVER');
          4 : Export_script(strm,'ACCESS');
          5 : Export_script(strm,'FIREBIRD');
          6 : Export_script(strm,'MARIADB');
          7 : Export_script(strm,'POSTGRESQL');
         end;

         strm.free;

    end;
    saveDialog.Free;
  end;
end;

function TMainData.doScript(script : string):boolean;

var DBEScript: TSQLScript;
    ZEOScript: TZSQLProcessor;

begin
  if isnullorempty(script) then exit;
  Screen.Cursor:=crSQLWait;
  MainForm.setMicroHelp(script,0);
  result:=true;
  ZEOScript:=nil;
  DBEScript:=nil;
  try
     try
        if cmode='ZEO' then
        begin
             ZEOScript:=TZSQLProcessor.Create(self);
             ZEOScript.Connection:=Zconnection;
             ZEOScript.Script.Add(script);
             ZEOScript.Execute;
        end else
        begin
             DBEScript:=TSQLScript.create(self);
             DBEScript.DataBase:=Database;
             DBEScript.Transaction:=Tran;
             {$IFDEF WINDOWS}
             DBEScript.AutoCommit:=true;
             {$ENDIF}
             DBEScript.Script.Add(script);
             DBEScript.Execute;
             Tran.Commit;
        end;
     except
         on e : Exception do
         begin
              Error (e, dber_sql,'TmainData.Doscript '+script);
              if cmode='DBE' then tran.Rollback;
         end;
     end;
  finally
     if assigned(ZEOScript) then freeandnil(ZEOScript);
     if assigned(DBEScript) then freeandnil(DBEScript);
     Screen.cursor:=crDefault;
     MainForm.setMicroHelp(rs_ready,0);
  end;
end;

function TMainData.getIhm(l,c : string) : TJSonData;

var sjson : string;

begin
  if assigned(ihm) then
  begin
    ihm.TryGetValue(c, sjson);
    if sjson<='' then sjson:='{}';
    result:=GetJson(sjson);
  end;
end;

function TMainData.getTimestamp : shortstring;

begin
  result:=FORMATDATETIME(GetSyntax('ROWVERSION','YYYY-MM-DD HH:MM:SS.ZZZ'),now);
end;

function TMainData.getSyntax(topic : string; def : string) : string;

var Node : TDomNode;

begin
  result:=def;
  if assigned(xmlSyntax) then
  begin
    Node:=xmlSyntax.FindNode(topic);
    if assigned(Node) and (Node.GetChildCount>0) then result:=Node.FirstChild.NodeValue else result:=def;
  end;
end;

function TMainData.getQuery(topic : string; def : string = '') : string;

var Node : TDomNode;

begin
  result:=def;
  if assigned(xmlSyntax) then
  begin
    Node:=xmlSyntax.FindNode('QUERIES');
    if assigned(Node) and (Node.GetChildCount>0) then Node:=Node.FindNode(topic);
    if assigned(Node) and (Node.GetChildCount>0) then result:=Node.FirstChild.NodeValue else result:=def;
  end;
end;

function TMainData.isConnected : boolean;

begin
    if cnx then
    begin
         if cmode='DBE' then
         begin
              if ConnectorType='ODBC' then isConnected:=ODBC.Connected
              ELSE isConnected:=SQLConnector.connected;
         end else
         begin
           isConnected:=ZConnection.Connected;
         end;
    end else isConnected:=false;
end;


function TMainData.getInfoConnect : String;

var
  OsVersion, MajVer, MinVer: ShortString;

begin
  Majver:='';
   MinVer:='';
  {$IFDEF LCLcarbon}
   OSVersion := 'Mac OS X 10.';
   {$ELSE}
   {$IFDEF Linux}
   OSVersion := 'Linux Kernel ';
   {$ELSE}
   {$IFDEF UNIX}
   OSVersion := 'Unix ';
   {$ELSE}
   {$IFDEF WINDOWS}
   if WindowsVersion = wv95 then OSVersion := 'Windows 95 '
    else if WindowsVersion = wvNT4 then OSVersion := 'Windows NT v.4 '
    else if WindowsVersion = wv98 then OSVersion := 'Windows 98 '
    else if WindowsVersion = wvMe then OSVersion := 'Windows ME '
    else if WindowsVersion = wv2000 then OSVersion := 'Windows 2000 '
    else if WindowsVersion = wvXP then OSVersion := 'Windows XP '
    else if WindowsVersion = wvServer2003 then OSVersion := 'Windows Server 2003 '
    else if WindowsVersion = wvVista then OSVersion := 'Windows Vista '
    else if WindowsVersion = wv7 then OSVersion := 'Windows 7 '
    else OSVersion:= 'Windows ';
   {$ENDIF}
   {$ENDIF}
   {$ENDIF}
   {$ENDIF}
  {$IFDEF WINDOWS}
  MajVer := IntToStr(Win32MajorVersion);
  MinVer := IntToStr(Win32MinorVersion);
  {$ELSE}
  MajVer := IntToStr(Lo(DosVersion) - 4);
  MinVer := IntToStr(Hi(DosVersion));
  {$ENDIF}
  OSVersion:=OSVersion+' '+MajVer+'.'+Minver;
  result:='('+OSVersion+')';
  if isConnected then
   begin
     if cmode='ZEO' then
     begin
       result:=ZConnection.Protocol+' '+ZConnection.Database+' '+result;
     end else
     begin
          if leftstr(ConnectorType,4)='ODBC' then
          begin
            result:='ODBC '+result;
          end else
          begin
            result:=sqlConnector.ConnectorType+' '+sqlconnector.DatabaseName+' '+result;
          end;
     end;
     result:=Mainform.UserName+' - '+result;
   end else result:=rs_diconnected;
end;

function TMainData.isSyntaxFile(f : shortstring):boolean;

var Xml: TXMLDocument;
    xmlS :  TDOMNode;

begin
     result:=false;
     if FileExists(f) then
     begin
        try
        ReadXMLFile(Xml, f,[]);
        if assigned(Xml) then
        begin
           try
              xmlS:=Xml.DocumentElement.FindNode(syntax);
              if assigned(xmls) then result:=true;
           finally
              freeAndNil(xmls);
           end;
        end;
        finally
           freeAndNil(xml);
        end;
     end;
end;

function TMainData.IsNullOrEmpty(s : string) : boolean;

begin
  Result:=system.Length(SysUtils.Trim(s))=0;
end;

(* Load Tables Definitions and user interface settings                        *)
procedure TMainData.LoadDeff;

var t :  TColumnDesc;
    code : ShortString;
    user : ShortString;
    sql : string;
    requete : Tdataset;


begin
  sql:='';
  requete:=nil;
  MainForm.setMicroHelp(rs_loadcfg,0);
  try
    try
      freeandnil(tablesdesc);
      freeandnil(ihm);
      tablesdesc:=TTableDesc.create;
      sql:=Maindata.getQuery('Q0008','SELECT TABLE_NAME, COLNAME,EXTERNAL_NAME, SYSCOL, TYPE_COL, COLLEN, PRECIS, MASK, CHARCASE DEFVAL, CTRL, JSON FROM LWH_COLUMNS');
      readDataset(requete,sql,true);
      Requete.First;
      while not Requete.EOF do
      begin
             t:=tablesdesc.add;
             ASSERT(assigned(t),'Erreur ajout élément');
             t.table_name:=(Requete.Fields[0].asString).ToUpper;
             t.col_name:=(Requete.Fields[1].asString).ToUpper;
             t.external_name:=Requete.Fields[2].asString;
             code:=Requete.Fields[3].AsString+'N';
             t.syscol:=code[1];
             t.col_type:=Requete.Fields[4].asString;
             t.col_lenght:=Requete.Fields[5].asInteger;
             t.col_prec:=Requete.Fields[6].asInteger;
             t.mask:=Requete.Fields[7].asString;
             code:=Requete.Fields[8].AsString+'A';
             t.charcase:=code[1];
             t.defval:=Requete.Fields[9].asString;
             t.ctrl:=Requete.Fields[10].asString;
             t.json:=Requete.Fields[11].asString;
             Requete.next;
      end;
      Requete.close;


      ihm:=TIhm.create;

      sql:=Maindata.getQuery('Q0009','SELECT CODE, USERNAME, JSON FROM LWH_IHM WHERE USERNAME=''admin'' OR USERNAME=''%u''');
      sql:=sql.Replace('%u',MainForm.username);
      readDataset(requete,sql,true);
      Requete.First;
      while not Requete.EOF do
      begin
           code:=Requete.FieldByName('CODE').asString;
           user:=Requete.FieldByName('USERNAME').asString;
           IF (not ihm.ContainsKey(code)) or (user<>'admin') then
           begin
             ihm.AddOrSetValue(code, Requete.FieldByName('JSON').asString);
           end;
           Requete.next;
      end;
    except
        on e : exception do Error (e, dber_sql,'LOAD IHM. TMainData.LoadDeff '+sql);
    end;
  finally
   if cmode='DBE' then
   begin
        TSqlTransaction(TsqlQuery(requete).Transaction).Commit;
   end;
   Requete.free;
   MainForm.setMicroHelp(rs_ready,0);
  end;
end;

function TMainData.Login : boolean; (* ************************************** *)

VAR Rubrique : string;
    s : String;
    flogin : TFlogin;
    modalresult : integer;
    username, password: shortstring;
    Info : SearchRec;


begin
   Assert(assigned(ini),'INI File not Initialized');
   IF not assigned(SQLConnector) THEN SQLConnector:=TSQLConnector.Create(nil);
   IF SQLConnector.connected THEN SQLConnector.close;
   IF ZConnection.Connected then ZConnection.Disconnect;
   cnx:=false;
   flogin:=TFLogin.Create(Mainform);
   while NOT cnx do
   begin
     MainForm.setMicroHelp(rs_connectchoice,0);
     modalresult:=flogin.ShowModal;
     MainForm.setMicroHelp(rs_connecting,0);
     if modalresult<>1 then break;
     username:=flogin.login;
     password:=flogin.password;
     rubrique:=flogin.profil;
     if Rubrique='' then  rubrique:=INI.ReadString('DEFAULT','CNX','');
     if Rubrique='' then
     begin
          ini.WriteString('DEFAULT','CNX','CNX01');
          ini.WriteString('CNX01','CONNECTORTYPE','SQLite3');
          ini.WriteString('CNX01','SQLSYNTAX','SQLITE');
          ini.WriteString('CNX01','DATABASENAME','Pampa.db');
          Rubrique:='CNX01';
     end;
     try
        syntax:=Ini.Readstring(Rubrique,'SQLSYNTAX','STDT');
        cmode:=Ini.Readstring(Rubrique,'MODE','ZEO');
        cmode:=uppercase(cmode);
        if cmode='DBE' then
        begin
          ConnectorType:=Ini.Readstring(Rubrique,'CONNECTORTYPE','');
          if connectorType='ODBC' then
          begin
            ODBC.Driver:='';
            ODBC.FileDsn:='';
            ODBC.Hostname:='';
            ODBC.UserName:='';
            ODBC.Password:='';
           { ODBC.Driver:=Ini.Readstring(Rubrique,'DRIVER','');
            ODBC.FileDSN:=Ini.Readstring(Rubrique,'FILEDSN','');
            ODBC.HostName:=Ini.Readstring(Rubrique,'HOSTNAME','');
            ODBC.Params.text:=Ini.Readstring(Rubrique,'PARAMS','');
            ODBC.UserName:=username;
            ODBC.Password:=password;}
            ODBC.Params.Clear;
            ODBC.Params.add('Driver='+Ini.Readstring(Rubrique,'DRIVER',''));
            ODBC.Params.add('Server='+Ini.Readstring(Rubrique,'HOSTNAME',''));
            ODBC.Params.add('Database='+Ini.Readstring(Rubrique,'DATABASENAME',''));
            ODBC.Params.add('CharSet='+Ini.Readstring(Rubrique,'CHARSET',''));
            ODBC.Params.add(Ini.Readstring(Rubrique,'PARAMS',''));
            ODBC.Params.add('AUTOCOMMIT=1');
            ODBC.Params.add('AUTOTRANSLATE=YES');
            ODBC.Params.add('APP=PAMPA');
            ODBC.PARAMS.add('ApplicationIntent=ReadWrite');
            ODBC.PARAMS.add('AnsiNPW=yes');
            ODBC.PARAMS.ADD('MultipleActiveResultSets=true');
            s:=Odbc.params.Text;
            {ODBC.CharSet:=Ini.Readstring(Rubrique,'CHARSET','');
            if trim(ODBC.UserName)>' ' then
            begin
                 MainForm.UserName:=trim(ODBC.UserName);
            end;}
          end else
          begin
            SQLConnector.ConnectorType:=Ini.Readstring(Rubrique,'CONNECTORTYPE','');
          //  SQLDBLibraryLoader1.ConnectionType:=SQLConnector.ConnectorType;
          //  SQLDBLibraryLoader1.LoadLibrary;
            SQLConnector.DatabaseName:=Ini.Readstring(Rubrique,'DATABASENAME','');
            SQLConnector.Hostname:=Ini.Readstring(Rubrique,'HOSTNAME','');
            SQLConnector.Charset:=Ini.Readstring(Rubrique,'CHARSET','');
            SQLConnector.UserName:=username;
            SQLConnector.Password:=password;
            SQLConnector.Params.text:=Ini.Readstring(Rubrique,'PARAMS','');
            if trim(SQLConnector.UserName)>' ' then
            begin
                 MainForm.UserName:=trim(SQLConnector.UserName);
            end;
          end;

        end else // if cmode='DBE' then
        begin
            cmode:='ZEO' ;
            ZConnection.Protocol:=Ini.Readstring(Rubrique,'CONNECTORTYPE','');
            ZConnection.Database:=Ini.Readstring(Rubrique,'DATABASENAME','');
            ZConnection.HostName:=Ini.Readstring(Rubrique,'HOSTNAME','');
           // ZConnection.Port:=Ini.ReadInteger(Rubrique,'PORT',null);
            ZConnection.ClientCodePage:=Ini.Readstring(Rubrique,'CHARSET','');
            ZConnection.User:=username;
            ZConnection.Password:=password;
            ZConnection.Properties.Add('Undefined_Varchar_AsString_Length= 800');
            ZConnection.Properties.Add(Ini.Readstring(Rubrique,'PARAMS',''));
        end;
     except
         on e : Exception do Error (e, dber_cfg,'TMainData.Login Profil='+rubrique+' Mode='+cmode);
     end;
     try
       try
          Screen.Cursor:=crSQLWait;
          if cmode='ZEO' then
          begin
               ZConnection.Connect;
               cnx:=ZConnection.Connected;
               //Database:=ZConnection;
          end else
          begin
               if connectortype='ODBC' then
               begin
                    ODBC.Connected:=true;
                    Database:=ODBC;
                    if ODBC.Connected then cnx:=true;
               end else
               begin
                  SQLConnector.connected:=true;
                  Database:= SQLConnector;
                  if SQLConnector.connected then cnx:=true;
               end;
          end;
       except
           on e : Exception do
           begin
                Error (e, dber_cfg,'TMainData.Login');
                //exit;
           end;
       end;
     finally
      Screen.Cursor:=crDefault;
     end;
   end;
   Login:=cnx;
   sqlsyntaxfile:=INI.ReadString('DEFAULT','SQLSYNTAX','SqlSyntax.xml');
   sqlsyntaxfile:=ExpandFileName(sqlsyntaxfile);
   while not FileExists(sqlsyntaxfile) do
   begin
     if Application.MessageBox('Le fichier de configuration n existe pas ou est invalide. Choisir un fichier ?','Fichier de configuration', MB_ICONQUESTION + MB_YESNO)=IDYES  then
     begin
          if OpenDialog1.Execute then
          begin
            sqlsyntaxfile:=OpenDialog1.FileName;
            sqlsyntaxfile:=ExpandFileName(sqlsyntaxfile);
            if isSyntaxFile(sqlsyntaxfile) then
            begin
              INI.WriteString('DEFAULT','SQLSYNTAX',sqlsyntaxfile);
            end;
          end else
          begin
              Application.Terminate;
              exit;
          end;
     end else
     begin
        Application.Terminate;
        exit;
     end;
   end;
   if assigned(flogin) then freeandnil(flogin);
   if cnx then
   begin
      if cmode='DBE' then Tran.Database:=Database;
      try
        if assigned(XmlDoc) then FreeAndNil(XmlDoc);
        ReadXMLFile(XmlDoc, sqlsyntaxfile,[]);
        if assigned(XmlDoc) then
        begin
           xmlSyntax:=XmlDoc.DocumentElement.FindNode(syntax);
        end;
      except
          on e : Exception do Error (e, dber_cfg,'TMainData.Login');
      end;
   end;
   MainForm.setMicroHelp(rs_ready,0);
   MainForm.StatusBar1.Panels[1].Text := getInfoConnect;
end;

procedure TMainData.Logon;

begin
      if Login then
      begin
            LoadDeff;
      end;
end;

procedure TMainData.Logoff;

begin
  if SQLConnector.Connected  then SQLConnector.Connected := False;
  freeandnil(tablesdesc);
  freeandNil(Ihm);
end;

procedure TMainData.DataModuleCreate(Sender: TObject);


begin
     cnx := false;
     try
       ini:=Tinifile.create('Pampa.ini');
     except
       on e : Exception do Error (e, dber_cfg,'TMainData.DataModuleCreate');
     end;
end;

procedure TMainData.CnxAfterConnect(Sender: TObject);
begin

end;

procedure TMainData.SQLConnectorAfterConnect(Sender: TObject);
begin
     MainForm.StatusBar1.Panels[1].Text := getInfoConnect;
end;

procedure TMainData.SQLConnectorAfterDisconnect(Sender: TObject);
begin

end;

procedure TMainData.SQLConnectorLog(Sender: TSQLConnection;
  EventType: TDBEventType; const Msg: String);

var s : string;

begin
  {$IFDEF DEBUG}
  s:='';
  case EventType of
       detCustom :    s:='Custom          ';
       detPrepare :   s:='Prepare         ';
       detExecute :   s:='    Execute     ';
       detFetch :     s:='      Fetch     ';
       detCommit :    s:='Commit          ';
       detRollBack :  s:='Rollback        ';
       else           s:='Unknow          ';
  end;
  s:=s+' '+Msg;
  MainForm.log(s);
  {$ENDIF}
end;

// todo : procedure WriteDataSet;
function TmainData.ReadDataSet(var R: Tdataset; sql : string; readonly : boolean ;  sinsert : string = ''; sdelete : string = ''; supdate : string='') : boolean;

var upd : TZUpdateSQL;

begin
  if isnullorempty(sql) then MainForm.setMicroHelp(rs_read,0) else MainForm.setMicroHelp(sql,0);
  Screen.Cursor:=crHourglass;
  result:=true;
  try
     try
      if not assigned(R) then
      begin
         if MainData.cmode='ZEO' then
         begin
              if readonly then
              begin
                R:=TZReadOnlyQuery.create(Mainform);
                TZReadOnlyQuery(R).connection:=Maindata.ZConnection;
              end else
              begin
                   R:=TZQuery.create(Mainform);
                   TZQuery(R).connection:=Maindata.ZConnection;
              end;
         end else
         begin
              R:=TSQLQuery.create(Mainform);
              TSQLQuery(R).DataBase:=MainData.Database;
              TSQLQuery(R).transaction:=MainData.tran;
         end;
      end;
     except
         on e : Exception do Error (e, dber_sql,'TmainData.ReadDataSet '+sql);
     end;
     try
      if (assigned(R)) and (isConnected) and (not isnullorempty(sql)) then
      begin
          Screen.Cursor:=crSQLWait;
          R.Close;
          if R is TZQuery then
          begin
            TZQuery(R).SQL.text:=sql;
            if (not readonly) then
            begin
                 //TZQuery(R).UpdateMode:=umUpdateChanged;
                 IF (sinsert>' ') or (supdate>' ') or (sdelete>' ') then
                 begin
                   upd:=TZquery(R).UpdateObject;
                   if not assigned(upd) then
                   begin
                       upd:=TZUpdateSQL.Create(R);
                   end;
                   if sinsert>' ' then upd.InsertSQL.Text:=sinsert;
                   if supdate>' ' then upd.ModifySQL.Text:=supdate;
                   if sdelete>' ' then upd.DeleteSQL.Text:=sdelete;
                   TZquery(R).UpdateObject:=upd;
                 end;
            end;
            TZQuery(R).prepare;
          end else
          if R is TZReadOnlyQuery then
          begin
            TZReadOnlyQuery(R).SQL.text:=sql;
            TZReadOnlyQuery(R).prepare;
          end else
          if R is TSQLQuery then
          begin
            TSQLQuery(R).SQL.text:=sql;
            if (not readonly) then
            begin
                 TSQLQuery(R).UpdateMode:=upWhereKeyOnly;
                 if sinsert>' ' then TSQLQuery(R).InsertSQL.Text:=sinsert;
                 if supdate>' ' then TSQLQuery(R).UpdateSQL.Text:=supdate;
                 if sdelete>' ' then TSQLQuery(R).DeleteSQL.Text:=sdelete;
            end;
            TSQLQuery(R).prepare;
          end else
          begin
            assert(false,'Not TZQuery or TZReadOnlyQuery or  TSQLQuery');
          end;
          R.open;
          if MainData.cmode='DBE' then TSqlTransaction(TSqlQuery(R).Transaction).CommitRetaining ;
      end;
     except
         on e : Exception do
         begin
           Error (e, dber_sql,'TmainData.ReadDataSet '+sql);
           if assigned(R) then R.close;
           if MainData.cmode='DBE' then TSqlTransaction(TSqlQuery(R).Transaction).Commit;
         end;
     end;
  finally
     Screen.cursor:=crDefault;
     MainForm.setMicroHelp(rs_ready,0);
  end;
end;

(* Save User interface settings                                               *)
procedure TmainData.SaveIhm(code,json : string);

var sdelete, sinsert : string;
    R : TSqlQuery;
    P : TZSqlProcessor;

begin
  if cnx then
  begin
     R:=nil;
     P:=nil;
     try
       try
         sdelete:='DELETE FROM LWH_IHM WHERE CODE='+quotedstr(code)+' AND USERNAME='+quotedstr(Mainform.username)+';';
         sinsert:='INSERT INTO LWH_IHM (CODE,USERNAME,JSON) VALUES ('+quotedstr(code)+','+quotedstr(Mainform.username)+','+quotedstr(json)+');';
         if cmode='ZEO' then
         begin
              P:=TZSqlProcessor.create(self);
              P.connection:=Maindata.ZConnection;
              P.Script.ADD(sdelete);
              P.Script.Add(sinsert);
              P.Execute;
         end else
         begin
              R:=TSQLQuery.create(self);
              TSQLQuery(R).DataBase:=MainData.Database;
              TSQLQuery(R).transaction:=MainData.tran;
              R.SQL.Text:=sdelete;
              R.ExecSQL;
              R.SQL.Text:=sinsert;
              R.ExecSQL;
              Tran.commit;
         end;

{         if MainForm.username<>'admin' then
         begin
            R.sql.text:='SELECT 1 FROM LWH_IHM WHERE CODE='+quotedstr(code)+' AND USERNAME=''admin'';';
            R.open;
            if R.recordCount=0 then
            begin
                 R.close;
                 s:='INSERT INTO LWH_IHM (CODE,USERNAME,JSON) VALUES ('+quotedstr(code)+',''admin'', '+quotedstr(json)+')';
                  R.Sql.text:=s;
                  R.ExecSQL;;
            end;
         end;
         Tran.commit; }
         ihm.AddOrSetValue(code,json);
     except
         on e : Exception do
             Error (e, dber_sql,'UPDATE IHM. TmainData.SaveIHM '+sdelete+' / '+sinsert);
     end;
     finally
      if assigned(R) then
      begin
        R.close;
        R.free;
      end;
      if assigned(P) then
      begin
        P.Free;
      end;
     end;
  end;
end;

procedure TMainData.SQLScript1Exception(Sender: TObject; Statement: TStrings;
  TheException: Exception; var Continue: boolean);
begin
  continue:=true;
end;

function TMainData.WriteDataSet(var R: Tdataset) : boolean;

var s : string;

begin
  assert(assigned(R),'Dataset not assigned');
  result:=false;
  Screen.Cursor:=crSQLWait;
  s:=MainForm.StatusBar1.Panels[0].Text;
  MainForm.StatusBar1.Panels[0].Text := rs_write;
  try
    try
      if R is TZQuery then
      begin
        R.Post;
        TZquery(R).ApplyUpdates;
        result:=true;
      end else
      if R is TSQLQuery then
      begin
        R.Post;
        TSQLQuery(R).ApplyUpdates;
        TSqlTransaction(TSQlQuery(R).Transaction).CommitRetaining;
        result:=true;
      end;
    except
          on e : Exception do
          begin
               Error (e, dber_sql,'TMainData.WriteDataSet');
               result:=false;
          end;
    end;
  finally
    Screen.Cursor := crDefault;
    MainForm.StatusBar1.Panels[0].Text := s;
  end;
end;

end.


end.

