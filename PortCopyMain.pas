(* Copy files from portable device
   ================================
   Destination: local drive

   © Dr. J. Rathlev, D-24222 Schwentinental

   The contents of this file may be used under the terms of the
   Mozilla Public License ("MPL") or
   GNU Lesser General Public License Version 2 or later (the "LGPL")

   Software distributed under this License is distributed on an "AS IS" basis,
   WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for
   the specific language governing rights and limitations under the License.

   J. Rathlev, June 2022
   last modified: February 2024
   *)

unit PortCopyMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls, Vcl.StdCtrls, Vcl.ExtCtrls,
  IStreamApi, FileUtils, PortableDeviceApi, PortableDeviceUtils;

type
  TMainForm = class(TForm)
    lbDevices: TListBox;
    gbDevice: TGroupBox;
    Label1: TLabel;
    Label2: TLabel;
    laManu: TLabel;
    laDesc: TLabel;
    Label4: TLabel;
    laPower: TLabel;
    Label7: TLabel;
    laType: TLabel;
    Label8: TLabel;
    laFirmware: TLabel;
    btnUpdate: TButton;
    tvObjects: TTreeView;
    lvFiles: TListView;
    btnCopy: TButton;
    laPath: TLabel;
    paCopy: TPanel;
    Label3: TLabel;
    FolderDialog: TFileOpenDialog;
    Label5: TLabel;
    Label6: TLabel;
    btnShowDirs: TButton;
    laStatus: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure lbDevicesClick(Sender: TObject);
    procedure tvObjectsClick(Sender: TObject);
    procedure tvObjectsExpanding(Sender: TObject; Node: TTreeNode;
      var AllowExpansion: Boolean);
    procedure lvFilesClick(Sender: TObject);
    procedure btnCopyClick(Sender: TObject);
    procedure btnUpdateClick(Sender: TObject);
    procedure FormResize(Sender: TObject);
  private
    { Private-Deklarationen }
    DevManager : TPortableDeviceManager;
    Device : TPortableDevice;
    procedure ReloadDeviceList;
    procedure ShowDeviceProps;
    procedure RefreshStatus(Index : integer; AObjectID : string);
    procedure BuildFileList (AIndex : integer);
    procedure AddTreeLevel (node : TTreeNode; AParent : TPortableDeviceObject);
    procedure BuildTree;
  public
    { Public-Deklarationen }
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

uses Vcl.FileCtrl, System.RTLConsts, ExtFileUtils;

{ ---------------------------------------------------------------- }
const
  sBytes = 'B';
  sKiBytes = 'KiB';    // 1024 byte
  sMiBytes = 'MiB';    // 1024*1024 byte
  sGiBytes = 'GiB';    // 1024*1024*1024 byte
  sKBytes = 'kB';      // 1000 byte
  sMBytes = 'MB';      // 1000*1000 byte
  sGBytes = 'GB';      // 1000*1000*1000 byte
  sGetBytePrefixes = 'KMGT';

  Suffixes : array[boolean,1..3] of string =
    ((sKiBytes,sMiBytes,sGiBytes),(sKBytes,sMBytes,sGBytes));

// Convert number of bytes to string using prefixes from IEC 1996
// DecSep : replace character from system default
// Decimal : use 1000 as divisor instead of 1024
// NoZeroDecimals : do not show zero fractions
function SizeToStr (Bytes : int64; Decimal : boolean = false;
  NoZeroDecimals : boolean = false; DecSep : char = #0) : string;
var
  v : extended;
  n,d : integer;
  fs: TFormatSettings;

  function ZeroFrac (val : extended; Dec : integer) : boolean;
  const
    FVal : array [1..2] of extended = (0.1,0.01);
  begin
    if Dec<1 then Result:=true
    else if Dec>2 then Result:=false
    else Result:=abs(val-round(val))<FVal[Dec];
    end;

begin
  if Decimal then d:=1000 else d:=1024;
  if Bytes<d then Result:=IntToStr(Bytes)+' '+sBytes  // bytes
  else begin
    fs:=FormatSettings;
    if DecSep<>#0 then fs.DecimalSeparator:=DecSep;
    v:=Bytes/d;
    if v<d then begin
      if v<10 then n:=2 else if v<100 then n:=1 else n:=0;
      if NoZeroDecimals and ZeroFrac(v,n) then n:=0;
      Result:=Format('%.'+IntToStr(n)+'f ',[v],fs)+Suffixes[Decimal,1]; // Kibibyte/kilobyte
      end
    else begin
      v:=v/d;
      if v<d then begin
        if v<10 then n:=2 else if v<100 then n:=1 else n:=0;
        if NoZeroDecimals and ZeroFrac(v,n) then n:=0;
        Result:=Format('%.'+IntToStr(n)+'f ',[v],fs)+Suffixes[Decimal,2]// Mebibyte/Megabyte
        end
      else begin
        if NoZeroDecimals and ZeroFrac(v,2) then n:=0 else n:=2;
        Result:=Format('%.'+IntToStr(n)+'f ',[v/d],fs)+Suffixes[Decimal,3]; // Gibibyte/Gigabyte
        end
      end;
    end;
  end;

function SystemErrorMessage(ASysError : cardinal) : string;
begin
  Result:=SysErrorMessage(ASysError);
  if length(Result)>0 then Result:=Result+Format(' (0x%.8x)',[ASysError])
  else Result:=Format(' 0x%.8x',[ASysError]);
  end;

{ ---------------------------------------------------------------- }
procedure TMainForm.FormCreate(Sender: TObject);
begin
  DevManager:=TPortableDeviceManager.Create;
  FolderDialog.DefaultFolder:=ExtractFilePath(Application.ExeName);
  end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  DevManager.Free;
  end;

procedure TMainForm.FormResize(Sender: TObject);
begin
  with lvFiles do begin
    Column[1].Width:=120;
    Column[2].Width:=70;
    Column[0].Width:=Width-215;
    end;
  end;

procedure TMainForm.FormShow(Sender: TObject);
begin
  ReloadDeviceList;
  end;

procedure TMainForm.ReloadDeviceList;
var
  i : integer;
begin
  lbDevices.Clear;
  with DevManager do begin
    Refresh;
    for i:=0 to DeviceCount-1 do lbDevices.AddItem(Devices[i].DeviceName,nil);
    end;
  lbDevices.ItemIndex:=0;
  Device:=DevManager.Devices[lbDevices.ItemIndex];
  ShowDeviceProps;
  btnCopy.Enabled:=false;
  paCopy.Visible:=false;
  end;

procedure TMainForm.ShowDeviceProps;
begin
  if assigned(Device) then with Device do begin
    gbDevice.Caption:=DeviceName;
    laManu.Caption:=Manufacturer;
    laType.Caption:=DeviceTypeAsString;
    laDesc.Caption:=Description;
    laPower.Caption:=PowerSourceAsString+' ('+IntTostr(PowerLevel)+'%)';
    laFirmware.Caption:=Firmware;
    end;
  end;

procedure TMainForm.BuildFileList (AIndex : integer);
var
  i : integer;
  pdo : TPortableDeviceObject;
begin
  Screen.Cursor:=crHourGlass;
  with lvFiles.Items do begin
    Clear;
    BeginUpdate;
    end;
  with Device.Content.Objects[AIndex] do begin
    for i:=0 to ChildCount-1 do begin
      pdo:=Children[i];
      if assigned(pdo) and (pdo.ObjectType=otFile) then begin
        with lvFiles.Items.Add do with pdo do begin
          Caption:=OriginalName;
          if length(Caption)=0 then Caption:=ExtractFilename(ObjectID);
          SubItems.Add(DateTimeToStr(LastWriteTime));
          SubItems.Add(SizeToStr(Size));
          Data:=pointer(pdo.Index);
          end;
        end;
      end;
    end;
  lvFiles.Items.EndUpdate;
  Screen.Cursor:=crDefault;
  end;

procedure TMainForm.AddTreeLevel (node : TTreeNode; AParent : TPortableDeviceObject);
var
  pdo : TPortableDeviceObject;
  nc  : TTreeNode;
  i   : integer;
  sn  : string;
begin
  with AParent do for i:=0 to ChildCount-1 do begin
    pdo:=Children[i];
    if assigned(pdo) and (pdo.ObjectType in [otRoot,otFolder]) then begin
      sn:=pdo.DisplayName;
      nc:=tvObjects.Items.AddChild(node,sn);
      nc.Data:=pointer(pdo.Index);
      tvObjects.Items.AddChild(nc,'');
      end;
    end;
  end;

procedure TMainForm.RefreshStatus(Index : integer; AObjectID : string);
begin
  if Index mod 10 = 0 then begin
    laStatus.Caption:=Format('%u objects found',[Index]);
    Application.ProcessMessages;
    end;
  end;

procedure TMainForm.BuildTree;
var
  node : TTreeNode;
  pdo : TPortableDeviceObject;
  sn  : string;
begin
  Screen.Cursor:=crHourGlass;
  with tvObjects.Items do begin
    Clear;
    BeginUpdate;
    end;
  with Device.Content do begin
    Refresh(RefreshStatus);
    with ErrorObjects do if Count>0 then begin
      sn:=Format('Error on object "%s": %s',[Strings[0],SystemErrorMessage(ErrorCode[0])]);
      if Count>1 then sn:=sn+sLineBreak+Format('... &u more errors',[Count-1]);
      MessageDlg(sn,mtError,[mbClose],0);
      end;
    pdo:=DeviceObject;
    if assigned(pdo) then begin
      sn:=pdo.DisplayName;
      node:=tvObjects.Items.Add(nil,sn);
      AddTreeLevel(node,pdo);
      node.Expand(false);
      end;
    laStatus.Caption:=Format('%u objects found',[ObjectCount]);
    end;
  tvObjects.Items.EndUpdate;
  Screen.Cursor:=crDefault;
  end;

procedure TMainForm.btnUpdateClick(Sender: TObject);
begin
  ReloadDeviceList;
  end;

procedure TMainForm.lbDevicesClick(Sender: TObject);
begin
  Device:=DevManager.Devices[lbDevices.ItemIndex];
  ShowDeviceProps;
  btnCopy.Enabled:=false;
  paCopy.Visible:=false;
  BuildTree;
  end;

procedure TMainForm.tvObjectsClick(Sender: TObject);
var
  node : TTreeNode;
begin
  node:=tvObjects.Selected;
  if node<>nil then begin
    BuildFileList(integer(node.Data));
    end;
  btnCopy.Enabled:=false;
  paCopy.Visible:=false;
  end;

procedure TMainForm.tvObjectsExpanding(Sender: TObject; Node: TTreeNode;
  var AllowExpansion: Boolean);
var
  ndx : integer;
begin
  with tvObjects,Items do begin
    BeginUpdate;
    node.DeleteChildren;
    ndx:=integer(node.Data);
    AddTreeLevel(node,Device.Content.Objects[ndx]);
    EndUpdate;
    end;
  end;

procedure TMainForm.lvFilesClick(Sender: TObject);
var
  n : integer;
  SelObject : TPortableDeviceObject;
begin
  n:=integer(lvFiles.Selected.Data);
  SelObject:=Device.Content.Objects[n];
  btnCopy.Enabled:=SelObject.ObjectType=otFile;
  end;

{ ------------------------------------------------------------------- }
// copy file
const
  defBufferSize = 512*1024;     // default buffer size for copy operations

procedure CopyPortableFile (const ASource : TFileData; const ADestName : string);
var
  sDest : TFileStream;
  FBuffer : array of byte;
  NRead,NWrite,bs : cardinal;
  sLen : int64;
  ec : integer;
  hr : HResult;
begin
  sDest:=TFileStream.Create(ADestName,fmCreate);
  with ASource do begin
    bs:=StreamData.BufferSize;
    if bs=0 then bs:=defBufferSize;
    SetLength(FBuffer,bs); sLen:=FileSize;
    repeat
      hr:=StreamData.FileStream.Read(FBuffer[0],bs,NRead);
      if failed(hr) then begin
        sDest.Free;
        raise EReadError.CreateRes(@SReadError);
        end;
      NWrite:=sDest.Write(FBuffer[0],NRead);
      if NWrite<NRead then begin
        sDest.Free;
        raise EWriteError.CreateRes(@SWriteError);
        end;
      dec(sLen,NRead);
      until (sLen<=0);
    try ASource.StreamData.FileStream.Commit(0); except end;
    FBuffer:=nil;
    end;
  try sDest.Free; except; end;
  ec:=SetFileTimestamps(ADestName,ASource.TimeStamps,false);
  if ec<>NO_ERROR then
     raise EWriteError.Create(SystemErrorMessage(ec));
  end;

procedure TMainForm.btnCopyClick(Sender: TObject);
var
  i,n : integer;
  PDObject : TPortableDeviceObject;
  Dest,sd  : string;
  FileData : TFileData;
begin
  with FolderDialog do if Execute then begin
    Dest:=Filename;
    paCopy.Visible:=true;
    with lvFiles do for i:=0 to Items.Count-1 do with Items[i] do if Selected then begin
      n:=integer(Data);
      PDObject:=Device.Content.Objects[n];
      with PDObject do begin
        with laPath do Caption:=MinimizeName(OriginalName,Canvas,paCopy.Width-2*Left);
        sd:=IncludeTrailingPathDelimiter(Dest)+ExtractFilename(OriginalName);
        GetFileData(FileData,true);
        end;
      try
        CopyPortableFile(FileData,sd);
      except
        on E:Exception do ShowMessage('Error: '+E.Message);
        end;
      Application.ProcessMessages;
      sleep(1000);
      end;
    end;
  paCopy.Visible:=false;
  end;

end.
