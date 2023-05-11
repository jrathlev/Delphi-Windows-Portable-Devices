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

uses WinApi.Windows, System.Classes, System.SysUtils;

type
  TFileTimestamps = record
    Valid: boolean;
    CreationTime, LastAccessTime, LastWriteTime: TFileTime;
    procedure Reset;
    procedure SetTimeStamps(CTime, MTime: TDateTime);
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

// get file or directory timestamps (UTC) from FindData
function GetTimestampsFromFindData(const FindData : TWin32FindData) : TFileTimestamps;

// convert Delphi time (TDateTime) to Filetime
function DateTimeToFileTime (dt : TDateTime) : TFileTime;
function LocalDateTimeToFileTime (dt : TDateTime) : TFileTime;

implementation

{ ------------------------------------------------------------------- }
function ResetFileTime : TFileTime;
begin
  with Result do begin
    dwLowDateTime:=0; dwHighDateTime:=0;
    end;
  end;

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
// get file or directory timestamps (UTC) from FindData
function GetTimestampsFromFindData(const FindData : TWin32FindData) : TFileTimestamps;
begin
  with Result do begin
    CreationTime:=FindData.ftCreationTime;
    LastAccessTime:=FindData.ftLastAccessTime;
    LastWriteTime:=FindData.ftLastWriteTime;
    Valid:=true;
    end;
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

// -----------------------------------------------------------------------------
// Reset timestamps and file data
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

end.
