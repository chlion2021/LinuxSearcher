unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ComCtrls,
  ExtCtrls, Menus, Buttons, FileCtrl, LCLType, LazFileUtils, LazUTF8, Process;

type
  TSearchMode = (smName, smContent, smSize, smTime, smExtension);
  
  TFileInfo = record
    FullPath: string;
    FileName: string;
    Size: Int64;
    Modified: TDateTime;
  end;
  
  TDiskPartition = record
    Device: string;
    MountPoint: string;
    FSType: string;
    TotalGB: Double;
    UsedGB: Double;
    FreeGB: Double;
    Percent: Double;
  end;

  { TForm1 }

  TForm1 = class(TForm)
    btnBrowsePath: TButton;
    btnBrowseTarget: TButton;
    btnClearResults: TButton;
    btnCopyAll: TButton;
    btnCopySelected: TButton;
    btnExportResults: TButton;
    btnInvertSelection: TButton;
    btnMoveAll: TButton;
    btnMoveSelected: TButton;
    btnSelectAll: TButton;
    btnStartSearch: TButton;
    btnStopSearch: TButton;
    cbFileExists: TComboBox;
    chkCaseSensitive: TCheckBox;
    chkRecursive: TCheckBox;
    chkRegex: TCheckBox;
    edtSearchPath: TEdit;
    edtTargetFolder: TEdit;
    gbDiskSelection: TGroupBox;
    gbFileOperations: TGroupBox;
    gbOpsStatus: TGroupBox;
    gbSearchControl: TGroupBox;
    gbSelection: TGroupBox;
    lblDiskStats: TLabel;
    lblExists: TLabel;
    lblResultCount: TLabel;
    lblSearchPath: TLabel;
    lblStatus: TLabel;
    lblTarget: TLabel;
    lvResults: TListView;
    mmOpsStatus: TMemo;
    pnlControls: TPanel;
    pnlDiskButtons: TPanel;
    pnlMain: TPanel;
    pnlModeButtons: TPanel;
    pnlOptions: TPanel;
    pnlParamContainer: TPanel;
    pnlResults: TPanel;
    pnlSearchParams: TPanel;
    pnlSearchPath: TPanel;
    pnlStatusBar: TPanel;
    pbFileOps: TProgressBar;
    pbSearch: TProgressBar;
    rbContent: TRadioButton;
    rbExtension: TRadioButton;
    rbName: TRadioButton;
    rbSize: TRadioButton;
    rbTime: TRadioButton;
    procedure btnBrowsePathClick(Sender: TObject);
    procedure btnBrowseTargetClick(Sender: TObject);
    procedure btnClearResultsClick(Sender: TObject);
    procedure btnCopyAllClick(Sender: TObject);
    procedure btnCopySelectedClick(Sender: TObject);
    procedure btnExportResultsClick(Sender: TObject);
    procedure btnInvertSelectionClick(Sender: TObject);
    procedure btnMoveAllClick(Sender: TObject);
    procedure btnMoveSelectedClick(Sender: TObject);
    procedure btnSelectAllClick(Sender: TObject);
    procedure btnStartSearchClick(Sender: TObject);
    procedure btnStopSearchClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure lvResultsClick(Sender: TObject);
    procedure lvResultsColumnClick(Sender: TObject; Column: TListColumn);
    procedure lvResultsCompare(Sender: TObject; Item1, Item2: TListItem;
      Data: Integer; var Compare: Integer);
    procedure lvResultsDblClick(Sender: TObject);
    procedure rbContentClick(Sender: TObject);
    procedure rbExtensionClick(Sender: TObject);
    procedure rbNameClick(Sender: TObject);
    procedure rbSizeClick(Sender: TObject);
    procedure rbTimeClick(Sender: TObject);
  private
    FSearchMode: TSearchMode;
    FStopSearch: Boolean;
    FDisplayedFiles: TStringList;
    FPartitions: array of TDiskPartition;
    FSortColumn: Integer;      // 当前排序的列索引
    FSortAscending: Boolean;   // 是否升序排序
    // 搜索参数控件
    edtSearchText: TEdit;
    edtFileFilter: TEdit;
    edtMinSize: TEdit;
    edtMaxSize: TEdit;
    cbMinUnit: TComboBox;
    cbMaxUnit: TComboBox;
    edtTimeValue: TEdit;
    cbTimeUnit: TComboBox;
    rbNewer: TRadioButton;
    rbOlder: TRadioButton;
    edtExtensions: TEdit;
    
    procedure SetupDiskButtons;
    procedure SetupSearchParams;
    procedure SetupNameParams;
    procedure SetupContentParams;
    procedure SetupSizeParams;
    procedure SetupTimeParams;
    procedure SetupExtensionParams;
    procedure ClearParamContainer;
    procedure UpdateStatus(const Msg: string);
    procedure AddResultToList(const FileInfo: TFileInfo);
    function FormatSize(SizeBytes: Int64): string;
    function ParseSize(SizeStr: string; UnitStr: string): Int64;
    function ParseSizeString(const SizeStr: string): Int64;  // 新添加的函数
    function GetSelectedFiles: TStringList;
    procedure CopyFiles(Files: TStringList; Operation: string);
    procedure MoveFiles(Files: TStringList; Operation: string);
    function SearchByName(const Path, Pattern: string; Recursive: Boolean): Integer;
    function SearchByContent(const Path, SearchText, FileFilter: string; Recursive: Boolean): Integer;
    function SearchBySize(const Path: string; MinSize, MaxSize: Int64; Recursive: Boolean): Integer;
    function SearchByTime(const Path: string; Days: Double; Recursive, Newer: Boolean): Integer;
    function SearchByExtension(const Path: string; Extensions: TStringList; Recursive: Boolean): Integer;
    function IsSpecialFilesystem(const Path: string): Boolean;
    function TryGetFileInfo(const Path: string; out FileInfo: TFileInfo): Boolean;
    procedure OpenFile(const FilePath: string);
    procedure OpenDirectory(const FilePath: string);
    procedure SearchTextEnter(Sender: TObject);
    procedure SearchTextExit(Sender: TObject);
    procedure DiskButtonClick(Sender: TObject);
    procedure MyCopyFile(const Source, Dest: string);
    procedure SortListView(ColumnIndex: Integer);
    procedure UpdateColumnHeaders;  // 新添加的函数
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }

constructor TForm1.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FDisplayedFiles := TStringList.Create;
  FDisplayedFiles.Sorted := True;
  FDisplayedFiles.Duplicates := dupIgnore;
  FSortColumn := -1;  // 初始未排序
  FSortAscending := True;
end;

destructor TForm1.Destroy;
begin
  FDisplayedFiles.Free;
  inherited Destroy;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  // 设置目标文件夹默认值
  edtTargetFolder.Text := GetEnvironmentVariable('HOME') + '/Desktop';
  
  // 设置搜索参数界面
  SetupSearchParams;
  
  // 设置硬盘分区按钮
  SetupDiskButtons;
  
  // 设置ListView支持排序
  lvResults.SortType := stData;
  lvResults.OnCompare := @lvResultsCompare;
  lvResults.OnColumnClick := @lvResultsColumnClick;
end;

// 解析大小字符串为字节数
function TForm1.ParseSizeString(const SizeStr: string): Int64;
var
  NumStr: string;
  UnitStr: string;
  Size: Double;
  I: Integer;
begin
  Result := 0;
  
  if Trim(SizeStr) = '' then Exit;
  
  // 提取数字部分和单位部分
  NumStr := '';
  UnitStr := '';
  
  for I := 1 to Length(SizeStr) do
  begin
    if SizeStr[I] in ['0'..'9', '.', ','] then
      NumStr := NumStr + SizeStr[I]
    else if SizeStr[I] <> ' ' then
      UnitStr := UnitStr + SizeStr[I];
  end;
  
  try
    if NumStr = '' then Exit;
    
    // 替换逗号为点
    NumStr := StringReplace(NumStr, ',', '.', [rfReplaceAll]);
    Size := StrToFloat(NumStr);
    
    if UnitStr = 'KB' then
      Result := Round(Size * 1024)
    else if UnitStr = 'MB' then
      Result := Round(Size * 1024 * 1024)
    else if UnitStr = 'GB' then
      Result := Round(Size * 1024 * 1024 * 1024)
    else if UnitStr = 'TB' then
      Result := Round(Size * 1024 * 1024 * 1024 * 1024)
    else  // B
      Result := Round(Size);
  except
    Result := 0;
  end;
end;

// 列点击事件处理
procedure TForm1.lvResultsColumnClick(Sender: TObject; Column: TListColumn);
begin
  if Column.Index > 0 then  // 第一列是复选框，不排序
  begin
    SortListView(Column.Index);
  end;
end;

// 排序ListView
procedure TForm1.SortListView(ColumnIndex: Integer);
begin
  if FSortColumn = ColumnIndex then
  begin
    // 同一列，切换排序方向
    FSortAscending := not FSortAscending;
  end
  else
  begin
    // 新列，默认升序
    FSortColumn := ColumnIndex;
    FSortAscending := True;
  end;
  
  // 更新列标题显示排序状态
  UpdateColumnHeaders;
  
  // 执行排序
  lvResults.AlphaSort;
end;

// 更新列标题显示排序状态
procedure TForm1.UpdateColumnHeaders;
var
  I: Integer;
  Col: TListColumn;
  Title: string;
begin
  for I := 0 to lvResults.Columns.Count - 1 do
  begin
    Col := lvResults.Columns[I];
    Title := Col.Caption;
    
    // 移除之前的排序标记
    if (Pos(' ↑', Title) > 0) or (Pos(' ↓', Title) > 0) then
      Title := Copy(Title, 1, Length(Title) - 2);
    
    // 添加新的排序标记
    if I = FSortColumn then
    begin
      if FSortAscending then
        Title := Title + ' ↑'
      else
        Title := Title + ' ↓';
    end;
    
    Col.Caption := Title;
  end;
end;

// 比较函数，用于排序
procedure TForm1.lvResultsCompare(Sender: TObject; Item1, Item2: TListItem;
  Data: Integer; var Compare: Integer);
var
  Str1, Str2: string;
  Size1, Size2: Int64;
  Date1, Date2: TDateTime;
begin
  Compare := 0;
  
  if FSortColumn < 0 then Exit;  // 没有指定排序列
  
  case FSortColumn of
    1: // 路径列
      begin
        Str1 := Item1.SubItems[0];  // 路径
        Str2 := Item2.SubItems[0];
        Compare := CompareText(Str1, Str2);
      end;
      
    2: // 文件名列
      begin
        Str1 := Item1.SubItems[1];  // 文件名
        Str2 := Item2.SubItems[1];
        Compare := CompareText(Str1, Str2);
      end;
      
    3: // 大小列
      begin
        Str1 := Item1.SubItems[2];  // 大小字符串
        Str2 := Item2.SubItems[2];
        
        // 解析大小字符串
        Size1 := ParseSizeString(Str1);
        Size2 := ParseSizeString(Str2);
        
        if Size1 < Size2 then
          Compare := -1
        else if Size1 > Size2 then
          Compare := 1
        else
          Compare := 0;
      end;
      
    4: // 修改时间列
      begin
        Str1 := Item1.SubItems[3];  // 时间字符串
        Str2 := Item2.SubItems[3];
        
        // 尝试解析日期时间
        try
          Date1 := StrToDateTime(Str1);
          Date2 := StrToDateTime(Str2);
          
          if Date1 < Date2 then
            Compare := -1
          else if Date1 > Date2 then
            Compare := 1
          else
            Compare := 0;
        except
          // 解析失败时按字符串比较
          Compare := CompareText(Str1, Str2);
        end;
      end;
  end;
  
  // 如果不是升序，反转比较结果
  if not FSortAscending then
    Compare := -Compare;
end;

procedure TForm1.DiskButtonClick(Sender: TObject);
var
  Index: Integer;
begin
  if Sender is TButton then
  begin
    Index := (Sender as TButton).Tag;
    if (Index >= 0) and (Index < Length(FPartitions)) then
    begin
      edtSearchPath.Text := FPartitions[Index].MountPoint;
      UpdateStatus('已选择分区: ' + FPartitions[Index].MountPoint);
    end;
  end;
end;

procedure TForm1.SetupDiskButtons;
var
  I: Integer;
  Btn: TButton;
  MountPoints: TStringList;
begin
  // 简单的分区检测
  MountPoints := TStringList.Create;
  try
    // 常见挂载点
    if DirectoryExists('/') then MountPoints.Add('/');
    if DirectoryExists('/home') then MountPoints.Add('/home');
    if DirectoryExists('/boot') then MountPoints.Add('/boot');
    if DirectoryExists('/var') then MountPoints.Add('/var');
    if DirectoryExists('/usr') then MountPoints.Add('/usr');
    if DirectoryExists('/tmp') then MountPoints.Add('/tmp');
    if DirectoryExists('/mnt') then MountPoints.Add('/mnt');
    if DirectoryExists('/media') then MountPoints.Add('/media');
    
    SetLength(FPartitions, MountPoints.Count);
    for I := 0 to MountPoints.Count - 1 do
    begin
      FPartitions[I].MountPoint := MountPoints[I];
      FPartitions[I].Device := '系统目录 (' + MountPoints[I] + ')';
      
      Btn := TButton.Create(pnlDiskButtons);
      Btn.Parent := pnlDiskButtons;
      Btn.Left := I * 120;
      Btn.Top := 0;
      Btn.Width := 115;
      
      if MountPoints[I] = '/' then
        Btn.Caption := '系统盘(/)'
      else
        Btn.Caption := ExtractFileName(MountPoints[I]);
        
      Btn.OnClick := @DiskButtonClick;
      Btn.Tag := I; // 保存分区索引
      Btn.Show;
    end;
    
    lblDiskStats.Caption := '检测到 ' + IntToStr(MountPoints.Count) + ' 个分区';
    
  finally
    MountPoints.Free;
  end;
end;

procedure TForm1.SetupSearchParams;
begin
  FSearchMode := smName;
  SetupNameParams;
end;

procedure TForm1.SetupNameParams;
begin
  ClearParamContainer;
  
  // 创建搜索内容标签和输入框
  with TLabel.Create(pnlParamContainer) do
  begin
    Parent := pnlParamContainer;
    Left := 0;
    Top := 5;
    Caption := '内容:';
  end;
  
  edtSearchText := TEdit.Create(pnlParamContainer);
  with edtSearchText do
  begin
    Parent := pnlParamContainer;
    Left := 40;
    Top := 2;
    Width := 400;
    Text := '示例: *.c, test*, [abc]*.txt';
    Font.Color := clGray;
    OnEnter := @SearchTextEnter;
    OnExit := @SearchTextExit;
  end;
  
  // 显示正则表达式选项
  chkRegex.Visible := True;
end;

procedure TForm1.SearchTextEnter(Sender: TObject);
begin
  if edtSearchText.Text = '示例: *.c, test*, [abc]*.txt' then
  begin
    edtSearchText.Text := '';
    edtSearchText.Font.Color := clBlack;
  end;
end;

procedure TForm1.SearchTextExit(Sender: TObject);
begin
  if Trim(edtSearchText.Text) = '' then
  begin
    edtSearchText.Text := '示例: *.c, test*, [abc]*.txt';
    edtSearchText.Font.Color := clGray;
  end;
end;

procedure TForm1.SetupContentParams;
begin
  ClearParamContainer;
  
  // 文本搜索
  with TLabel.Create(pnlParamContainer) do
  begin
    Parent := pnlParamContainer;
    Left := 0;
    Top := 5;
    Caption := '文本:';
  end;
  
  edtSearchText := TEdit.Create(pnlParamContainer);
  with edtSearchText do
  begin
    Parent := pnlParamContainer;
    Left := 40;
    Top := 2;
    Width := 120;
    Text := '';
  end;
  
  // 文件过滤
  with TLabel.Create(pnlParamContainer) do
  begin
    Parent := pnlParamContainer;
    Left := 170;
    Top := 5;
    Caption := '过滤:';
  end;
  
  edtFileFilter := TEdit.Create(pnlParamContainer);
  with edtFileFilter do
  begin
    Parent := pnlParamContainer;
    Left := 210;
    Top := 2;
    Width := 100;
    Text := '*';
  end;
  
  // 隐藏正则表达式选项
  chkRegex.Visible := False;
end;

procedure TForm1.SetupSizeParams;
begin
  ClearParamContainer;
  
  // 大小搜索
  with TLabel.Create(pnlParamContainer) do
  begin
    Parent := pnlParamContainer;
    Left := 0;
    Top := 5;
    Caption := '大小:';
  end;
  
  edtMinSize := TEdit.Create(pnlParamContainer);
  with edtMinSize do
  begin
    Parent := pnlParamContainer;
    Left := 40;
    Top := 2;
    Width := 50;
    Text := '';
  end;
  
  cbMinUnit := TComboBox.Create(pnlParamContainer);
  with cbMinUnit do
  begin
    Parent := pnlParamContainer;
    Left := 95;
    Top := 2;
    Width := 50;
    Items.Add('B');
    Items.Add('KB');
    Items.Add('MB');
    Items.Add('GB');
    ItemIndex := 1; // KB
    Style := csDropDownList;
  end;
  
  with TLabel.Create(pnlParamContainer) do
  begin
    Parent := pnlParamContainer;
    Left := 150;
    Top := 5;
    Caption := '到';
  end;
  
  edtMaxSize := TEdit.Create(pnlParamContainer);
  with edtMaxSize do
  begin
    Parent := pnlParamContainer;
    Left := 170;
    Top := 2;
    Width := 50;
    Text := '';
  end;
  
  cbMaxUnit := TComboBox.Create(pnlParamContainer);
  with cbMaxUnit do
  begin
    Parent := pnlParamContainer;
    Left := 225;
    Top := 2;
    Width := 50;
    Items.Add('B');
    Items.Add('KB');
    Items.Add('MB');
    Items.Add('GB');
    ItemIndex := 2; // MB
    Style := csDropDownList;
  end;
  
  // 隐藏正则表达式选项
  chkRegex.Visible := False;
end;

procedure TForm1.SetupTimeParams;
begin
  ClearParamContainer;
  
  // 时间搜索
  with TLabel.Create(pnlParamContainer) do
  begin
    Parent := pnlParamContainer;
    Left := 0;
    Top := 5;
    Caption := '时间:';
  end;
  
  edtTimeValue := TEdit.Create(pnlParamContainer);
  with edtTimeValue do
  begin
    Parent := pnlParamContainer;
    Left := 40;
    Top := 2;
    Width := 40;
    Text := '7';
  end;
  
  cbTimeUnit := TComboBox.Create(pnlParamContainer);
  with cbTimeUnit do
  begin
    Parent := pnlParamContainer;
    Left := 85;
    Top := 2;
    Width := 50;
    Items.Add('小时');
    Items.Add('天');
    Items.Add('周');
    ItemIndex := 1; // 天
    Style := csDropDownList;
  end;
  
  with TLabel.Create(pnlParamContainer) do
  begin
    Parent := pnlParamContainer;
    Left := 140;
    Top := 5;
    Caption := '内';
  end;
  
  // 时间方向
  rbNewer := TRadioButton.Create(pnlParamContainer);
  with rbNewer do
  begin
    Parent := pnlParamContainer;
    Left := 160;
    Top := 4;
    Width := 30;
    Caption := '新';
    Checked := True;
  end;
  
  rbOlder := TRadioButton.Create(pnlParamContainer);
  with rbOlder do
  begin
    Parent := pnlParamContainer;
    Left := 195;
    Top := 4;
    Width := 30;
    Caption := '旧';
  end;
  
  // 隐藏正则表达式选项
  chkRegex.Visible := False;
end;

procedure TForm1.SetupExtensionParams;
begin
  ClearParamContainer;
  
  // 扩展名搜索
  with TLabel.Create(pnlParamContainer) do
  begin
    Parent := pnlParamContainer;
    Left := 0;
    Top := 5;
    Caption := '扩展名:';
  end;
  
  edtExtensions := TEdit.Create(pnlParamContainer);
  with edtExtensions do
  begin
    Parent := pnlParamContainer;
    Left := 55;
    Top := 2;
    Width := 150;
    Text := '.c .txt .md';
  end;
  
  // 隐藏正则表达式选项
  chkRegex.Visible := False;
end;

procedure TForm1.ClearParamContainer;
var
  I: Integer;
begin
  // 清除容器中的所有控件
  for I := pnlParamContainer.ControlCount - 1 downto 0 do
    pnlParamContainer.Controls[I].Free;
end;

procedure TForm1.rbNameClick(Sender: TObject);
begin
  FSearchMode := smName;
  SetupNameParams;
end;

procedure TForm1.rbContentClick(Sender: TObject);
begin
  FSearchMode := smContent;
  SetupContentParams;
end;

procedure TForm1.rbSizeClick(Sender: TObject);
begin
  FSearchMode := smSize;
  SetupSizeParams;
end;

procedure TForm1.rbTimeClick(Sender: TObject);
begin
  FSearchMode := smTime;
  SetupTimeParams;
end;

procedure TForm1.rbExtensionClick(Sender: TObject);
begin
  FSearchMode := smExtension;
  SetupExtensionParams;
end;

procedure TForm1.UpdateStatus(const Msg: string);
begin
  lblStatus.Caption := Msg;
  Application.ProcessMessages;
end;

function TForm1.FormatSize(SizeBytes: Int64): string;
const
  Units: array[0..4] of string = ('B', 'KB', 'MB', 'GB', 'TB');
var
  I: Integer;
  Size: Double;
begin
  if SizeBytes < 0 then
    Result := 'N/A'
  else if SizeBytes = 0 then
    Result := '0 B'
  else
  begin
    Size := SizeBytes;
    I := 0;
    while (Size >= 1024) and (I < High(Units)) do
    begin
      Size := Size / 1024;
      Inc(I);
    end;
    Result := FormatFloat('0.0', Size) + ' ' + Units[I];
  end;
end;

function TForm1.ParseSize(SizeStr: string; UnitStr: string): Int64;
var
  Size: Double;
begin
  Result := 0;
  if Trim(SizeStr) = '' then Exit;
  
  try
    Size := StrToFloat(SizeStr);
    
    if UnitStr = 'KB' then
      Result := Round(Size * 1024)
    else if UnitStr = 'MB' then
      Result := Round(Size * 1024 * 1024)
    else if UnitStr = 'GB' then
      Result := Round(Size * 1024 * 1024 * 1024)
    else // B
      Result := Round(Size);
  except
    Result := 0;
  end;
end;

procedure TForm1.AddResultToList(const FileInfo: TFileInfo);
var
  ListItem: TListItem;
begin
  if FDisplayedFiles.IndexOf(FileInfo.FullPath) >= 0 then
    Exit; // 已显示的文件，跳过
    
  FDisplayedFiles.Add(FileInfo.FullPath);
  
  ListItem := lvResults.Items.Add;
  ListItem.Caption := ''; // 复选框列
  ListItem.Checked := False;
  ListItem.SubItems.Add(FileInfo.FullPath);
  ListItem.SubItems.Add(FileInfo.FileName);
  ListItem.SubItems.Add(FormatSize(FileInfo.Size));
  ListItem.SubItems.Add(DateTimeToStr(FileInfo.Modified));
  
  lblResultCount.Caption := '搜索结果: ' + IntToStr(lvResults.Items.Count) + ' 个文件';
  Application.ProcessMessages;
end;

function TForm1.IsSpecialFilesystem(const Path: string): Boolean;
begin
  Result := (Pos('/proc', Path) = 1) or
            (Pos('/sys', Path) = 1) or
            (Pos('/dev', Path) = 1) or
            (Pos('/run', Path) = 1);
end;

function TForm1.TryGetFileInfo(const Path: string; out FileInfo: TFileInfo): Boolean;
var
  FileAgeResult: LongInt;
  F: File;
  Size: Int64;
begin
  // 初始化 FileInfo
  FileInfo.FullPath := Path;
  FileInfo.FileName := ExtractFileName(Path);
  FileInfo.Size := 0;
  FileInfo.Modified := Now;
  
  Result := False;
  
  // 检查特殊文件系统
  if IsSpecialFilesystem(Path) then
  begin
    Result := True; // 对于特殊文件系统，返回True但使用默认值
    Exit;
  end;
  
  try
    // 检查文件是否存在
    if FileExists(Path) then
    begin
      // 获取文件大小
      try
        AssignFile(F, Path);
        try
          Reset(F, 1);
          Size := FileSize(F);
          FileInfo.Size := Size;
        finally
          CloseFile(F);
        end;
      except
        FileInfo.Size := 0;
      end;
      
      // 获取文件修改时间
      FileAgeResult := FileAge(Path);
      if FileAgeResult <> -1 then
        FileInfo.Modified := FileDateToDateTime(FileAgeResult)
      else
        FileInfo.Modified := Now;
        
      Result := True;
    end;
  except
    // 无法访问的文件，返回默认值但Result为True
    Result := True;
  end;
end;

function TForm1.SearchByName(const Path, Pattern: string; Recursive: Boolean): Integer;
var
  SearchRec: TSearchRec;
  FileInfo: TFileInfo;
  SubDir: string;
  Matched: Boolean;
  FileName: string;
  SearchPattern: string;
begin
  Result := 0;
  
  if not DirectoryExists(Path) then
    Exit;
    
  // 检查是否在特殊文件系统中
  if IsSpecialFilesystem(Path) then
  begin
    UpdateStatus('跳过特殊目录: ' + Path);
    Exit;
  end;
  
  if FindFirst(IncludeTrailingPathDelimiter(Path) + '*', faAnyFile, SearchRec) = 0 then
  begin
    repeat
      if FStopSearch then Break;
      
      // 跳过特殊目录
      if (SearchRec.Name = '.') or (SearchRec.Name = '..') then
        Continue;
        
      FileName := SearchRec.Name;
      SubDir := IncludeTrailingPathDelimiter(Path) + FileName;
      
      // 检查是否是特殊文件系统
      if IsSpecialFilesystem(SubDir) then
        Continue;
      
      if (SearchRec.Attr and faDirectory) = faDirectory then
      begin
        // 如果是目录且需要递归搜索
        if Recursive then
          Result := Result + SearchByName(SubDir, Pattern, Recursive);
      end
      else
      begin
        // 匹配文件名
        Matched := False;
        
        if chkCaseSensitive.Checked then
        begin
          SearchPattern := Pattern;
          FileName := SearchRec.Name;
        end
        else
        begin
          SearchPattern := LowerCase(Pattern);
          FileName := LowerCase(SearchRec.Name);
        end;
        
        if chkRegex.Checked then
        begin
          // 正则表达式匹配（简化版）
          Matched := Pos(SearchPattern, FileName) > 0;
        end
        else
        begin
          // 通配符匹配（简化版）
          if (Pos('*', SearchPattern) > 0) or (Pos('?', SearchPattern) > 0) then
          begin
            // 简单的通配符匹配
            if SearchPattern = '*' then
              Matched := True
            else if (Pos('*', SearchPattern) = 1) and (Pos('*', SearchPattern) = Length(SearchPattern)) then
            begin
              // *text* 模式
              Matched := Pos(Copy(SearchPattern, 2, Length(SearchPattern) - 2), FileName) > 0;
            end
            else if Pos('*', SearchPattern) = Length(SearchPattern) then
            begin
              // text* 模式
              Matched := Pos(Copy(SearchPattern, 1, Length(SearchPattern) - 1), FileName) = 1;
            end;
          end
          else
          begin
            // 简单包含匹配
            Matched := Pos(SearchPattern, FileName) > 0;
          end;
        end;
        
        if Matched then
        begin
          if TryGetFileInfo(SubDir, FileInfo) then
          begin
            AddResultToList(FileInfo);
            Inc(Result);
            UpdateStatus('找到: ' + FileInfo.FileName);
          end;
        end;
      end;
      
      Application.ProcessMessages;
      
    until FindNext(SearchRec) <> 0;
    FindClose(SearchRec);
  end;
end;

function TForm1.SearchByContent(const Path, SearchText, FileFilter: string; Recursive: Boolean): Integer;
var
  SearchRec: TSearchRec;
  FileInfo: TFileInfo;
  SubDir: string;
  FileContent: TStringList;
  Found: Boolean;
begin
  Result := 0;
  
  if not DirectoryExists(Path) then
    Exit;
    
  if IsSpecialFilesystem(Path) then
  begin
    UpdateStatus('跳过特殊目录: ' + Path);
    Exit;
  end;
  
  if FindFirst(IncludeTrailingPathDelimiter(Path) + '*', faAnyFile, SearchRec) = 0 then
  begin
    repeat
      if FStopSearch then Break;
      
      if (SearchRec.Name = '.') or (SearchRec.Name = '..') then
        Continue;
        
      SubDir := IncludeTrailingPathDelimiter(Path) + SearchRec.Name;
      
      if IsSpecialFilesystem(SubDir) then
        Continue;
      
      if (SearchRec.Attr and faDirectory) = faDirectory then
      begin
        if Recursive then
          Result := Result + SearchByContent(SubDir, SearchText, FileFilter, Recursive);
      end
      else
      begin
        // 文件过滤
        if (FileFilter <> '*') then
        begin
          if ExtractFileExt(SearchRec.Name) <> FileFilter then
            Continue;
        end;
        
        // 尝试读取文件内容
        try
          FileContent := TStringList.Create;
          try
            FileContent.LoadFromFile(SubDir);
            
            Found := False;
            if chkCaseSensitive.Checked then
              Found := Pos(SearchText, FileContent.Text) > 0
            else
              Found := Pos(LowerCase(SearchText), LowerCase(FileContent.Text)) > 0;
              
            if Found then
            begin
              if TryGetFileInfo(SubDir, FileInfo) then
              begin
                AddResultToList(FileInfo);
                Inc(Result);
                UpdateStatus('找到: ' + FileInfo.FileName);
              end;
            end;
          finally
            FileContent.Free;
          end;
        except
          // 无法读取文件，跳过
        end;
      end;
      
      Application.ProcessMessages;
      
    until FindNext(SearchRec) <> 0;
    FindClose(SearchRec);
  end;
end;

function TForm1.SearchBySize(const Path: string; MinSize, MaxSize: Int64; Recursive: Boolean): Integer;
var
  SearchRec: TSearchRec;
  FileInfo: TFileInfo;
  SubDir: string;
  SizeMatch: Boolean;
begin
  Result := 0;
  
  if not DirectoryExists(Path) then
    Exit;
    
  if IsSpecialFilesystem(Path) then
  begin
    UpdateStatus('跳过特殊目录: ' + Path);
    Exit;
  end;
  
  if FindFirst(IncludeTrailingPathDelimiter(Path) + '*', faAnyFile, SearchRec) = 0 then
  begin
    repeat
      if FStopSearch then Break;
      
      if (SearchRec.Name = '.') or (SearchRec.Name = '..') then
        Continue;
        
      SubDir := IncludeTrailingPathDelimiter(Path) + SearchRec.Name;
      
      if IsSpecialFilesystem(SubDir) then
        Continue;
      
      if (SearchRec.Attr and faDirectory) = faDirectory then
      begin
        if Recursive then
          Result := Result + SearchBySize(SubDir, MinSize, MaxSize, Recursive);
      end
      else
      begin
        if TryGetFileInfo(SubDir, FileInfo) then
        begin
          SizeMatch := True;
          
          if (MinSize > 0) and (FileInfo.Size < MinSize) then
            SizeMatch := False;
            
          if (MaxSize > 0) and (FileInfo.Size > MaxSize) then
            SizeMatch := False;
            
          if SizeMatch then
          begin
            AddResultToList(FileInfo);
            Inc(Result);
            UpdateStatus('找到: ' + FileInfo.FileName);
          end;
        end;
      end;
      
      Application.ProcessMessages;
      
    until FindNext(SearchRec) <> 0;
    FindClose(SearchRec);
  end;
end;

function TForm1.SearchByTime(const Path: string; Days: Double; Recursive, Newer: Boolean): Integer;
var
  SearchRec: TSearchRec;
  FileInfo: TFileInfo;
  SubDir: string;
  Cutoff: TDateTime;
  TimeMatch: Boolean;
begin
  Result := 0;
  
  if not DirectoryExists(Path) then
    Exit;
    
  if IsSpecialFilesystem(Path) then
  begin
    UpdateStatus('跳过特殊目录: ' + Path);
    Exit;
  end;
  
  Cutoff := Now - Days;
  
  if FindFirst(IncludeTrailingPathDelimiter(Path) + '*', faAnyFile, SearchRec) = 0 then
  begin
    repeat
      if FStopSearch then Break;
      
      if (SearchRec.Name = '.') or (SearchRec.Name = '..') then
        Continue;
        
      SubDir := IncludeTrailingPathDelimiter(Path) + SearchRec.Name;
      
      if IsSpecialFilesystem(SubDir) then
        Continue;
      
      if (SearchRec.Attr and faDirectory) = faDirectory then
      begin
        if Recursive then
          Result := Result + SearchByTime(SubDir, Days, Recursive, Newer);
      end
      else
      begin
        if TryGetFileInfo(SubDir, FileInfo) then
        begin
          if Newer then
            TimeMatch := FileInfo.Modified > Cutoff
          else
            TimeMatch := FileInfo.Modified < Cutoff;
            
          if TimeMatch then
          begin
            AddResultToList(FileInfo);
            Inc(Result);
            UpdateStatus('找到: ' + FileInfo.FileName);
          end;
        end;
      end;
      
      Application.ProcessMessages;
      
    until FindNext(SearchRec) <> 0;
    FindClose(SearchRec);
  end;
end;

function TForm1.SearchByExtension(const Path: string; Extensions: TStringList; Recursive: Boolean): Integer;
var
  SearchRec: TSearchRec;
  FileInfo: TFileInfo;
  SubDir: string;
  FileExt: string;
  I: Integer;
  ExtMatched: Boolean;
begin
  Result := 0;
  
  if not DirectoryExists(Path) then
    Exit;
    
  if IsSpecialFilesystem(Path) then
  begin
    UpdateStatus('跳过特殊目录: ' + Path);
    Exit;
  end;
  
  if FindFirst(IncludeTrailingPathDelimiter(Path) + '*', faAnyFile, SearchRec) = 0 then
  begin
    repeat
      if FStopSearch then Break;
      
      if (SearchRec.Name = '.') or (SearchRec.Name = '..') then
        Continue;
        
      SubDir := IncludeTrailingPathDelimiter(Path) + SearchRec.Name;
      
      if IsSpecialFilesystem(SubDir) then
        Continue;
      
      if (SearchRec.Attr and faDirectory) = faDirectory then
      begin
        if Recursive then
          Result := Result + SearchByExtension(SubDir, Extensions, Recursive);
      end
      else
      begin
        FileExt := LowerCase(ExtractFileExt(SearchRec.Name));
        
        ExtMatched := False;
        for I := 0 to Extensions.Count - 1 do
        begin
          if not Extensions[I].StartsWith('.') then
            Extensions[I] := '.' + Extensions[I];
            
          if FileExt = LowerCase(Extensions[I]) then
          begin
            ExtMatched := True;
            Break;
          end;
        end;
        
        if ExtMatched then
        begin
          if TryGetFileInfo(SubDir, FileInfo) then
          begin
            AddResultToList(FileInfo);
            Inc(Result);
            UpdateStatus('找到: ' + FileInfo.FileName);
          end;
        end;
      end;
      
      Application.ProcessMessages;
      
    until FindNext(SearchRec) <> 0;
    FindClose(SearchRec);
  end;
end;

procedure TForm1.btnStartSearchClick(Sender: TObject);
var
  Path: string;
  FoundCount: Integer;
  MinSize, MaxSize: Int64;
  Days: Double;
  Extensions: TStringList;
  SearchText: string;
  FileFilter: string;
begin
  // 检查路径
  Path := edtSearchPath.Text;
  if not DirectoryExists(Path) then
  begin
    MessageDlg('错误', '路径不存在: ' + Path, mtError, [mbOK], 0);
    Exit;
  end;
  
  // 确认搜索整个分区
  if Path = '/' then
  begin
    if MessageDlg('确认搜索', 
       '即将搜索整个分区: /' + #13#10 +
       '这可能会搜索大量文件，耗时较长。' + #13#10#13#10 +
       '是否继续？', 
       mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
      Exit;
  end;
  
  // 清除旧结果
  lvResults.Items.Clear;
  FDisplayedFiles.Clear;
  lblResultCount.Caption := '搜索结果: 0 个文件';
  mmOpsStatus.Lines.Clear;
  
  // 重置排序状态
  FSortColumn := -1;
  FSortAscending := True;
  
  // 重置列标题（移除排序箭头）
  UpdateColumnHeaders;
  
  // 重置搜索状态
  FStopSearch := False;
  btnStartSearch.Enabled := False;
  btnStopSearch.Enabled := True;
  pbSearch.Position := 0;
  pbSearch.Max := 100;
  
  UpdateStatus('正在搜索...');
  
  try
    // 根据搜索模式执行搜索
    case FSearchMode of
      smName:
        begin
          SearchText := edtSearchText.Text;
          if SearchText = '示例: *.c, test*, [abc]*.txt' then
            SearchText := '';
            
          if Trim(SearchText) = '' then
          begin
            MessageDlg('错误', '请输入搜索内容', mtError, [mbOK], 0);
            Exit;
          end;
          
          FoundCount := SearchByName(Path, SearchText, chkRecursive.Checked);
        end;
        
      smContent:
        begin
          SearchText := edtSearchText.Text;
          if Assigned(edtFileFilter) then
            FileFilter := edtFileFilter.Text
          else
            FileFilter := '*';
            
          if Trim(SearchText) = '' then
          begin
            MessageDlg('错误', '请输入搜索文本', mtError, [mbOK], 0);
            Exit;
          end;
          
          FoundCount := SearchByContent(Path, SearchText, FileFilter, chkRecursive.Checked);
        end;
        
      smSize:
        begin
          MinSize := ParseSize(edtMinSize.Text, cbMinUnit.Text);
          MaxSize := ParseSize(edtMaxSize.Text, cbMaxUnit.Text);
          
          FoundCount := SearchBySize(Path, MinSize, MaxSize, chkRecursive.Checked);
        end;
        
      smTime:
        begin
          try
            Days := StrToFloat(edtTimeValue.Text);
            if cbTimeUnit.Text = '小时' then
              Days := Days / 24
            else if cbTimeUnit.Text = '周' then
              Days := Days * 7;
              
            FoundCount := SearchByTime(Path, Days, chkRecursive.Checked, rbNewer.Checked);
          except
            MessageDlg('错误', '请输入有效的时间值', mtError, [mbOK], 0);
            Exit;
          end;
        end;
        
      smExtension:
        begin
          Extensions := TStringList.Create;
          try
            Extensions.Delimiter := ' ';
            Extensions.DelimitedText := edtExtensions.Text;
            
            if Extensions.Count = 0 then
            begin
              MessageDlg('错误', '请输入文件扩展名', mtError, [mbOK], 0);
              Exit;
            end;
            
            FoundCount := SearchByExtension(Path, Extensions, chkRecursive.Checked);
          finally
            Extensions.Free;
          end;
        end;
    end;
    
    // 搜索完成
    if FStopSearch then
      UpdateStatus('搜索已停止，找到 ' + IntToStr(FoundCount) + ' 个文件')
    else
      UpdateStatus('搜索完成，找到 ' + IntToStr(FoundCount) + ' 个文件');
      
    if (FoundCount = 0) and (not FStopSearch) then
      MessageDlg('提示', '未找到匹配的文件', mtInformation, [mbOK], 0);
      
  finally
    btnStartSearch.Enabled := True;
    btnStopSearch.Enabled := False;
    pbSearch.Position := 100;
  end;
end;

procedure TForm1.btnStopSearchClick(Sender: TObject);
begin
  FStopSearch := True;
  UpdateStatus('正在停止搜索...');
end;

procedure TForm1.btnClearResultsClick(Sender: TObject);
begin
  lvResults.Items.Clear;
  FDisplayedFiles.Clear;
  lblResultCount.Caption := '搜索结果: 0 个文件';
  mmOpsStatus.Lines.Clear;
  
  // 重置排序状态
  FSortColumn := -1;
  FSortAscending := True;
  UpdateColumnHeaders;
  
  UpdateStatus('就绪');
end;

procedure TForm1.btnExportResultsClick(Sender: TObject);
var
  SaveDialog: TSaveDialog;
  I: Integer;
  ListItem: TListItem;
  FileContent: TStringList;
begin
  if lvResults.Items.Count = 0 then
  begin
    MessageDlg('警告', '没有结果可以导出', mtWarning, [mbOK], 0);
    Exit;
  end;
  
  SaveDialog := TSaveDialog.Create(nil);
  try
    SaveDialog.Filter := '文本文件|*.txt|CSV文件|*.csv|所有文件|*.*';
    SaveDialog.DefaultExt := 'txt';
    SaveDialog.FileName := 'search_results.txt';
    SaveDialog.Options := [ofOverwritePrompt, ofHideReadOnly, ofEnableSizing];
    
    if SaveDialog.Execute then
    begin
      FileContent := TStringList.Create;
      try
        FileContent.Add('搜索时间: ' + DateTimeToStr(Now));
        FileContent.Add('搜索路径: ' + edtSearchPath.Text);
        
        // 获取搜索模式
        if rbName.Checked then
          FileContent.Add('搜索模式: 文件名')
        else if rbContent.Checked then
          FileContent.Add('搜索模式: 内容')
        else if rbSize.Checked then
          FileContent.Add('搜索模式: 大小')
        else if rbTime.Checked then
          FileContent.Add('搜索模式: 时间')
        else if rbExtension.Checked then
          FileContent.Add('搜索模式: 类型');
          
        FileContent.Add('找到文件: ' + IntToStr(lvResults.Items.Count) + ' 个');
        FileContent.Add(StringOfChar('-', 80));
        FileContent.Add('');
        
        for I := 0 to lvResults.Items.Count - 1 do
        begin
          ListItem := lvResults.Items[I];
          if ListItem.SubItems.Count >= 4 then
          begin
            FileContent.Add('文件: ' + ListItem.SubItems[1]); // 文件名
            FileContent.Add('路径: ' + ListItem.SubItems[0]); // 路径
            FileContent.Add('大小: ' + ListItem.SubItems[2]); // 大小
            FileContent.Add('修改时间: ' + ListItem.SubItems[3]); // 修改时间
            FileContent.Add(StringOfChar('-', 40));
          end;
        end;
        
        FileContent.SaveToFile(SaveDialog.FileName);
        UpdateStatus('结果已导出到: ' + SaveDialog.FileName);
        MessageDlg('成功', '结果已导出到: ' + SaveDialog.FileName, mtInformation, [mbOK], 0);
        
      finally
        FileContent.Free;
      end;
    end;
  finally
    SaveDialog.Free;
  end;
end;

procedure TForm1.btnBrowsePathClick(Sender: TObject);
var
  Dir: string;
begin
  Dir := edtSearchPath.Text;
  if SelectDirectory('选择搜索路径', '', Dir) then
    edtSearchPath.Text := Dir;
end;

procedure TForm1.btnBrowseTargetClick(Sender: TObject);
var
  Dir: string;
begin
  Dir := edtTargetFolder.Text;
  if SelectDirectory('选择目标文件夹', '', Dir) then
    edtTargetFolder.Text := Dir;
end;

function TForm1.GetSelectedFiles: TStringList;
var
  I: Integer;
  ListItem: TListItem;
begin
  Result := TStringList.Create;
  for I := 0 to lvResults.Items.Count - 1 do
  begin
    ListItem := lvResults.Items[I];
    if ListItem.Checked then
      Result.Add(ListItem.SubItems[0]); // 完整路径
  end;
end;

// 自定义的CopyFile函数
procedure TForm1.MyCopyFile(const Source, Dest: string);
var
  SourceStream, DestStream: TFileStream;
begin
  SourceStream := TFileStream.Create(Source, fmOpenRead);
  try
    DestStream := TFileStream.Create(Dest, fmCreate);
    try
      DestStream.CopyFrom(SourceStream, SourceStream.Size);
    finally
      DestStream.Free;
    end;
  finally
    SourceStream.Free;
  end;
end;

procedure TForm1.CopyFiles(Files: TStringList; Operation: string);
var
  I, J: Integer;
  SourcePath, TargetPath, FileName, BaseName, Ext: string;
  Counter: Integer;
  SuccessCount, SkipCount, ErrorCount: Integer;
  HandleType: string;
begin
  if Files.Count = 0 then
  begin
    MessageDlg('警告', '请先选择要操作的文件', mtWarning, [mbOK], 0);
    Files.Free;
    Exit;
  end;
  
  TargetPath := edtTargetFolder.Text;
  if not DirectoryExists(TargetPath) then
  begin
    MessageDlg('错误', '目标文件夹不存在或无效', mtError, [mbOK], 0);
    Files.Free;
    Exit;
  end;
  
  if MessageDlg('确认', 
     '确定要' + Operation + ' ' + IntToStr(Files.Count) + ' 个文件到:' + #13#10 +
     TargetPath + ' 吗？', 
     mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
  begin
    Files.Free;
    Exit;
  end;
  
  SuccessCount := 0;
  SkipCount := 0;
  ErrorCount := 0;
  
  pbFileOps.Position := 0;
  pbFileOps.Max := Files.Count;
  mmOpsStatus.Lines.Clear;
  
  for I := 0 to Files.Count - 1 do
  begin
    SourcePath := Files[I];
    FileName := ExtractFileName(SourcePath);
    TargetPath := IncludeTrailingPathDelimiter(edtTargetFolder.Text) + FileName;
    
    if not FileExists(SourcePath) then
    begin
      mmOpsStatus.Lines.Add(Format('[%s] 错误: 源文件不存在: %s', 
        [FormatDateTime('hh:nn:ss', Now), SourcePath]));
      Inc(ErrorCount);
      Continue;
    end;
    
    if FileExists(TargetPath) then
    begin
      HandleType := cbFileExists.Text;
      
      if HandleType = '跳过' then
      begin
        mmOpsStatus.Lines.Add(Format('[%s] 跳过: 文件已存在: %s', 
          [FormatDateTime('hh:nn:ss', Now), FileName]));
        Inc(SkipCount);
        Continue;
      end
      else if HandleType = '重命名' then
      begin
        BaseName := ChangeFileExt(FileName, '');
        Ext := ExtractFileExt(FileName);
        Counter := 1;
        
        while FileExists(TargetPath) do
        begin
          FileName := BaseName + '_' + IntToStr(Counter) + Ext;
          TargetPath := IncludeTrailingPathDelimiter(edtTargetFolder.Text) + FileName;
          Inc(Counter);
        end;
        
        mmOpsStatus.Lines.Add(Format('[%s] 重命名为: %s', 
          [FormatDateTime('hh:nn:ss', Now), FileName]));
      end;
      // 如果选择覆盖，直接继续
    end;
    
    try
      if Operation = '复制' then
      begin
        // 使用自定义的CopyFile函数
        MyCopyFile(SourcePath, TargetPath);
        mmOpsStatus.Lines.Add(Format('[%s] 复制: %s', 
          [FormatDateTime('hh:nn:ss', Now), ExtractFileName(TargetPath)]));
        Inc(SuccessCount);
      end
      else if Operation = '剪切' then
      begin
        // 先复制然后删除源文件
        MyCopyFile(SourcePath, TargetPath);
        if DeleteFile(SourcePath) then
        begin
          mmOpsStatus.Lines.Add(Format('[%s] 剪切: %s', 
            [FormatDateTime('hh:nn:ss', Now), ExtractFileName(TargetPath)]));
          Inc(SuccessCount);
          
          // 从列表中移除
          for J := lvResults.Items.Count - 1 downto 0 do
          begin
            if lvResults.Items[J].SubItems[0] = SourcePath then
            begin
              lvResults.Items.Delete(J);
              Break;
            end;
          end;
        end
        else
        begin
          mmOpsStatus.Lines.Add(Format('[%s] 错误: 剪切失败: %s', 
            [FormatDateTime('hh:nn:ss', Now), FileName]));
          Inc(ErrorCount);
        end;
      end;
    except
      on E: Exception do
      begin
        mmOpsStatus.Lines.Add(Format('[%s] 错误: 操作失败: %s - %s', 
          [FormatDateTime('hh:nn:ss', Now), FileName, E.Message]));
        Inc(ErrorCount);
      end;
    end;
    
    pbFileOps.Position := I + 1;
    Application.ProcessMessages;
  end;
  
  pbFileOps.Position := Files.Count;
  
  mmOpsStatus.Lines.Add('');
  mmOpsStatus.Lines.Add(Operation + '操作完成！');
  mmOpsStatus.Lines.Add('总计: ' + IntToStr(Files.Count) + ' 个文件');
  mmOpsStatus.Lines.Add('成功: ' + IntToStr(SuccessCount) + ' 个');
  mmOpsStatus.Lines.Add('跳过: ' + IntToStr(SkipCount) + ' 个');
  mmOpsStatus.Lines.Add('失败: ' + IntToStr(ErrorCount) + ' 个');
  
  lblResultCount.Caption := '搜索结果: ' + IntToStr(lvResults.Items.Count) + ' 个文件';
  UpdateStatus(Operation + '操作完成: ' + IntToStr(SuccessCount) + '/' + IntToStr(Files.Count) + ' 成功');
  
  if ErrorCount = 0 then
    MessageDlg('完成', Operation + '操作完成！' + #13#10 + '成功处理 ' + IntToStr(SuccessCount) + ' 个文件。', 
      mtInformation, [mbOK], 0)
  else
    MessageDlg('完成', 
      Operation + '操作完成！' + #13#10 +
      '成功: ' + IntToStr(SuccessCount) + #13#10 +
      '失败: ' + IntToStr(ErrorCount) + #13#10 +
      '跳过: ' + IntToStr(SkipCount), 
      mtWarning, [mbOK], 0);
      
  Files.Free;
end;

procedure TForm1.MoveFiles(Files: TStringList; Operation: string);
begin
  if Operation = '剪切' then
  begin
    if MessageDlg('确认', 
       '确定要剪切 ' + IntToStr(Files.Count) + ' 个文件吗？' + #13#10 +
       '注意: 剪切操作会删除源文件！', 
       mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
    begin
      Files.Free;
      Exit;
    end;
  end;
  
  CopyFiles(Files, Operation);
end;

procedure TForm1.btnCopySelectedClick(Sender: TObject);
var
  Files: TStringList;
begin
  Files := GetSelectedFiles;
  CopyFiles(Files, '复制');
end;

procedure TForm1.btnMoveSelectedClick(Sender: TObject);
var
  Files: TStringList;
begin
  Files := GetSelectedFiles;
  MoveFiles(Files, '剪切');
end;

procedure TForm1.btnCopyAllClick(Sender: TObject);
var
  Files: TStringList;
  I: Integer;
begin
  Files := TStringList.Create;
  for I := 0 to lvResults.Items.Count - 1 do
    Files.Add(lvResults.Items[I].SubItems[0]);
    
  CopyFiles(Files, '复制');
end;

procedure TForm1.btnMoveAllClick(Sender: TObject);
var
  Files: TStringList;
  I: Integer;
begin
  Files := TStringList.Create;
  for I := 0 to lvResults.Items.Count - 1 do
    Files.Add(lvResults.Items[I].SubItems[0]);
    
  MoveFiles(Files, '剪切');
end;

procedure TForm1.btnSelectAllClick(Sender: TObject);
var
  I: Integer;
begin
  for I := 0 to lvResults.Items.Count - 1 do
    lvResults.Items[I].Checked := True;
end;

procedure TForm1.btnInvertSelectionClick(Sender: TObject);
var
  I: Integer;
begin
  for I := 0 to lvResults.Items.Count - 1 do
    lvResults.Items[I].Checked := not lvResults.Items[I].Checked;
end;

procedure TForm1.lvResultsClick(Sender: TObject);
begin
  if (lvResults.Selected <> nil) and (lvResults.Selected.SubItems.Count >= 2) then
  begin
    UpdateStatus('选中文件: ' + lvResults.Selected.SubItems[1]);
  end;
end;

procedure TForm1.lvResultsDblClick(Sender: TObject);
begin
  if (lvResults.Selected <> nil) and (lvResults.Selected.SubItems.Count >= 1) then
  begin
    OpenFile(lvResults.Selected.SubItems[0]);
  end;
end;

procedure TForm1.OpenFile(const FilePath: string);
var
  Process: TProcess;
begin
  // 在Linux中打开文件
  try
    Process := TProcess.Create(nil);
    try
      Process.Executable := 'xdg-open';
      Process.Parameters.Add(FilePath);
      Process.Options := [poNoConsole];
      Process.Execute;
    finally
      Process.Free;
    end;
  except
    MessageDlg('错误', '无法打开文件', mtError, [mbOK], 0);
  end;
end;

procedure TForm1.OpenDirectory(const FilePath: string);
var
  DirPath: string;
  Process: TProcess;
begin
  DirPath := ExtractFileDir(FilePath);
  
  // 在Linux中打开目录
  try
    Process := TProcess.Create(nil);
    try
      Process.Executable := 'xdg-open';
      Process.Parameters.Add(DirPath);
      Process.Options := [poNoConsole];
      Process.Execute;
    finally
      Process.Free;
    end;
  except
    MessageDlg('错误', '无法打开目录', mtError, [mbOK], 0);
  end;
end;

procedure TForm1.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  FStopSearch := True;
end;

end.
