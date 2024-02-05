(* Delphi Unit
  Objects and functions to access Windows Portable Devices
  ========================================================

  © Dr. J. Rathlev, D-24222 Schwentinental (kontakt(a)rathlev-home.de)

  The contents of this file may be used under the terms of the
  Mozilla Public License ("MPL") or
  GNU Lesser General Public License Version 2 or later (the "LGPL")

  Software distributed under this License is distributed on an "AS IS" basis,
  WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for
  the specific language governing rights and limitations under the License.

  Vers. 1 -  July 2022
  last modified - January 2024
*)

unit PortableDeviceUtils;

interface

uses System.SysUtils, System.Classes, System.Contnrs, Winapi.Windows, Winapi.ActiveX,
  Winapi.ShlObj, Vcl.ComCtrls, IStreamApi, ExtFileUtils,
  PortableDeviceDefs, PortableDeviceApi;

const
  CLIENT_NAME         = 'Delphi PortableDeviceUtils';
  CLIENT_MAJOR_VER    = 1;
  CLIENT_MINOR_VER    = 0;
  CLIENT_REVISION     = 4;

  PowerSources : array of string = ['Battery','External'];
  DeviceTypes : array of string = ['Generic','Camera','Media Player','Phone',
                    'Video','Personal Information Manager','Audio Recorder'];

type
  TContentType = (ctUnknown, ctFunctionalObject, ctFolder, ctImage, ctDocument,
    ctContact, ctContactGroup, ctAudio, ctVideo, ctTelevision, ctPlayList,
    ctMixedContentAlbum, ctAudioAlbum, ctImageAlbum, ctVideoAlbum, ctMemo,
    ctEmail, ctAppointment, ctTask, ctProgram, ctGenericFile, ctCalendar,
    ctGenericMessage, ctNetworkAssociation, ctTypeCertificate, ctWirelessProfile,
    ctMediaCast, ctSection, ctUnspecified);

  TObjectType = (otUnknown,otDevice,otRoot,otFolder,otFile);
  TObjectTypes = set of TObjectType;

  TObjectProperty = (opCreationTime,opLastWriteTime,opSize);

  TFindObjects = procedure (Index : integer; AObjectID : string) of Object;

  TObjectFormat = (ofUnknown, ofScript, ofExecutable, ofText, ofHtml, ofDigPrintOrder,
    ofAudioInterchange, ofWave, ofMp3, ofAvi, ofMpeg, ofAdvStream, ofExif, ofTiffEp,
    ofFlashPix, ofBmp, ofCamImg, ofGif, ofJpgInterchange, ofPtCloudData, ofPict, ofPng,
    ofTiff, ofTiffIt, ofJp2, ofJpX, ofWinImg, ofWma, ofWmv, ofWplPlaylist, ofM3uPlaylist,
    ofMplPlaylist, ofAsxPlaylist, ofPlsPlaylist, ofAbstractContactGroup, ofAbstractMediaCast,
    ofVCalendar, ofICalendar, ofAbstractContact, ofVCard2, ofVCard3, ofIcon, ofXml,
    ofAdvAudioCoding, ofAudible, ofFlac, ofOgg, ofMp4, ofM4a, ofMp2, ofMSWord,
    ofCompiledHtml, ofMSExel, ofMSPowerpoint, ofNetworkAssoc, ofX509Ceritficate,
    ofMSWfc, of3Gp, of3Gpa, ofPropsOnly);

const
  ContentTypeGuids : array of PGuid = [
    @WPD_CONTENT_TYPE_ALL,
    @WPD_CONTENT_TYPE_FUNCTIONAL_OBJECT,
    @WPD_CONTENT_TYPE_FOLDER,
    @WPD_CONTENT_TYPE_IMAGE,
    @WPD_CONTENT_TYPE_DOCUMENT,
    @WPD_CONTENT_TYPE_CONTACT,
    @WPD_CONTENT_TYPE_CONTACT_GROUP,
    @WPD_CONTENT_TYPE_AUDIO,
    @WPD_CONTENT_TYPE_VIDEO,
    @WPD_CONTENT_TYPE_TELEVISION,
    @WPD_CONTENT_TYPE_PLAYLIST,
    @WPD_CONTENT_TYPE_MIXED_CONTENT_ALBUM,
    @WPD_CONTENT_TYPE_AUDIO_ALBUM,
    @WPD_CONTENT_TYPE_IMAGE_ALBUM,
    @WPD_CONTENT_TYPE_VIDEO_ALBUM,
    @WPD_CONTENT_TYPE_MEMO,
    @WPD_CONTENT_TYPE_EMAIL,
    @WPD_CONTENT_TYPE_APPOINTMENT,
    @WPD_CONTENT_TYPE_TASK,
    @WPD_CONTENT_TYPE_PROGRAM,
    @WPD_CONTENT_TYPE_GENERIC_FILE,
    @WPD_CONTENT_TYPE_CALENDAR,
    @WPD_CONTENT_TYPE_GENERIC_MESSAGE,
    @WPD_CONTENT_TYPE_NETWORK_ASSOCIATION,
    @WPD_CONTENT_TYPE_CERTIFICATE,
    @WPD_CONTENT_TYPE_WIRELESS_PROFILE,
    @WPD_CONTENT_TYPE_MEDIA_CAST,
    @WPD_CONTENT_TYPE_SECTION,
    @WPD_CONTENT_TYPE_UNSPECIFIED];

  ObjectFormatGuids : array of PGuid = [
    @WPD_OBJECT_FORMAT_UNSPECIFIED,
    @WPD_OBJECT_FORMAT_SCRIPT,
    @WPD_OBJECT_FORMAT_EXECUTABLE,
    @WPD_OBJECT_FORMAT_TEXT,
    @WPD_OBJECT_FORMAT_HTML,
    @WPD_OBJECT_FORMAT_DPOF,
    @WPD_OBJECT_FORMAT_AIFF,
    @WPD_OBJECT_FORMAT_WAVE,
    @WPD_OBJECT_FORMAT_MP3,
    @WPD_OBJECT_FORMAT_AVI,
    @WPD_OBJECT_FORMAT_MPEG,
    @WPD_OBJECT_FORMAT_ASF,
    @WPD_OBJECT_FORMAT_EXIF,
    @WPD_OBJECT_FORMAT_TIFFEP,
    @WPD_OBJECT_FORMAT_FLASHPIX,
    @WPD_OBJECT_FORMAT_BMP,
    @WPD_OBJECT_FORMAT_CIFF,
    @WPD_OBJECT_FORMAT_GIF,
    @WPD_OBJECT_FORMAT_JFIF,
    @WPD_OBJECT_FORMAT_PCD,
    @WPD_OBJECT_FORMAT_PICT,
    @WPD_OBJECT_FORMAT_PNG,
    @WPD_OBJECT_FORMAT_TIFF,
    @WPD_OBJECT_FORMAT_TIFFIT,
    @WPD_OBJECT_FORMAT_JP2,
    @WPD_OBJECT_FORMAT_JPX,
    @WPD_OBJECT_FORMAT_WINDOWSIMAGEFORMAT,
    @WPD_OBJECT_FORMAT_WMA,
    @WPD_OBJECT_FORMAT_WMV,
    @WPD_OBJECT_FORMAT_WPLPLAYLIST,
    @WPD_OBJECT_FORMAT_M3UPLAYLIST,
    @WPD_OBJECT_FORMAT_MPLPLAYLIST,
    @WPD_OBJECT_FORMAT_ASXPLAYLIST,
    @WPD_OBJECT_FORMAT_PLSPLAYLIST,
    @WPD_OBJECT_FORMAT_ABSTRACT_CONTACT_GROUP,
    @WPD_OBJECT_FORMAT_ABSTRACT_MEDIA_CAST,
    @WPD_OBJECT_FORMAT_VCALENDAR1,
    @WPD_OBJECT_FORMAT_ICALENDAR,
    @WPD_OBJECT_FORMAT_ABSTRACT_CONTACT,
    @WPD_OBJECT_FORMAT_VCARD2,
    @WPD_OBJECT_FORMAT_VCARD3,
    @WPD_OBJECT_FORMAT_ICON,
    @WPD_OBJECT_FORMAT_XML,
    @WPD_OBJECT_FORMAT_AAC,
    @WPD_OBJECT_FORMAT_AUDIBLE,
    @WPD_OBJECT_FORMAT_FLAC,
    @WPD_OBJECT_FORMAT_OGG,
    @WPD_OBJECT_FORMAT_MP4,
    @WPD_OBJECT_FORMAT_M4A,
    @WPD_OBJECT_FORMAT_MP2,
    @WPD_OBJECT_FORMAT_MICROSOFT_WORD,
    @WPD_OBJECT_FORMAT_MHT_COMPILED_HTML,
    @WPD_OBJECT_FORMAT_MICROSOFT_EXCEL,
    @WPD_OBJECT_FORMAT_MICROSOFT_POWERPOINT,
    @WPD_OBJECT_FORMAT_NETWORK_ASSOCIATION,
    @WPD_OBJECT_FORMAT_X509V3CERTIFICATE,
    @WPD_OBJECT_FORMAT_MICROSOFT_WFC,
    @WPD_OBJECT_FORMAT_3GP,
    @WPD_OBJECT_FORMAT_3GPA,
    @WPD_OBJECT_FORMAT_PROPERTIES_ONLY];

  ObjectPropertyGuids : array [TObjectProperty] of PPropertyKey = (
    @WPD_OBJECT_DATE_CREATED,
    @WPD_OBJECT_DATE_MODIFIED,
    @WPD_OBJECT_SIZE);

  FileObjects : set of TContentType = [ctImage, ctDocument, ctContact, ctAudio,
    ctVideo, ctTelevision, ctPlayList, ctMemo, ctEmail, ctProgram, ctGenericFile,
    ctCalendar, ctGenericMessage, ctTypeCertificate,ctMediaCast, ctUnspecified];

  otDefault = [otDevice,otRoot,otFolder,otFile];

  ObjectExtensions : array [TObjectFormat] of string = ('','txt','','txt','html','dpof',
    'aiff','wav','mp3','avi','mpeg','asf','jpg','tiffep',
    'flashpix','bmp','ciff','gif','jfif','pcd','pict','png',
    'tiff','tiffit','jp2','jpx','wim','wma','wmv','wpl','m3u',
    'mpl','asx','pls','','','vcs','ics','','vcf','vcf','ico','xml',
    'aac','aax','flac','ogg','mp4','m4a','mp2','doc',
    'chm','xls','pps','','x509','wfc','3gp','gpa','');

type
  TPCharArray = array of PWideChar;

  TDeviceList = class (TStringList);
  TPortableDeviceManager = class;
  TPortableDevice = class;
  TPortableDeviceContent = class;

  TErrorList = class (TStringList)
  private
    function GetErrorCode (AIndex : integer) : cardinal;
  public
    procedure AddError (const ObjectId : string; ErrorCode : cardinal);
    property Errorcode[Index : integer] : cardinal read GetErrorCode;
    end;

  TDeviceData = class (TObject)
  private
    FriendlyName : string;
  public
    constructor Create (const AName : string);
    end;

  TPortableDeviceObject = class (TObject)
  private
    FObjectID,FParentID,
    FObjectName,
    FOriginalName : string;
    FContentType : TGuid;
    FObjectFormat : TGuid;
    FContent : TPortableDeviceContent;
    FChildObjects : array of integer;
    FChildCount,
    FIndex,
    FParentIndex,
    FLevel : integer;
    function GetChildCount : integer;
    function GetChild (Index : integer) : TPortableDeviceObject;
    function GetParentID : string;
    function GetContentGuid: TGuid;
    function GetContentType : TContentType;
    function GetObjectName : string;
    function GetOriginalName : string;
    function GetDisplayName : string;
    function GetObjecType : TObjectType;
    function GetObjectFormat : TObjectFormat;
    function GetObjectExt : string;
    function GetCreationTime: TDateTime;
    function GetLastWriteTime: TDateTime;
    function GetSize: int64;
    function GetPath : string;
  protected
    procedure SetIndex (Value : integer);
  public
    constructor Create (const AContent : TPortableDeviceContent; const AObjectID : string;
                        AParentIndex : integer = 0; ALevel : integer = 0);
    destructor Destroy; override;
    function CopyToFile (const AFilename : string) : HResult;
    function GetFileData (var AFileData : TFileData; AGetStream : boolean = false) : HResult;
    function GetFileStream (var AStreamData : TFileStreamData) : HResult;
    procedure AddChild (AIndex : integer);
    function GetChildByName (const AName : string) : TPortableDeviceObject;
    function GetChildByOriginalName (const AName : string) : TPortableDeviceObject;
//    property ChildObjectCount : integer read FChildObjectCount;
    function GetProperty (const PropertyKey : TPropertyKey; var pv : TPropVariant) : HResult;
    function CanWriteProperty (ObjectProperty : TObjectProperty) : boolean;
    function AddNameExtension (const AFilename : string) : string;
    property ContentGuid : TGuid read GetContentGuid;
    property ContentType : TContentType read GetContentType;
    property Index : integer read FIndex;
    property Level : integer read FLevel;
    property ObjectName : string read GetObjectName;
    property OriginalName : string read GetOriginalName;
    property DisplayName : string read GetDisplayName;
    property ObjectExtension : string read GetObjectExt;
    property ObjectFormat : TObjectFormat read GetObjectFormat;
    property ObjectType : TObjectType read GetObjecType;
    property ObjectID : string read FObjectID;
    property Path : string read GetPath;
    property ParentID : string read GetParentID;
    property ParentIndex : integer read FParentIndex;
    property CreationTime: TDateTime read GetCreationTime;
    property LastWriteTime : TDateTime read GetLastWriteTime;
    property Size: int64 read GetSize;
    property ChildCount : integer read GetChildCount;
    property Children[Index : integer] : TPortableDeviceObject read GetChild;
    end;

  TPortableDeviceContent = class (TObject)
  private
    pContent : IPortableDeviceContent;
    FDevice  : TPortableDevice;
    FObjectList : TStringlist;
    FFindCallback : TFindObjects;
    FErrorObjects : TErrorList;
    function FindObjects (const AObjectID : string; AParent : TPortableDeviceObject) : boolean;
    function GetObjectCount : integer;
    function GetRootCount : integer;
    function GetFolderCount : integer;
    function GetObject (Index : integer) : TPortableDeviceObject;
    function GetDevObject : TPortableDeviceObject;
    function GetRootObject (Index : integer) : TPortableDeviceObject;
  public
    constructor Create (const ADevice : TPortableDevice);
    destructor Destroy; override;
    function Refresh (ACallBack : TFindObjects = nil) : boolean;
    function FindNextObject (AObjectType : TObjectType; var AIndex : integer) : TPortableDeviceObject;
    function GetObjectByID (const AObjectID : string) : TPortableDeviceObject;
    function GetObjectByPath (APath : string) : TPortableDeviceObject;
    function GetObjectIndexByPath (const APath : string) : integer;
    property ErrorObjects : TErrorList read FErrorObjects;
    property ObjectCount : integer read GetObjectCount;
    property Objects[Index : integer] : TPortableDeviceObject read GetObject;
    property DeviceObject : TPortableDeviceObject read GetDevObject;
    property FolderCount : integer read GetFolderCount;
    property RootCount : integer read GetRootCount;
    property RootObjects[Index : integer] : TPortableDeviceObject read GetRootObject;
    end;

  TPortableDevice = class (TObject)
  private
    pDevice : IPortableDevice;
    pCapabilities : IPortableDeviceCapabilities;
    FDeviceManager : TPortableDeviceManager;
    FContent : TPortableDeviceContent;
    FDeviceObject : TPortableDeviceObject;
    FDeviceID : string;
    function GetDeviceName : string;
    function GetDescription: string;
    function GetManufacturer : string;
    function GetFirmware : string;
    function GetModel : string;
    function GetProtocol : string;
    function GetPowerSource : cardinal;
    function GetPowerSourceAsString : string;
    function GetPowerLevel : cardinal;
    function GetSerialNumber : string;
    function GetDeviceType : cardinal;
    function GetDeviceTypeAsString : string;
  public
    constructor Create (const AManager : TPortableDeviceManager; const ADeviceID : string);
    destructor Destroy; override;
    property Content : TPortableDeviceContent read FContent;
    property Description : string read GetDescription;
    property DeviceID : string read FDeviceID;
    property DeviceName : string read GetDeviceName;
    property DeviceType : cardinal read GetDeviceType;
    property DeviceTypeAsString : string read GetDeviceTypeAsString;
    property Firmware : string read GetFirmware;
    property Manufacturer : string read GetManufacturer;
    property Model : string read GetModel;
    property PowerLevel : cardinal read GetPowerLevel;
    property PowerSource : cardinal read GetPowerSource;
    property PowerSourceAsString : string read GetPowerSourceAsString;
    property Protocol : string read GetProtocol;
    property SerialNumber: string read GetSerialNumber;
    end;

  TPortableDeviceManager = class (TObject)
  private
    pDeviceManager    : IPortableDeviceManager;
    FDeviceCount      : cardinal;
    FDeviceList       : TDeviceList;
    FCurrentDevice    : TPortableDevice;
    function GetDevice (Index : integer) : TPortableDevice;
  public
    constructor Create;
    destructor Destroy; override;
    function GetClientInformation :  IPortableDeviceValues;
    function GetDeviceByName (const DeviceName : string) : TPortableDevice;
    function GetDeviceByID (const DeviceID : string) : TPortableDevice;
    procedure Refresh;
    property DeviceCount : cardinal read FDeviceCount;
    property Devices[Index : integer] : TPortableDevice read GetDevice;
    property SelectedDevice : TPortableDevice read FCurrentDevice;
    end;

// Helper functions to access files on portable devices from Windows Shell
function GetPortableParsingNameFromIDList (AbsoluteID: PItemIDLIst; var ParsName : string) : boolean;
function GetPortableFríendlyNameFromIDList (AbsoluteID: PItemIDLIst) : string;

function SplitPortableDeviceParsingName (const APath : string;
                       var BaseCLSID : TGuid; var DeviceID,DevicePath : string) : boolean;
function GetPortableDeviceIDFromParsingName (const APath : string) : string;
function GetPortableObjectIDFromParsingName (const APath : string) : string;
function GetPortableObjectIDFromIDList (AbsoluteID: PItemIDLIst) : string;

// read properties of IStream
function GetStreamInfoFromIStream (AStream : IStream; var FileData : TFileData) : HResult;

implementation

uses System.Win.ComObj, System.DateUtils, FileUtils;

//-----------------------------------------------------------------------------
// Extract first subdirectory from path and remove from Path
function ExtractFirstDir (var Path : string) : string;
var
  n : integer;
begin
  Result:='';
  if length(Path)>0 then begin
    if (Path[1]<>PathDelim) and (pos(DriveDelim,Path)=0) then begin
      n:=Pos(PathDelim,Path);
      if n>0 then begin
        Result:=copy(Path,1,n-1); delete(Path,1,n);
        end
      else begin
        Result:=Path; Path:='';
        end;
      end;
    end;
  end;

//-----------------------------------------------------------------------------
// Raise EOleSysError exception from an error code and show hint
procedure OleErrorHint(ErrorCode : HResult; const Hint : string = '');
var se : string;
begin
  se:=SysErrorMessage(ErrorCode);
  if length(se)=0 then se:='<Unknown error code>'
  else se:=se+Format(' (0x%.8x)',[ErrorCode]);
  raise EOleSysError.Create(Hint+' : '+se,ErrorCode,0);
  end;

// Raise EOleSysError exception if result code indicates an error }
procedure OleCheck(Result : HResult; const Hint : string = '');
begin
  if failed(Result) then begin
    OleErrorHint(Result,'Error calling: '+Hint);
    end;
  end;

//-----------------------------------------------------------------------------
// Get a practical parse name for objects on portable devices
// split and combine paths from SIGDN_DESKTOPABSOLUTEPARSING and SIGDN_DESKTOPABSOLUTEEDITING
function GetPortableParsingNameFromIDList (AbsoluteID: PItemIDLIst; var ParsName : string) : boolean;
var
  pn : PWideChar;
  sa,se : string;
  n1,n2 : integer;
begin
  Result:=false;
  OleCheck(SHGetNameFromIDList(AbsoluteID,SIGDN_DESKTOPABSOLUTEPARSING,pn),
    'GetPortableParsingNameFromIDList:SHGetNameFromIDList(SIGDN_DESKTOPABSOLUTEPARSING)');
  sa:=pn; CoTaskMemFree(pn); pn:=nil;
  OleCheck(SHGetNameFromIDList(AbsoluteID,SIGDN_DESKTOPABSOLUTEEDITING,pn),
    'GetPortableParsingNameFromIDList:SHGetNameFromIDList(SIGDN_DESKTOPABSOLUTEEDITING)');
  se:=pn; CoTaskMemFree(pn); pn:=nil;
  n1:=pos('\\\?\',sa);
  if n1>0 then begin
    n1:=pos('\',sa,n1+5);
    if n1>0 then begin
      n2:=pos('\',se);
      n2:=pos('\',se,n2+1);
      ParsName:=copy(sa,1,n1)+copy(se,n2+1,length(se));
      Result:=true;
      end
    else ParsName:=sa;
    end
  else ParsName:=sa;
  end;

// Get friendly name for the portable device path
function GetPortableFríendlyNameFromIDList (AbsoluteID: PItemIDLIst) : string;
var
  pn : PWideChar;
  n  : integer;
begin
  OleCheck(SHGetNameFromIDList(AbsoluteID,SIGDN_DESKTOPABSOLUTEEDITING,pn),
    'GetPortableParsingNameFromIDList:SHGetNameFromIDList(SIGDN_DESKTOPABSOLUTEEDITING)');
  Result:=pn; CoTaskMemFree(pn); pn:=nil;
  n:=pos('\',Result);
  if n>0 then Result:=copy(Result,n+1,length(Result));
  end;

// Split parsing name
function SplitPortableDeviceParsingName (const APath : string;
                       var BaseCLSID : TGuid; var DeviceID,DevicePath : string) : boolean;
var
  n : integer;
  s : string;
begin
  BaseCLSID:=GUID_NULL; DeviceID:=''; DevicePath:='';
  Result:=false;
  if pos('::',APath)=1 then begin
    n:=pos('\\\?\',APath);
    if n>0 then begin
      s:=copy(APath,3,n-3);
      BaseCLSID:=StringToGuid(s);
      s:=copy(APath,n+1,length(APath));
      Result:=true;
      n:=pos('\',s,6);
      if n>0 then begin
        DeviceID:=copy(s,1,n-1);
        DevicePath:=copy(s,n+1,length(s));
        end
      else DeviceID:=s;
      end;
    end;
  end;

// Get the ID of a portable device from parsing name
function GetPortableDeviceIDFromParsingName (const APath : string) : string;
var
  n : integer;
begin
  n:=pos('\\\?\',APath);
  if n>0 then begin
    Result:=copy(APath,n+1,length(APath));
    n:=pos('\',Result,6);
    if n>0 then Result:=copy(Result,1,n-1);
    end
  else Result:='';
  end;

// Get the ID of a portable device object from parsing name
function GetPortableObjectIDFromParsingName (const APath : string) : string;
var
  si : IShellItem2;
  pv : TPropVariant;
begin
  OleCheck(SHCreateItemFromParsingName(PChar(APath),nil,IShellItem2,si),'GetPortableObjectIDFromParsingName:SHCreateItemFromParsingName');;
  OleCheck(si.GetProperty(WPD_OBJECT_ID,pv),'GetPortableObjectIDFromIDListFromParsingName:IShellItem2.GetProperty');
  with pv do if (vt=VT_LPWSTR) and (pwszVal<>nil) then Result:=pwszVal else Result:='';
  PropVariantClear(pv);
  end;

// Get the ObjectID of and portable device object from IDList
function GetPortableObjectIDFromIDList (AbsoluteID: PItemIDLIst) : string;
var
  si : IShellItem2;
  pv : TPropVariant;
begin
  OleCheck(SHCreateItemFromIDList(AbsoluteID,IShellItem2,si),'GetPortableObjectIDFromIDList:SHCreateItemFromIDList');
  OleCheck(si.GetProperty(WPD_OBJECT_ID,pv),'GetPortableObjectIDFromIDList:IShellItem2.GetProperty');
  with pv do if (vt=VT_LPWSTR) and (pwszVal<>nil) then Result:=pwszVal else Result:='';
  PropVariantClear(pv);
  end;

//-----------------------------------------------------------------------------
// Free assigned objects in TStrings
procedure FreeListObjects (Liste : TStrings);
var
  i : integer;
begin
  with Liste do begin
    for i:=0 to Count-1 do if assigned(Objects[i]) then begin
      try Objects[i].Free; except end;
      Objects[i]:=nil;
      end;
    end;
  end;

// -----------------------------------------------------------------------------
// read properties of IStream
function GetStreamInfoFromIStream (AStream : IStream; var FileData : TFileData) : HResult;
var
  ssg : TStatStg;
begin
  with FileData do begin
    FileName:=''; FileSize:=0; FileAttr:=INVALID_FILE_ATTRIBUTES;
    TimeStamps.Reset;
    end;
  Result:=AStream.Stat(ssg,STATFLAG_NONAME);
  if succeeded(Result) and (ssg.dwType=STGTY_STREAM) then with FileData do begin
    FileSize:=ssg.cbSize.QuadPart; FileAttr:=faArchive;
    with TimeStamps do begin
      Valid:=true;
      CreationTime:=ssg.ctime;
      LastWriteTime:=ssg.mtime;
      LastAccessTime:=ssg.atime;
      end;
    end;
  end;

//-----------------------------------------------------------------------------
// Copies data from a source stream to a destination stream using the
// specified transferSizeBytes as the temporary buffer size.
// requires IStream definition from PortableDeviceApi
function StreamCopy(SourceStream,DestStream : IStream; BufSize : cardinal) : HResult;
var
  tbuf  : array of byte;
  br,bw : cardinal;
begin
  // Allocate a temporary buffer of optimal transfer size (IPortableDeviceResources.GetStream)
  SetLength(tbuf,BufSize);
  repeat
    // Read object data from the source stream
    Result:=sourceStream.Read(tbuf[0],BufSize,br);
    if succeeded(Result) then begin
      if br>0 then begin
        // Write object data to the destination stream
        Result:=destStream.Write(tbuf[0],br,bw);
        end;
      end
    until failed(Result) or (br=0);
  tbuf:=nil;
  end;

//-----------------------------------------------------------------------------
function GetContentTypeFromGuid (const contentType : TGuid) : TContentType;
var
  i : integer;
begin
  for i:=0 to High(ContentTypeGuids) do if ContentTypeGuids[i]^=contentType then Break;
  if i<length(ContentTypeGuids) then Result:=TContentType(i) else Result:=ctUnknown;
  end;

//-----------------------------------------------------------------------------
function GetFormatTypeFromGuid (const formatType : TGuid) : TObjectFormat;
var
  i : integer;
begin
  for i:=0 to High(ObjectFormatGuids) do if ObjectFormatGuids[i]^=formatType then Break;
  if i<length(ObjectFormatGuids) then Result:=TObjectFormat(i) else Result:=ofUnknown;
  end;

//-----------------------------------------------------------------------------
function TErrorList.GetErrorCode (AIndex : integer) : cardinal;
begin
  Result:=cardinal(Objects[AIndex]);
  end;

procedure TErrorList.AddError (const ObjectId : string; ErrorCode : cardinal);
begin
  AddObject(ObjectId,pointer(ErrorCode));
  end;

//-----------------------------------------------------------------------------
constructor TDeviceData.Create (const AName : string);
begin
  inherited Create;
  FriendlyName:=AName;
  end;

//-----------------------------------------------------------------------------
constructor TPortableDeviceObject.Create (const AContent : TPortableDeviceContent; const AObjectID : string;
                                          AParentIndex,ALevel : integer);
begin
  inherited Create;
  FContent:=AContent; FObjectID:=AObjectID; FParentIndex:=AParentIndex; FLevel:=ALevel;
  FParentID:=''; FObjectName:=''; FOriginalName:='';
  FChildCount:=-1; FChildObjects:=nil;
  FContentType:=GUID_NULL; FObjectFormat:=GUID_NULL;
  end;

destructor TPortableDeviceObject.Destroy;
begin
  FChildObjects:=nil;
  inherited Destroy;
  end;

function TPortableDeviceObject.GetFileData (var AFileData : TFileData; AGetStream : boolean) : HResult;
var
  Resources : IPortableDeviceResources;
begin
  AFileData.Reset;
  Result:=FContent.pContent.Transfer(Resources);
  if succeeded(Result) then begin
    with AFileData do begin
      Filename:=DisplayName;
      FileSize:=Size;
      TimeStamps.SetTimeStamps(CreationTime,LastWriteTime);
      if ObjectType=otFile then begin
        FileAttr:=faNormal;
        // Get the IStream (with READ access) and the optimal transfer buffer size to begin the transfer.
        if AGetStream then with StreamData do
          Result:=Resources.GetStream(PChar(FObjectID),WPD_RESOURCE_DEFAULT,STGM_READ,BufferSize,FileStream );
        end
      else FileAttr:=faDirectory;
      end;
    end;
  end;

function TPortableDeviceObject.GetFileStream (var AStreamData : TFileStreamData) : HResult;
var
  Resources : IPortableDeviceResources;
begin
  AStreamData.Reset;
  Result:=FContent.pContent.Transfer(Resources);
  if succeeded(Result) then with AStreamData do begin
  // Get the IStream (with READ access) and the optimal transfer buffer size to begin the transfer.
    Result:=Resources.GetStream(PChar(FObjectID),WPD_RESOURCE_DEFAULT,STGM_READ,BufferSize,FileStream );
    end;
  end;

function TPortableDeviceObject.CopyToFile (const AFilename : string) : HResult;
var
  BufSize   : cardinal;
  Resources : IPortableDeviceResources;
  ObjStream,FileStream : IStream;
begin
  OleCheck(FContent.pContent.Transfer(Resources),
    'TPortableDeviceObject.GetProperty:IPortableDeviceContent.Transfer');
  BufSize:=0;
  // Get the IStream (with READ access) and the optimal transfer buffer size to begin the transfer.
  OleCheck(Resources.GetStream(PChar(FObjectID),WPD_RESOURCE_DEFAULT,STGM_READ,BufSize,ObjStream),
    'TPortableDeviceObject.GetProperty:IPortableDeviceResources.GetStream');
  // Create a destination for the data to be written to.
  Result:=SHCreateStreamOnFileEx(PChar(AFilename),STGM_CREATE or STGM_WRITE,FILE_ATTRIBUTE_NORMAL,false,nil,FileStream);
  if succeeded(Result) then begin
    Result:=StreamCopy(ObjStream,FileStream,BufSize);
    if succeeded(Result) then Result:=FileStream.Commit(STGC_DEFAULT);
    end;
  end;

procedure TPortableDeviceObject.SetIndex (Value : integer);
begin
  FIndex:=Value;
  end;

function TPortableDeviceObject.GetProperty (const PropertyKey : TPropertyKey; var pv : TPropVariant) : HResult;
var
  objectProperties : IPortableDeviceValues;
  Properties       : IPortableDeviceProperties;
  PropertiesToRead : IPortableDeviceKeyCollection;
begin
  Result:=FContent.pContent.Properties(properties);
  // CoCreate an IPortableDeviceKeyCollection interface to hold the property keys
  if succeeded(Result) then
    Result:=CoCreateInstance(CLSID_PortableDeviceKeyCollection,nil,CLSCTX_INPROC_SERVER,
             IPortableDeviceKeyCollection,PropertiesToRead);
  // Populate the IPortableDeviceKeyCollection with desired objects
  if succeeded(Result) then begin
    PropertiesToRead.Add(PropertyKey);
    Result:=properties.GetValues(PChar(FObjectID),PropertiesToRead,objectProperties);
    if succeeded(Result) then Result:=objectProperties.GetValue(PropertyKey,pv);
// 'Die angeforderte Ressource wird bereits verwendet (0x800700AA)'
    end;
  end;

//function TPortableDeviceObject.CanWriteProperty (const PropertyKey : TPropertyKey; var CanWrite : boolean) : HResult;
function TPortableDeviceObject.CanWriteProperty (ObjectProperty : TObjectProperty) : boolean;
var
  Properties  : IPortableDeviceProperties;
  Attributes  : IPortableDeviceValues;
  cw          : bool;
begin
  Result:=false;
  if succeeded(FContent.pContent.Properties(Properties)) then begin
    if succeeded(Properties.GetPropertyAttributes(PChar(FObjectID),ObjectPropertyGuids[ObjectProperty]^,attributes)) then begin
      if succeeded(Attributes.GetBoolValue(WPD_PROPERTY_ATTRIBUTE_CAN_WRITE,cw)) then Result:=cw;
      end;
    end;
  end;

function TPortableDeviceObject.GetChildCount : integer;
begin
  if FChildCount<0 then begin
    Result:=length(FChildObjects);
    FChildCount:=Result;
    end
  else Result:=FChildCount;
  end;

function TPortableDeviceObject.GetChild (Index : integer) : TPortableDeviceObject;
begin
  if (Index>=0) and (Index<length(FChildObjects)) then Result:=FContent.Objects[FChildObjects[Index]]
  else Result:=nil;
  end;

procedure TPortableDeviceObject.AddChild (AIndex : integer);
var
  n : integer;
begin
  n:=length(FChildObjects);
  SetLength(FChildObjects,n+1);
  FChildObjects[n]:=AIndex;
  end;

function TPortableDeviceObject.GetChildByName (const AName : string) : TPortableDeviceObject;
var
  i : integer;
begin
  for i:=0 to ChildCount-1 do if AnsiSameText(Children[i].ObjectName,AName) then Break;
  if i<ChildCount then Result:=Children[i] else Result:=nil;
  end;

function TPortableDeviceObject.GetChildByOriginalName (const AName : string) : TPortableDeviceObject;
var
  i : integer;
begin
  for i:=0 to ChildCount-1 do if AnsiSameText(Children[i].OriginalName,AName) then Break;
  if i<ChildCount then Result:=Children[i] else Result:=nil;
  end;

function TPortableDeviceObject.GetObjectName : string;
var
  pv : TPropVariant;
begin
  if length(FObjectName)=0 then begin
    if succeeded(GetProperty(WPD_OBJECT_NAME,pv)) then begin
      with pv do if vt=VT_LPWSTR then Result:=pwszVal else Result:='';
      FObjectName:=Result;
      end
    else Result:='';
    PropVariantClear(pv);
    end
  else Result:=FObjectName;
  end;

function TPortableDeviceObject.GetOriginalName : string;
var
  pv : TPropVariant;
begin
  if length(FOriginalName)=0 then begin
    if succeeded(GetProperty(WPD_OBJECT_ORIGINAL_FILE_NAME,pv)) then begin
      with pv do if vt=VT_LPWSTR then Result:=pwszVal else Result:='';
      FOriginalName:=Result;
      end
    else Result:='';
    PropVariantClear(pv);
    end
  else Result:=FOriginalName;
  end;

function TPortableDeviceObject.GetParentID : string;
var
  pv : TPropVariant;
begin
  if length(FParentID)=0 then begin
    if succeeded(GetProperty(WPD_OBJECT_PARENT_ID,pv)) then begin
      with pv do if vt=VT_LPWSTR then Result:=pwszVal else Result:='';
      FParentID:=Result;
      end
    else Result:='';
    PropVariantClear(pv);
    end
  else Result:=FParentID;
  end;

function TPortableDeviceObject.GetContentGuid : TGuid;
var
  pv : TPropVariant;
begin
  if FContentType=GUID_NULL then begin
    if succeeded(GetProperty(WPD_OBJECT_CONTENT_TYPE,pv)) then begin
      with pv do if vt=VT_CLSID then Result:=puuid^ else Result:=WPD_CONTENT_TYPE_UNSPECIFIED;
      FContentType:=Result;
      end
    else Result:=WPD_CONTENT_TYPE_UNSPECIFIED;
    PropVariantClear(pv);
    end
  else Result:=FContentType;
  end;

function TPortableDeviceObject.GetLastWriteTime : TDateTime;
var
  pv : TPropVariant;
begin
  if succeeded(GetProperty(WPD_OBJECT_DATE_MODIFIED,pv)) then begin
    with pv do if vt=VT_DATE then Result:=date else Result:=Now;
    PropVariantClear(pv);
    end
  else Result:=Now;
  end;

function TPortableDeviceObject.GetCreationTime : TDateTime;
var
  pv : TPropVariant;
begin
  if succeeded(GetProperty(WPD_OBJECT_DATE_CREATED,pv)) then begin
    with pv do if vt=VT_DATE then Result:=date else Result:=Now;
    PropVariantClear(pv);
    end
  else Result:=Now;
  end;

function TPortableDeviceObject.GetSize : int64;
var
  pv : TPropVariant;
begin
  if succeeded(GetProperty(WPD_OBJECT_SIZE,pv)) then begin
    with pv do if vt=VT_UI8 then Result:=uhVal.QuadPart else Result:=0;
    PropVariantClear(pv);
    end
  else Result:=0;
  end;

function TPortableDeviceObject.GetObjecType : TObjectType;
begin
  if ContentGuid=WPD_CONTENT_TYPE_FUNCTIONAL_OBJECT then begin
    if length(ParentID)=0 then Result:=otDevice
    else Result:=otRoot;
    end
  else if ContentGuid=WPD_CONTENT_TYPE_FOLDER then Result:=otFolder
  else if GetContentTypeFromGuid(ContentGuid) in FileObjects then Result:=otFile
  else Result:=otUnknown;
  end;

function TPortableDeviceObject.GetContentType : TContentType;
begin
  Result:=GetContentTypeFromGuid(ContentGuid);
  end;

function TPortableDeviceObject.GetObjectFormat : TObjectFormat;
var
  pv : TPropVariant;
begin
  if FObjectFormat=GUID_NULL then begin
    if succeeded(GetProperty(WPD_OBJECT_FORMAT,pv)) then begin
      with pv do if vt=VT_CLSID then FObjectFormat:=puuid^ else FObjectFormat:=WPD_OBJECT_FORMAT_UNSPECIFIED;
      end
    else FObjectFormat:=WPD_OBJECT_FORMAT_UNSPECIFIED;
    PropVariantClear(pv);
    end;
  Result:=GetFormatTypeFromGuid(FObjectFormat);
  end;

function TPortableDeviceObject.GetObjectExt : string;
begin
  Result:=ObjectExtensions[ObjectFormat];
  end;

function TPortableDeviceObject.AddNameExtension (const AFilename : string) : string;
var
  sf,se : string;
begin
  Result:=AFilename;
  sf:=GetObjectExt;
  if length(sf)>0 then begin
    se:=ExtractFileExt(AFilename);
    if (length(se)=0) then Result:=AFilename+'.'+sf;
    end
  end;

function TPortableDeviceObject.GetDisplayName : string;
begin
  if ObjectType=otFile then begin
    Result:=OriginalName;
    if length(Result)=0 then Result:=ObjectName;   // use ObjectName if WPD_OBJECT_ORIGINAL_FILE_NAME property is missing
    if length(Result)=0 then Result:=ObjectID+'.data'; // if both properties are missing
    end
  else begin
    Result:=ObjectName;
    if length(Result)=0 then Result:=OriginalName; // use OriginalName if WPD_OBJECT_NAME property is missing
    if length(Result)=0 then Result:=ObjectID;     // if both properties are missing
    end;
  end;

function TPortableDeviceObject.GetPath : string;
var
  ID : string;
  obj : TPortableDeviceObject;
begin
  Result:=DisplayName; ID:=ParentID;
  while (length(ID)>0) and not AnsiSameText(ID,WPD_DEVICE_OBJECT_ID) do begin
    obj:=FContent.GetObjectByID(ID);
    if assigned(obj) then with obj do begin
      Result:=IncludeTrailingPathDelimiter(DisplayName)+Result;
      ID:=ParentID;
      end;
    end;
  end;

//-----------------------------------------------------------------------------
constructor TPortableDeviceContent.Create (const ADevice : TPortableDevice);
begin
  inherited Create;
  FDevice:=ADevice; FFindCallback:=nil;
  OleCheck(FDevice.pDevice.Content(pContent),'TPortableDeviceContent.Create:IPortableDevice.Content(');
  FObjectList:=TStringlist.Create;
  FErrorObjects:=TErrorList.Create;
  end;

destructor TPortableDeviceContent.Destroy;
begin
  FreeListObjects(FObjectList); FreeAndNil(FObjectList); FreeAndNil(FErrorObjects);
  pContent:=nil;
  inherited Destroy;
  end;

function TPortableDeviceContent.FindObjects (const AObjectID : string; AParent : TPortableDeviceObject) : boolean;
var
  hr            : HResult;
  enumObjectIDs : IEnumPortableDeviceObjectIDs;
  numFetched,i  : cardinal;
  objectIDArray : TPCharArray;
  n,nl,np       : integer;
  pdo           : TPortableDeviceObject;
const
  NumObjects = 10;
begin
  if assigned(AParent) then with AParent do begin
    np:=Index; nl:=Level+1;
    end
  else begin
    np:=-1; nl:=0;
    end;
  pdo:=TPortableDeviceObject.Create(self,AObjectID,np,nl);
  n:=FObjectList.AddObject(AObjectID,pdo);
  if assigned(FFindCallback) then FFindCallback(n,AObjectID);
  pdo.SetIndex(n);
  if assigned(AParent) then AParent.AddChild(n);
  hr:=pContent.EnumObjects(0,PWideChar(AObjectID),nil,enumObjectIDs);
  Result:=succeeded(hr);
  if Result then begin
//  OleCheck(hr,'TPortableDeviceContent.FindObjects:IPortableDeviceContent.EnumObjects (ID='+AObjectID+')');
    SetLength(objectIDArray,NumObjects);
    while hr=S_OK do begin
      hr:=enumObjectIDs.Next(NumObjects,objectIDArray[0],numFetched);
      if succeeded(hr) then begin
        if numFetched>0 then for i:=0 to numFetched-1 do if objectIDArray[i]<>nil then begin
          Result:=FindObjects(objectIDArray[i],pdo) and Result;
          CoTaskMemFree(objectIDArray[i]); objectIDArray[i]:=nil;
          end;
        end;
      end;
    objectIDArray:=nil;
//    if n=10 then FErrorObjects.AddError(AObjectID,$80042009);   // for testing
    end
  else FErrorObjects.AddError(AObjectID,hr);
//  OleCheck(hr,'TPortableDeviceContent.FindObjects:IPortableDeviceContent.Next');
  end;

function TPortableDeviceContent.Refresh (ACallBack : TFindObjects) : boolean;
begin
  FreeListObjects(FObjectList); FObjectList.Clear; FErrorObjects.Clear;
  FFindCallback:=ACallBack;
  Result:=FindObjects(WPD_DEVICE_OBJECT_ID,nil);
  FFindCallback:=nil;
  end;

function TPortableDeviceContent.GetObjectCount : integer;
begin
  Result:=FObjectList.Count;
  end;

function TPortableDeviceContent.FindNextObject (AObjectType : TObjectType;
                                                var AIndex : integer) : TPortableDeviceObject;
begin
  while (AIndex<ObjectCount) and not ((Objects[AIndex] as TPortableDeviceObject).ObjectType=AObjectType) do inc(AIndex);
  if (AIndex<ObjectCount) then Result:=Objects[AIndex] else Result:=nil;
  end;

function TPortableDeviceContent.GetRootCount : integer;
var
  nl : integer;
  pdo : TPortableDeviceObject;
begin
  nl:=0; Result:=0;
  repeat
    pdo:=FindNextObject(otRoot,nl);
    inc(nl);
    if assigned(pdo) then inc(Result);
    until not assigned(pdo);
  end;

function TPortableDeviceContent.GetFolderCount : integer;
var
  nl : integer;
  pdo : TPortableDeviceObject;
begin
  nl:=0; Result:=0;
  repeat
    pdo:=FindNextObject(otFolder,nl);
    inc(nl);
    if assigned(pdo) then inc(Result);
    until not assigned(pdo);
  end;

function TPortableDeviceContent.GetDevObject : TPortableDeviceObject;
var
  nl : integer;
begin
  nl:=0;
  Result:=FindNextObject(otDevice,nl);
  end;

function TPortableDeviceContent.GetRootObject (Index : integer) : TPortableDeviceObject;
var
  nl : integer;
begin
  nl:=0;
  repeat
    Result:=FindNextObject(otRoot,nl);
    inc(nl); dec(Index);
    until (Index<0) or not assigned(Result);
  end;

function TPortableDeviceContent.GetObject (Index : integer) : TPortableDeviceObject;
begin
  if (Index>=0) and (Index<FObjectList.Count) then
    Result:=(FObjectList.Objects[Index] as TPortableDeviceObject)
  else Result:=nil;
  end;

function TPortableDeviceContent.GetObjectByID (const AObjectID : string) : TPortableDeviceObject;
var
  n : integer;
begin
  with FObjectList do begin
    n:=IndexOf(AObjectID);
    if n>=0 then Result:=(Objects[n] as TPortableDeviceObject) else Result:=nil;
    end;
  end;

function TPortableDeviceContent.GetObjectByPath (APath : string) : TPortableDeviceObject;
var
  s : string;
  i : integer;
  pdo : TPortableDeviceObject;
begin
  Result:=nil;
  s:=ExtractFirstDir(APath);
  for i:=0 to RootCount-1 do if AnsiSameText(RootObjects[i].DisplayName,s) then Break;
  if (i<RootCount) then begin
    pdo:=RootObjects[i];
    if length(APath)>0 then begin
      repeat
        s:=ExtractFirstDir(APath);
        pdo:=pdo.GetChildByName(s);
        until (length(APath)=0) or (pdo=nil);
      end;
    Result:=pdo;
    end;
  end;

function TPortableDeviceContent.GetObjectIndexByPath(const APath : string) : integer;
var
  pdo : TPortableDeviceObject;
begin
  pdo:=GetObjectByPath(APath);
  if assigned(pdo) then Result:=pdo.Index else Result:=-1;
  end;

//-----------------------------------------------------------------------------
constructor TPortableDevice.Create (const AManager : TPortableDeviceManager; const ADeviceID : string);
begin
  inherited Create;
  FDeviceManager:=AManager; FDeviceID:=ADeviceID;
  OleCheck(CoCreateInstance(CLSID_PortableDeviceFTM,nil,CLSCTX_INPROC_SERVER,IID_IPortableDevice,pDevice),
      'TPortableDevice.Create:CoCreateInstance CLSID_PortableDeviceFTM');
  OleCheck(pDevice.Open(PChar(FDeviceID),FDeviceManager.GetClientInformation),
      'TPortableDevice.Create:IPortableDevice.Open');
  FContent:=TPortableDeviceContent.Create(self);
  OleCheck(pDevice.Capabilities(pCapabilities),'TPortableDevice.Create:IPortableDevice.Capabilities');
  FDeviceObject:=TPortableDeviceObject.Create(FContent,WPD_DEVICE_OBJECT_ID);
  end;

destructor TPortableDevice.Destroy;
begin
  FreeAndNil(FContent);
  OleCheck(pDevice.Close,'TPortableDevice.Destroy:pDevice.Close');
  pDevice:=nil;
  inherited Destroy;
  end;

function TPortableDevice.GetDeviceName : string;
var
  fnl  : DWORD;
  sBuf : array of WChar;
  pnul : PWChar;
begin
  fnl:=0; Result:=''; pnul:=nil;
  OleCheck(FDeviceManager.pDeviceManager.GetDeviceFriendlyName(pchar(FDeviceID),pnul^,fnl),
    'TPortableDevice.GetDeviceName:IDeviceManager.GetDeviceFriendlyName');
  if fnl>0 then begin
    SetLength(sBuf,fnl);
    OleCheck(FDeviceManager.pDeviceManager.GetDeviceFriendlyName(pchar(DeviceID),sbuf[0],fnl),
      'TPortableDevice.GetDeviceName:IDeviceManager.GetDeviceFriendlyName');
    Result:=pchar(@sbuf[0]);
    sBuf:=nil;
    end
  end;

function TPortableDevice.GetManufacturer : string;
var
  fnl  : DWORD;
  sBuf : array of WChar;
  pnul : PWChar;
begin
  fnl:=0; Result:=''; pnul:=nil;
  OleCheck(FDeviceManager.pDeviceManager.GetDeviceManufacturer(pchar(DeviceID),pnul^,fnl),
    'TPortableDevice.GetDeviceName:IDeviceManager.GetDeviceManufacturer');
  if fnl>0 then begin
    SetLength(sBuf,fnl);
    OleCheck(FDeviceManager.pDeviceManager.GetDeviceManufacturer(pchar(DeviceID),sbuf[0],fnl),
      'TPortableDevice.GetDeviceName:IDeviceManager.GetDeviceManufacturer');
    Result:=pchar(@sbuf[0]);
    sBuf:=nil;
    end
  end;

function TPortableDevice.GetDescription : string;
var
  fnl  : DWORD;
  sBuf : array of WChar;
  pnul : PWChar;
begin
  fnl:=0; Result:=''; pnul:=nil;
  OleCheck(FDeviceManager.pDeviceManager.GetDeviceDescription(pchar(DeviceID),pnul^,fnl),
    'TPortableDevice.GetDeviceName:IDeviceManager.GetDeviceDescription');
  if fnl>0 then begin
    SetLength(sBuf,fnl);
    OleCheck(FDeviceManager.pDeviceManager.GetDeviceDescription(pchar(DeviceID),sbuf[0],fnl),
      'TPortableDevice.GetDeviceName:IDeviceManager.GetDeviceDescription');
    Result:=pchar(@sbuf[0]);
    sBuf:=nil;
    end
  end;

function TPortableDevice.GetFirmware : string;
var
  pv : TPropVariant;
begin
  FDeviceObject.GetProperty(WPD_DEVICE_FIRMWARE_VERSION,pv);
  with pv do if (vt=VT_LPWSTR) and (pwszVal<>nil) then Result:=pwszVal else Result:='';
  PropVariantClear(pv);
  end;

function TPortableDevice.GetModel : string;
var
  pv : TPropVariant;
begin
  FDeviceObject.GetProperty(WPD_DEVICE_MODEL,pv);
  with pv do if (vt=VT_LPWSTR) and (pwszVal<>nil) then Result:=pwszVal else Result:='';
  PropVariantClear(pv);
  end;

function TPortableDevice.GetProtocol : string;
var
  pv : TPropVariant;
begin
  FDeviceObject.GetProperty(WPD_DEVICE_PROTOCOL,pv);
  with pv do if (vt=VT_LPWSTR) and (pwszVal<>nil) then Result:=pwszVal else Result:='';
  PropVariantClear(pv);
  end;

function TPortableDevice.GetPowerSource : cardinal;
var
  pv : TPropVariant;
begin
  FDeviceObject.GetProperty(WPD_DEVICE_POWER_SOURCE,pv);
  with pv do if (vt=VT_UI4) then Result:=ulVal else Result:=0;
  PropVariantClear(pv);
  end;

function TPortableDevice.GetPowerSourceAsString : string;
var
  n : cardinal;
begin
  n:=GetPowerSource;
  if (n<length(PowerSources)) then Result:=PowerSources[n] else Result:='';
  end;

function TPortableDevice.GetPowerLevel : cardinal;
var
  pv : TPropVariant;
begin
  FDeviceObject.GetProperty(WPD_DEVICE_POWER_LEVEL,pv);
  with pv do if (vt=VT_UI4) then Result:=ulVal else Result:=0;
  PropVariantClear(pv);
  end;

function TPortableDevice.GetSerialNumber : string;
var
  pv : TPropVariant;
begin
  FDeviceObject.GetProperty(WPD_DEVICE_SERIAL_NUMBER,pv);
  with pv do if (vt=VT_LPWSTR) and (pwszVal<>nil) then Result:=pwszVal else Result:='';
  PropVariantClear(pv);
  end;

function TPortableDevice.GetDeviceType : cardinal;
var
  pv : TPropVariant;
begin
  FDeviceObject.GetProperty(WPD_DEVICE_TYPE,pv);
  with pv do if (vt=VT_UI4) then Result:=ulVal else Result:=0;
  PropVariantClear(pv);
  end;

function TPortableDevice.GetDeviceTypeAsString : string;
var
  n : cardinal;
begin
  n:=GetDeviceType;
  if (n<length(DeviceTypes)) then Result:=DeviceTypes[n] else Result:='';
  end;

//-----------------------------------------------------------------------------
constructor TPortableDeviceManager.Create;
begin
  inherited Create;
  FCurrentDevice:=nil;
  FDeviceList:=TDeviceList.Create;
  Refresh;
  end;

destructor TPortableDeviceManager.Destroy;
begin
  FreeListObjects(FDeviceList);
  FreeAndNil(FDeviceList); pDeviceManager:=nil;
  inherited Destroy;
  end;

// Creates and populates an IPortableDeviceValues with information about
// this application.  The IPortableDeviceValues is used as a parameter
// when calling the IPortableDevice::Open() method.
function TPortableDeviceManager.GetClientInformation : IPortableDeviceValues;
begin
  Result:=nil;
  OleCheck(CoCreateInstance(CLSID_PortableDeviceValues,nil,CLSCTX_INPROC_SERVER,IPortableDeviceValues,Result),
    'TPortableDeviceManager.GetClientInformation:CoCreateInstance CLSID_PortableDeviceValues');
  // Attempt to set all bits of client information
  OleCheck(Result.SetStringValue(WPD_CLIENT_NAME,CLIENT_NAME),
    'TPortableDeviceManager.GetClientInformation:WPD_CLIENT_NAME');
  OleCheck(Result.SetUnsignedIntegerValue(WPD_CLIENT_MAJOR_VERSION,CLIENT_MAJOR_VER),
    'TPortableDeviceManager.GetClientInformation:WPD_CLIENT_MAJOR_VERSION');
  OleCheck(Result.SetUnsignedIntegerValue(WPD_CLIENT_MINOR_VERSION,CLIENT_MINOR_VER),
    'TPortableDeviceManager.GetClientInformation:WPD_CLIENT_MINOR_VERSION');
  OleCheck(Result.SetUnsignedIntegerValue(WPD_CLIENT_REVISION,CLIENT_REVISION),
    'TPortableDeviceManager.GetClientInformation:WPD_CLIENT_REVISION');
  //  Some device drivers need to impersonate the caller in order to function correctly.  Since our application does not
  //  need to restrict its identity, specify SECURITY_IMPERSONATION so that we work with all devices.
  OleCheck(Result.SetSignedIntegerValue(WPD_CLIENT_SECURITY_QUALITY_OF_SERVICE,SECURITY_IMPERSONATION),
    'TPortableDeviceManager.GetClientInformation:WPD_CLIENT_SECURITY_QUALITY_OF_SERVICE');
  end;


procedure TPortableDeviceManager.Refresh;
var
  DeviceIDs : TPCharArray;
  pnul : ppchar;
  i   : cardinal;

  function GetDeviceName (const DeviceID : string) : string;
  var
    fnl  : DWORD;
    sBuf : array of WChar;
    pnul : PWChar;
    hr   : HResult;
  begin
    fnl:=0; Result:=''; pnul:=nil;
    hr:=pDeviceManager.GetDeviceFriendlyName(pchar(DeviceID),pnul^,fnl);
//    OleCheck(pDeviceManager.GetDeviceFriendlyName(pchar(DeviceID),pnul^,fnl),
//      'TPortableDevice.GetDeviceName:IDeviceManager.GetDeviceFriendlyName');
    if succeeded(hr) then begin
      if fnl>0 then begin
        SetLength(sBuf,fnl);
        hr:=pDeviceManager.GetDeviceFriendlyName(pchar(DeviceID),sbuf[0],fnl);
  //      OleCheck(pDeviceManager.GetDeviceFriendlyName(pchar(DeviceID),sbuf[0],fnl),
  //        'TPortableDevice.GetDeviceName:IDeviceManager.GetDeviceFriendlyName');
        if succeeded(hr) then Result:=pchar(@sbuf[0]);
        sBuf:=nil;
        end;
      end;
    if failed(hr) then Result:='<Unknown device>';
    end;

begin
  OleCheck(CoCreateInstance(CLSID_PortableDeviceManager,nil,CLSCTX_INPROC_SERVER,IID_IPortableDeviceManager,pDeviceManager),
          'TPortableDeviceManager.Refresh: CoCreateInstance CLSID_PortableDeviceManager');
  // Pass nullptr as the PWSTR array pointer to get the total number of devices found on the system.
  pnul:=nil; FDeviceCount:=0;
  OleCheck(pDeviceManager.GetDevices(pnul^,FDeviceCount),
    'TPortableDeviceManager.Refresh:IDeviceManager.GetDevices: DeviceCount');
  SetLength(DeviceIDs,FDeviceCount);
  OleCheck(pDeviceManager.GetDevices(DeviceIDs[0],FDeviceCount),
    'TPortableDeviceManager.Refresh:IDeviceManager.GetDevices: DeviceIDs');
  // Loop through all devices
  FDeviceList.Clear;
  if FDeviceCount>0 then for i:=0 to FDeviceCount-1 do begin
    FDeviceList.AddObject(DeviceIDs[i],TDeviceData.Create(GetDeviceName(DeviceIDs[i])));
    end;
  end;

function TPortableDeviceManager.GetDevice (Index : integer) : TPortableDevice;
begin
  if Assigned(FCurrentDevice) then FreeAndNil(FCurrentDevice);
  if (Index>=0) and (Index<FDeviceList.Count) then
    FCurrentDevice:=TPortableDevice.Create(self,FDeviceList[Index]);
  Result:=FCurrentDevice;
  end;

function TPortableDeviceManager.GetDeviceByName (const DeviceName : string) : TPortableDevice;
var
  i : integer;
begin
  if Assigned(FCurrentDevice) then FreeAndNil(FCurrentDevice);
  for i:=0 to FDeviceCount-1 do with (FDeviceList.Objects[i] as TDeviceData) do begin
    if AnsiSameText(FriendlyName,DeviceName) then Break;
    end;
  if i<FDeviceCount then FCurrentDevice:=TPortableDevice.Create(self,FDeviceList[i])
  else FCurrentDevice:=nil;
  Result:=FCurrentDevice;
  end;

function TPortableDeviceManager.GetDeviceByID (const DeviceID : string) : TPortableDevice;
var
  i : integer;
begin
  if Assigned(FCurrentDevice) then FreeAndNil(FCurrentDevice);
  for i:=0 to FDeviceCount-1 do if AnsiSameText(FDeviceList[i],DeviceID) then Break;
  if i<FDeviceCount then FCurrentDevice:=TPortableDevice.Create(self,FDeviceList[i])
  else FCurrentDevice:=nil;
  Result:=FCurrentDevice;
  end;

end.

