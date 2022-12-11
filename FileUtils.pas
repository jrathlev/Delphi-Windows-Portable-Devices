(* Delphi Unit (Unicode)
   selected procedures and functions for file and directory processing
   ===================================================================
   to be used with Portable Device units

   © Dr. J. Rathlev, D-24222 Schwentinental (kontakt(a)rathlev-home.de)

   The contents of this file may be used under the terms of the
   Mozilla Public License ("MPL") or
   GNU Lesser General Public License Version 2 or later (the "LGPL")

   Software distributed under this License is distributed on an "AS IS" basis,
   WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for
   the specific language governing rights and limitations under the License.

   last modified: December 2022
   *)

unit FileUtils;

interface

uses WinApi.Windows, System.Classes, System.SysUtils, IStreamApi;

type
{ ------------------------------------------------------------------- }
  TFileStreamData = record
    FileStream: IStream;
    BufferSize: Cardinal;
    procedure Reset;
  end;

  TFileTimestamps = record
    Valid: boolean;
    CreationTime, LastAccessTime, LastWriteTime: TFileTime;
    procedure Reset;
    procedure SetTimeStamps(CTime, MTime: TDateTime);
  end;

  TFileData = record
  private
    function GetModTime: TDateTime;
    function GetCreateTime: TDateTime;
  public
    FileName,FullPath : string;
    StreamData: TFileStreamData;
    FileSize: int64;
    FileAttr: Cardinal;
    TimeStamps: TFileTimestamps;
    procedure Reset;
    property CreationTime: TDateTime read GetCreateTime;
    property ModifiedTime: TDateTime read GetModTime;
  end;

{ ---------------------------------------------------------------- }
// convert Delphi time (TDateTime) to Filetime
function FileTimeToDateTime (ft : TFileTime; var dt : TDateTime) : boolean; overload;
function FileTimeToDateTime (ft : TFileTime) : TDateTime; overload;
function FileTimeToLocalDateTime (ft : TFileTime; var dt : TDateTime) : boolean; overload;
function FileTimeToLocalDateTime (ft : TFileTime) : TDateTime; overload;

// set file or directory timestamps (UTC)
function SetFileTimestamps (const FileName: string; Timestamps : TFileTimestamps;
                            SetCreationTime : boolean) : integer;

// convert Delphi time (TDateTime) to Filetime
function DateTimeToFileTime (dt : TDateTime) : TFileTime;
function LocalDateTimeToFileTime (dt : TDateTime) : TFileTime;

{ ---------------------------------------------------------------- }
// Add a path to a filename
function AddPath (const Path,Name : string) : string;

// Check if Path is an absolute path (starting with \ or drive)
function ContainsFullPath (const Path : string) : boolean;

// Extract first subdirectory from path and remove from Path
function ExtractFirstDir (var Path : string) : string;

implementation

// -----------------------------------------------------------------------------
// Reset timestamps and file data
function ResetFileTime : TFileTime;
begin
  with Result do begin
    dwLowDateTime:=0; dwHighDateTime:=0;
    end;
  end;

procedure TFileTimestamps.Reset;
begin
  Valid:=false;
  CreationTime:=ResetFileTime;
  LastWriteTime:=ResetFileTime;
  LastAccessTime:=ResetFileTime;
  end;

procedure TFileTimestamps.SetTimeStamps(CTime, MTime: TDateTime);
begin
  Valid:=True;
  CreationTime:=LocalDateTimeToFileTime(CTime);
  LastWriteTime:=LocalDateTimeToFileTime(MTime);
  LastAccessTime:=LastWriteTime;
  end;

procedure TFileStreamData.Reset;
begin
  FileStream:=nil;
  BufferSize:=0;
  end;

procedure TFileData.Reset;
begin
  FileName:='';
  FullPath:='';
  FileSize:=0;
  FileAttr:=faArchive;
  TimeStamps.Reset;
  StreamData.Reset;
  end;

function TFileData.GetModTime: TDateTime;
begin
  Result:=FileTimeToLocalDateTime(TimeStamps.LastWriteTime);
  end;

function TFileData.GetCreateTime: TDateTime;
begin
  Result:=FileTimeToLocalDateTime(TimeStamps.CreationTime);
  end;

{ ------------------------------------------------------------------- }
// convert Filetime to Delphi time (TDateTime)
function FileTimeToDateTime (ft : TFileTime; var dt : TDateTime) : boolean;
var
  st : TSystemTime;
begin
  Result:=false;
  if not (FileTimeToSystemTime(ft,st) and TrySystemTimeToDateTime(st,dt)) then dt:=Now
  else Result:=true;
  end;

function FileTimeToDateTime (ft : TFileTime) : TDateTime; overload;
begin
  if not FileTimeToDateTime(ft,Result) then Result:=EncodeDate(1980,1,1);
  end;

function FileTimeToLocalDateTime (ft : TFileTime; var dt : TDateTime) : boolean;
var
  ftl : TFileTime;
begin
  Result:=FileTimeToLocalFileTime(ft,ftl);
  Result:=Result and FileTimeToDateTime(ftl,dt);
  end;

// convert Delphi time (TDateTime) to Filetime
function DateTimeToFileTime (dt : TDateTime) : TFileTime;
var
  st : TSystemTime;
begin
  with st do begin
    DecodeDate(dt,wYear,wMonth,wDay);
    DecodeTime(dt,wHour,wMinute,wSecond,wMilliseconds);
    end;
  SystemTimeToFileTime(st,Result);
  end;

function FileTimeToLocalDateTime (ft : TFileTime) : TDateTime; overload;
begin
  if not FileTimeToLocalDateTime (ft,Result) then Result:=EncodeDate(1980,1,1);
  end;

function LocalDateTimeToFileTime (dt : TDateTime) : TFileTime;
var
  ft : TFileTime;
begin
  ft:=DateTimeToFileTime(dt);
  LocalFileTimeToFileTime(ft,Result);
  end;

{ ---------------------------------------------------------------- }
// set file or directory timestamps (UTC)
// SetCreationTime = true:  set CreationTime and LastAccessTime
function SetFileTimestamps (const FileName: string; Timestamps : TFileTimestamps;
                            SetCreationTime : boolean) : integer;
var
  Handle   : THandle;
  tm       : TFiletime;
  ok       : boolean;
begin
  tm:=DateTimeToFileTime(Now);
  with Timestamps do if not Valid then begin
    CreationTime:=tm; LastAccessTime:=tm; LastWriteTime:=tm;
    end;
  Handle:=CreateFile(PChar(FileName),FILE_WRITE_ATTRIBUTES,0,nil,OPEN_EXISTING,FILE_FLAG_BACKUP_SEMANTICS,0);
  if Handle=THandle(-1) then Result:=GetLastError
  else with Timestamps do begin
    if SetCreationTime then ok:=SetFileTime(Handle,@CreationTime,@LastAccessTime,@LastWriteTime)
    else ok:=SetFileTime(Handle,nil,nil,@LastWriteTime);
    if ok then Result:=NO_ERROR else Result:=GetLastError;
    FileClose(Handle);
    end;
  end;

{ --------------------------------------------------------------- }
// Add a path to a filename
function AddPath (const Path,Name : string) : string;
begin
  if length(Name)>0 then begin
    if length(Path)>0 then Result:=IncludeTrailingPathDelimiter(Path)+Name else Result:=Name;
    end
  else Result:=Path;
  end;

// Check if Path is an absolute path (starting with \ or drive)
function ContainsFullPath (const Path : string) : boolean;
begin
  if length(Path)>0 then Result:=(Path[1]=PathDelim) or (pos('.',Path)>0)
  else Result:=false;
  end;

// Extract first subdirectory from path and remove from Path
function ExtractFirstDir (var Path : string) : string;
var
  n : integer;
begin
  Result:='';
  if not ContainsFullPath(Path) then begin
    n:=Pos(PathDelim,Path);
    if n>0 then begin
      Result:=copy(Path,1,n-1); delete(Path,1,n);
      end
    else begin
      Result:=Path; Path:='';
      end;
    end;
  end;


end.
