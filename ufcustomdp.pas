unit UFCustomDp;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls, StdCtrls,
  Buttons, Spin, DBCtrls, ExtCtrls, ActnList, Menus,
  DataPanel, LWData, ZConnection;

type

  Tchange = (ch_all, ch_dimpos);

  { TFCustomDP }

  TFCustomDP = class(TForm)
    Act_add_bevel: TAction;
    Act_add_button: TAction;
    Act_add_flag: TAction;
    Act_add_text: TAction;
    Act_add_field: TAction;
    Act_taborder: TAction;
    Act_space_horizontal: TAction;
    Act_space_vertical: TAction;
    Act_size_height: TAction;
    Act_size_width: TAction;
    Act_align_right: TAction;
    Act_align_left: TAction;
    Act_align_top: TAction;
    Act_align_bottom: TAction;
    Act_delete: TAction;
    Act_save: TAction;
    Act_close: TAction;
    ActionList1: TActionList;
    Btn_supr: TBitBtn;
    Button1: TButton;
    Btn_close: TBitBtn;
    Btn_tab: TBitBtn;
    Btn_save: TBitBtn;
    CheckBox1: TCheckBox;
    chk_color: TCheckBox;
    ColorButton1: TColorButton;
    ColorDialog1: TColorDialog;
    ComboBox1: TComboBox;
    ComboBox_kind: TComboBox;
    ComboBox_fields: TComboBox;
    EdHint: TEdit;
    Ed_caption: TEdit;
    Gb_align: TGroupBox;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    Label1: TLabel;
    Label10: TLabel;
    Label11: TLabel;
    Label12: TLabel;
    Label13: TLabel;
    Label14: TLabel;
    Label15: TLabel;
    Label16: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    DDM_align: TPopupMenu;
    MenuItem1: TMenuItem;
    MenuItem10: TMenuItem;
    MenuItem11: TMenuItem;
    MI_add_bevel: TMenuItem;
    MI_add_flag: TMenuItem;
    MI_add_button: TMenuItem;
    MI_add_label: TMenuItem;
    MI_add_field: TMenuItem;
    MenuItem2: TMenuItem;
    MenuItem3: TMenuItem;
    MenuItem4: TMenuItem;
    MenuItem5: TMenuItem;
    MenuItem6: TMenuItem;
    MenuItem7: TMenuItem;
    MenuItem8: TMenuItem;
    MenuItem9: TMenuItem;
    DDM_Add: TPopupMenu;
    PosH: TSpinEdit;
    PosW: TSpinEdit;
    PosX: TSpinEdit;
    PosY: TSpinEdit;
    SB_alignRight: TSpeedButton;
    SB_AlignLeft: TSpeedButton;
    SB_AlignTop: TSpeedButton;
    SB_AlignBottom: TSpeedButton;
    SB_SizeWidth: TSpeedButton;
    SB_SizeHeight: TSpeedButton;
    SETaborder: TSpinEdit;
    SpeedButton1: TSpeedButton;
    SpeedButton2: TSpeedButton;
    StaticText1: TStaticText;
    St_flag: TStaticText;
    St_bevel: TStaticText;
    St_text: TStaticText;
    St_column: TStaticText;
    St_button: TStaticText;
    Tab: TPageControl;
    ToolBar1: TToolBar;
    TB_close: TToolButton;
    TB_save: TToolButton;
    TB_delete: TToolButton;
    TB_align: TToolButton;
    tb_add: TToolButton;
    TS_Add: TTabSheet;
    Ts_gen: TTabSheet;
    TS_control: TTabSheet;
    TS_format: TTabSheet;
    procedure Act_add_bevelExecute(Sender: TObject);
    procedure Act_add_buttonExecute(Sender: TObject);
    procedure Act_add_fieldExecute(Sender: TObject);
    procedure Act_add_flagExecute(Sender: TObject);
    procedure Act_add_textExecute(Sender: TObject);
    procedure Act_space_horizontalExecute(Sender: TObject);
    procedure Act_align_bottomExecute(Sender: TObject);
    procedure Act_align_leftExecute(Sender: TObject);
    procedure Act_align_rightExecute(Sender: TObject);
    procedure Act_align_topExecute(Sender: TObject);
    procedure Act_closeExecute(Sender: TObject);
    procedure Act_size_heightExecute(Sender: TObject);
    procedure Act_size_widthExecute(Sender: TObject);
    procedure Act_space_verticalExecute(Sender: TObject);
    procedure Act_taborderExecute(Sender: TObject);
    procedure Btn_closeClick(Sender: TObject);
    procedure Btn_saveClick(Sender: TObject);
    procedure Btn_suprClick(Sender: TObject);
    procedure chk_colorChange(Sender: TObject);

    procedure ColorButton1ColorChanged(Sender: TObject);
    procedure ComboBox_fieldsChange(Sender: TObject);
    procedure ComboBox_kindChange(Sender: TObject);
    procedure Ctrl_buttonClick(Sender: TObject);
    procedure Ctrl_columnClick(Sender: TObject);
    procedure Ctrl_flagClick(Sender: TObject);
    procedure Ctrl_textClick(Sender: TObject);
    procedure EdHintChange(Sender: TObject);
    procedure Ed_captionChange(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormDragOver(Sender, Source: TObject; X, Y: integer;
      State: TDragState; var Accept: boolean);
    procedure PosHChange(Sender: TObject);
    procedure PosWChange(Sender: TObject);
    procedure PosXChange(Sender: TObject);
    procedure PosYChange(Sender: TObject);
    procedure SETaborderChange(Sender: TObject);
    procedure TabChange(Sender: TObject);
    procedure TS_AddMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
  private
    changing: boolean;
    fpanel: TDataPanel;
    oldnbsel: integer;
    selectedControl: TLWControl;
    constructor Init(AOwner: TComponent);
    procedure remplir_combo_kind(c: TLWControl);
  public
    insert_object : shortstring;
    class function Create(AOwner: TComponent): TFCustomDP;
    class function get: TFCustomDP;
    procedure PanelChange(change: Tchange);
    procedure setInsertObject(o : shortstring);
    procedure setpanel(p: TDataPanel);
    procedure UpdateTSControl;
    destructor Destroy; override;
  end;

var
  FCustomDP: TFCustomDP;

implementation

uses Main;

{$R *.lfm}

procedure TFCustomDP.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  if assigned(fpanel) then
    fpanel.SetDesign(False);
  CloseAction := caHide;
end;

procedure TFCustomDP.FormDragOver(Sender, Source: TObject; X, Y: integer;
  State: TDragState; var Accept: boolean);

begin
  if assigned(Source) and (Source is Tcontrol) (*and (Source is TImage32)*) then
  begin
    if leftStr(TControl(Source).Name, 4) = 'Ctrl' then
      accept := True;
  end;
  accept := True;
end;

procedure TFCustomDP.EdHintChange(Sender: TObject);

var
  c: TLwControl;
  n: shortstring;

begin
  if changing then
    exit;
  n := trim(EdHint.Caption);
  if (assigned(fpanel)) then
  begin
    for c in fpanel.ctrlList.values do
    begin
      if c.selected then
      begin
        c.setHint(n);
      end;
    end;
  end;
end;

procedure TFCustomDP.Ed_captionChange(Sender: TObject);

var
  c: TLwControl;
  n: shortstring;

begin
  if changing then
    exit;
  n := trim(Ed_Caption.Caption);
  if (assigned(fpanel)) then
  begin
    for c in fpanel.ctrlList.values do
    begin
      if c.selected then
      begin
        c.setCaption(n);
      end;
    end;
  end;
end;

procedure TFCustomDP.FormActivate(Sender: TObject);
begin
  Mainform.updatePanel(self);
end;

procedure TFCustomDP.Btn_saveClick(Sender: TObject);
begin
  if assigned(fpanel) then
  begin
    if fpanel.GetDesignMode then fpanel.save;
  end;
  setInsertObject('');
end;

procedure TFCustomDP.Btn_suprClick(Sender: TObject);
begin
  if assigned(fpanel) then
  begin
    if fpanel.GetDesignMode then fpanel.DeleteControls;
  end;
  setInsertObject('');
end;

procedure TFCustomDP.Btn_closeClick(Sender: TObject);
begin
  if assigned(fpanel) then
  begin
    fpanel.SetDesign(False);
  end;
end;

procedure TFCustomDP.Act_closeExecute(Sender: TObject);
begin

end;

procedure TFCustomDP.Act_size_heightExecute(Sender: TObject);
begin
  if assigned(fpanel) then
  begin
    if fpanel.GetDesignMode then fPanel.align('H');
  end;
  setInsertObject('');
end;

procedure TFCustomDP.Act_size_widthExecute(Sender: TObject);
begin
  if assigned(fpanel) then
  begin
    if fpanel.GetDesignMode then fPanel.align('W');
  end;
  setInsertObject('');
end;

procedure TFCustomDP.Act_space_verticalExecute(Sender: TObject);
begin
  setInsertObject('');
end;

procedure TFCustomDP.Act_taborderExecute(Sender: TObject);
begin
  if assigned(fpanel) then
  begin
    if fpanel.GetDesignMode then fpanel.CalcZOrder;
    fpanel.paint(self);
  end;
  setInsertObject('');
end;

procedure TFCustomDP.Act_align_bottomExecute(Sender: TObject);
begin
  if assigned(fpanel) then
  begin
    if fpanel.GetDesignMode then fPanel.align('B');
  end;
  setInsertObject('');
end;

procedure TFCustomDP.Act_space_horizontalExecute(Sender: TObject);
begin
  setInsertObject('');
end;

procedure TFCustomDP.Act_add_fieldExecute(Sender: TObject);
begin
  Tab.ActivePage := TS_add;
  setInsertObject('Ctrl_column');
end;

procedure TFCustomDP.Act_add_flagExecute(Sender: TObject);
begin
  Tab.ActivePage := TS_add;
  setInsertObject('Ctrl_flag');
end;

procedure TFCustomDP.Act_add_buttonExecute(Sender: TObject);
begin
  Tab.ActivePage := TS_add;
  setInsertObject('Ctrl_button');
end;

procedure TFCustomDP.Act_add_bevelExecute(Sender: TObject);
begin
  Tab.ActivePage := TS_add;
  setInsertObject('Ctrl_bevel');
end;

procedure TFCustomDP.Act_add_textExecute(Sender: TObject);
begin
  Tab.ActivePage := TS_add;
  setInsertObject('Ctrl_text');
end;

procedure TFCustomDP.Act_align_leftExecute(Sender: TObject);
begin
  if assigned(fpanel) then
  begin
    if fpanel.GetDesignMode then fPanel.align('L');
  end;
  setInsertObject('');
end;

procedure TFCustomDP.Act_align_rightExecute(Sender: TObject);
begin
  if assigned(fpanel) then
  begin
    if fpanel.GetDesignMode then fPanel.align('R');
  end;
  setInsertObject('');
end;

procedure TFCustomDP.Act_align_topExecute(Sender: TObject);
begin
  if assigned(fpanel) then
  begin
    if fpanel.GetDesignMode then fPanel.align('T');
  end;
  setInsertObject('');
end;



procedure TFCustomDP.chk_colorChange(Sender: TObject);

var
  c: Tcolor;

begin
  if assigned(fpanel) then
  begin
    if chk_color.Checked then
    begin
      c := fpanel.Color;
      ColorButton1.color := c;
      ColorButton1.Visible := True;
    end
    else
    begin
      c := cldefault;
      ColorButton1.Visible := False;
      if fpanel.GetDesignMode then fpanel.setColor(c);
    end;
  end;
  setInsertObject('');
end;

procedure TFCustomDP.ColorButton1ColorChanged(Sender: TObject);

var
  c: Tcolor;

begin
  c := ColorButton1.ButtonColor;
  if assigned(fpanel) then
  begin
    if fpanel.GetDesignMode then fpanel.setColor(c);
  end;
  setInsertObject('');
end;

procedure TFCustomDP.ComboBox_fieldsChange(Sender: TObject);

var
  c: TLwControl;
  n: shortstring;

begin
  if changing then
    exit;
  n := trim(ComboBox_fields.Text);
  if (assigned(fpanel)) then
  begin
    if not fpanel.GetDesignMode then exit;
    for c in fpanel.ctrlList.values do
    begin
      if c.selected then
      begin
        c.SetSField(n);
      end;
    end;
  end;
end;

procedure TFCustomDP.ComboBox_kindChange(Sender: TObject);

var
  i: integer;
  o: TObject;
  o1: TLWStyleItem;

begin
  i := ComboBox_kind.ItemIndex;
  ShowMessage(ComboBox_kind.Items.Values[ComboBox_kind.Items[i]]);
  //     Value := Integer(ComboBox.Items.Objects[ComboBox.ItemIndex]);
end;

procedure TFCustomDP.Ctrl_buttonClick(Sender: TObject);
begin
  act_add_button.Execute;
end;

procedure TFCustomDP.Ctrl_columnClick(Sender: TObject);
begin
  act_add_field.Execute;
end;

procedure TFCustomDP.Ctrl_flagClick(Sender: TObject);
begin
  act_add_flag.Execute;
end;

procedure TFCustomDP.Ctrl_textClick(Sender: TObject);
begin
  act_add_text.Execute;
end;


procedure TFCustomDP.PosHChange(Sender: TObject);
var
  c: TLwControl;
  n: integer;

begin
  if changing then
    exit;
  n := PosH.Value;
  if (assigned(fpanel)) and (n >= 23) then
  begin
    if not fpanel.GetDesignMode then exit;
    for c in fpanel.ctrlList.values do
    begin
      if c.selected then
      begin
        c.setHeight(n);
        fpanel.paint(self);
      end;
    end;
  end;
end;

procedure TFCustomDP.PosWChange(Sender: TObject);

var
  c: TLwControl;
  n: integer;

begin
  if changing then
    exit;
  n := PosW.Value;
  if (assigned(fpanel)) and (n >= 20) then
  begin
    if not fpanel.GetDesignMode then exit;
    for c in fpanel.ctrlList.values do
    begin
      if c.selected then
      begin
        c.setWidth(n);
        fpanel.paint(self);
      end;
    end;
  end;
end;

procedure TFCustomDP.PosXChange(Sender: TObject);

var
  c: TLwControl;
  n: integer;

begin
  if changing then
    exit;
  n := PosX.Value;
  if (assigned(fpanel)) and (n >= 0) then
  begin
    if not fpanel.GetDesignMode then exit;
    for c in fpanel.ctrlList.values do
    begin
      if c.selected then
      begin
        c.setPosX(n);
        fpanel.paint(self);
      end;
    end;
  end;
end;

procedure TFCustomDP.PosYChange(Sender: TObject);

var
  c: TLwControl;
  n: integer;

begin
  if changing then
    exit;
  n := PosY.Value;
  if (assigned(fpanel)) and (n >= 0) then
  begin
    if not fpanel.GetDesignMode then exit;
    for c in fpanel.ctrlList.values do
    begin
      if c.selected then
      begin
        c.setPosY(n);
        fpanel.paint(self);
      end;
    end;
  end;
end;




procedure TFCustomDP.SETaborderChange(Sender: TObject);

var
  c: TLwControl;
  n: integer;

begin
  setInsertObject('');
  if changing then
    exit;
  n := SETaborder.Value;
  if (assigned(fpanel)) and (n >= 0) then
  begin
    if not fpanel.GetDesignMode then exit;
    for c in fpanel.ctrlList.values do
    begin
      if c.selected then
      begin
        c.setTaborder(n);
        fpanel.paint(self);
      end;
    end;
  end;
end;

procedure TFCustomDP.TabChange(Sender: TObject);
begin
  setInsertObject('');
end;

procedure TFCustomDP.TS_AddMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  setInsertObject('');
end;

constructor TFCustomDP.Init(AOwner: TComponent);(* ************************* *)

begin
  inherited Create(AOwner);
  setInsertObject('');
  fpanel := nil;
  changing := False;
  Tab.ActivePageIndex := 0;
  oldnbsel:=0;
end;

class function TFCustomDP.Create(AOwner: TComponent): TFCustomDP;

begin
  if not assigned(FCustomDP) then
  begin
    FCustomDP := TFCustomDP.init(AOwner);
  end;
  assert(assigned(FCustomDP), 'FCustomDP is not assigned');
  //if assigned(FCustomize.Table) then FCustomize.Table.Clear;
  //freeAndNil(FCustomize.Table);
  Result := FCustomDP;
end;

class function TFCustomDP.get: TFCustomDP;

begin
  if not assigned(FCustomDP) then
    TFCustomDP.Create(MainForm);
  get := FCustomDP;
end;

procedure TFCustomDP.PanelChange(change: Tchange);

begin
  Assert(assigned(fpanel),'Fpanel is not assigned');
  changing := True;
  if assigned(fpanel) then
  begin
    if fpanel.nbsel = 0 then
    begin
      Act_delete.Enabled := False;
      if oldnbsel <> fpanel.nbsel then
        Tab.ActivePage := TS_gen;
    end
    else
    begin
      Act_delete.Enabled := True;
    end;
    if fpanel.nbsel = 1 then
    begin
      TS_control.Enabled := True;
      if oldnbsel <> fpanel.nbsel then
        Tab.ActivePage := TS_control;
      UpdateTsControl;
    end
    else
    begin
      TS_control.Enabled := False;
      PosX.Clear;
      PosY.Clear;
      PosH.Clear;
      PosW.Clear;
      edHint.Clear;
      SETaborder.Clear;
    end;
    if fpanel.nbsel > 1 then
    begin
      if oldnbsel <> fpanel.nbsel then
        Tab.ActivePage := TS_format;
      TS_format.Enabled := True;
      act_align_top.Enabled := True;
      act_align_left.Enabled := True;
      act_align_right.Enabled := True;
      act_align_bottom.Enabled := True;
      act_size_width.Enabled := True;
      act_size_height.Enabled := True;
      act_space_horizontal.Enabled := True;
      act_space_vertical.Enabled := True;
    end
    else
    begin
      TS_format.Enabled := False;
      act_align_top.Enabled := False;
      act_align_left.Enabled := False;
      act_align_right.Enabled := False;
      act_align_bottom.Enabled := False;
      act_size_width.Enabled := False;
      act_size_height.Enabled := False;
      act_space_horizontal.Enabled := False;
      act_space_vertical.Enabled := False;
    end;
    oldnbsel := fpanel.nbsel;
    changing := False;
  end;
end;

procedure TFCustomDP.remplir_combo_kind(c: TLWControl);

var
  item: TLWStyleItem;
  o: TObject;

begin
  ComboBox_kind.Items.Clear;
  {$IFDEF WINDOWS}
  case c.ctrlType of
    lwct_column:
    begin
      if not assigned(c.def) then
        exit;
      if (c.def.col_type = 'DATE') then
      begin
        combobox_kind.Items.AddPair('EditMask', 'EM');
        combobox_kind.Items.AddPair('Calendar', 'CA');
      end;
      if c.def.col_type = 'BOOL' then
      begin
        combobox_kind.Items.AddPair('CheckBox', 'CB');
        combobox_kind.Items.AddPair('ListBox', 'LB');
      end;
      if (c.def.col_type = 'CHAR') then
      begin
        combobox_kind.Items.AddPair('Edit', 'ED');
        combobox_kind.Items.AddPair('EditMask', 'EM');
        combobox_kind.Items.AddPair('Memo', 'ME');
        combobox_kind.Items.AddPair('ListBox', 'LB');
        combobox_kind.Items.AddPair('Radiobuttons', 'RB');
        //ComboBox.AddItem(List.Names[i], TObject(StrToInt(List.ValueFromIndex[i], 0)));
      end;
      if (c.def.col_type = 'NUM') then
      begin
        combobox_kind.Items.AddPair('Edit', 'ED');
        combobox_kind.Items.AddPair('EditMask', 'EM');
      end;
    end;
    lwct_label:
    begin
      ComboBox_kind.Enabled := False;
    end;
  end;
  {$ENDIF}
end;


procedure TFCustomDP.setInsertObject(o : shortstring);

begin
  insert_object:=o;
 (* Bvl_column.shape:=bsSpacer;
  Bvl_text.shape:=bsSpacer;
  Bvl_button.shape:=bsSpacer;
  Bvl_flag.shape:=bsSpacer;
  Bvl_bevel.shape:=bsSpacer;
  if insert_object='Ctrl_column' then Bvl_column.shape:=bsFrame;
  if insert_object='Ctrl_text' then Bvl_text.shape:=bsFrame;
  if insert_object='Ctrl_button' then Bvl_button.shape:=bsFrame;
  if insert_object='Ctrl_flag' then Bvl_flag.shape:=bsFrame;
  if insert_object='Ctrl_bevel' then Bvl_bevel.shape:=bsFrame;
  if insert_object='' then Screen.Cursor:=crDefault else Screen.cursor:=crDrag;     *)
end;

{ Indicates which panel is affected by the changes
  @param(p is an object of type TDataPanel)}
procedure TFCustomDP.setpanel(p: TDataPanel);

var c: TCollectionItem;
    pa : TWinControl;

begin
  if (assigned(fpanel)) and (fpanel <> p) then
  begin
    fpanel.setDesign(False);
  end;
  if not assigned(p) then
  begin
    fpanel := nil;
    ComboBox_fields.Clear;
    parent:=nil;
    hide;
    exit;
  end;
  if not p.GetDesignMode then
  begin
    fpanel := nil;
    parent:=nil;
    ComboBox_fields.Clear;
    hide;
    exit;
  end;
  if (fpanel <> p) then
  begin
    fpanel := p;
    Tab.ActivePageIndex := 0;
    oldnbsel := 0;
    {TODO : LWH. Problème avec le parent }
    pa:=p.parent;
    while assigned(pa) and (not (pa is Tform)) do
      begin
           pa:=pa.parent;
      end;
      If assigned(pa) and (pa is Tform) then
      begin
        parent:=pa;
      end else
      begin
       // parent:=nil;
      end;
      parent:=nil;
  end;
  if assigned(p) then
  begin
    if fpanel.ParentBackground then
    begin
      chk_color.Checked := False;
      ColorButton1.Visible := False;
    end
    else
    begin
      ColorButton1.ButtonColor := fpanel.color;
      chk_color.Checked := True;
      ColorButton1.Visible := True;
    end;
    ComboBox_fields.Clear;
    if assigned(fpanel.Columndesc) then
    begin
      for c in fpanel.ColumnDesc do
      begin
        if c is TcolumnDesc then
        begin
          ComboBox_fields.AddItem(TcolumnDesc(c).col_name, c);
        end;
      end;
    end;
  end;
  PanelChange(ch_all);
end;

procedure TFCustomDP.UpdateTSControl;

var
  r: trect;

begin
  if not assigned(fpanel) then
    exit;
  if fpanel.nbsel > 0 then
  begin
    act_delete.Enabled := True;
  end
  else
  begin
    act_delete.Enabled := False;
  end;
  for selectedControl in fpanel.ctrlList.values do
  begin
    if selectedControl.selected then
      break;
  end;
  if (not assigned(selectedControl)) or (not selectedControl.selected) then
  begin
    TS_control.Enabled := False;
    PosX.Clear;
    PosY.Clear;
    PosH.Clear;
    PosW.Clear;
    edHint.Clear;
    SETaborder.Clear;
    exit;
  end;
  TS_control.Enabled := True;
  r := selectedControl.getBounds;
  posX.Value := r.left;
  PosX.Caption := IntToStr(r.left);
  PosX.Enabled := True;
  posY.Value := r.top;
  posY.Caption := IntToStr(R.top);
  posY.Enabled := True;
  posW.Value := r.Right - r.left;
  posW.Caption := IntToStr(R.Width);
  posW.Enabled := True;
  posH.Value := r.Bottom - r.top;
  posH.Caption := IntToStr(r.Height);
  posH.Enabled := True;
  edHint.Text := selectedControl.hint;
  edHint.Enabled := True;

  case SelectedControl.ctrlType of
    lwct_column:
    begin
      ComboBox_fields.Enabled := True;
      if assigned(selectedControl.def) then
      begin
        ComboBox_fields.Text := SelectedControl.def.col_name;
        ComboBox_kind.Enabled := True;
        //remplir_combo_kind(SelectedControl);
      end
      else
      begin
        Combobox_fields.Text := '';
        ComboBox_kind.Enabled := False;
        ComboBox_kind.items.Clear;
      end;
      Ed_caption.Enabled := False;
      Ed_caption.Text := '';
      SETaborder.Enabled := True;
      SETaborder.Value := selectedControl.taborder;
      SETaborder.Caption := IntToStr(selectedControl.taborder);
    end;
    lwct_label:
    begin
      Combobox_fields.Enabled := False;
      ComboBox_fields.Text := '';
      Ed_caption.Enabled := True;
      Ed_caption.Text := SelectedControl.Caption;
      ComboBox_kind.Enabled := False;
      ComboBox_kind.Items.Clear;
      SETaborder.Enabled := False;
      SETaborder.Clear;
    end;
  end;


end;

destructor TFCustomDP.Destroy;

begin
  Combobox_kind.items.Clear;
  FCustomDP := nil;
  inherited;
end;

end.
