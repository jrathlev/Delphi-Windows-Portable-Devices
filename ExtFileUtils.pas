(* Delphi Unit (Unicode)
   extensions to be used with portable devices for file and directory processing
   =============================================================================

   © Dr. J. Rathlev, D-24222 Schwentinental (kontakt(a)rathlev-home.de)

   The contents of this file may be used under the terms of the
   Mozilla Public License ("MPL") or
   GNU Lesser General Public License Version 2 or later (the "LGPL")

   Software distributed under this License is distributed on an "AS IS" basis,
   WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for
   the specific language governing rights and limitations under the License.

   Vers. 1 - June 2022

*)

unit ExtFileUtils;

interface

uses WinApi.Windows, System.Classes, System.SysUtils, IStreamApi, FileUtils;

type
  TFileStreamData = record
    FileStream: IStream;
    BufferSize: Cardinal;
    procedure Reset;
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

function GetFileData (const AFileName : string; var FileData : TFileData) : boolean;

implementation

{ ------------------------------------------------------------------- }
// Reset timestamps and file data
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
// get file size, timestamps and attributes
function GetFileData (const AFileName : string; var FileData : TFileData) : boolean;
var
  FindRec : TSearchRec;
  FindResult : integer;
begin
  Result:=false;            // does not exist
  with FileData do begin
    Reset;
    FileName:=ExtractFileName(AFileName);
    FindResult:=FindFirst(AFileName,faAnyFile,FindRec);
    if (FindResult=0) then with FindRec do begin
      TimeStamps:=GetTimestampsFromFindData(FindData);
      FileSize:=Size;
      FileAttr:=FindData.dwFileAttributes;
      Result:=true;
      end;
    FindClose(FindRec);
    end;
  end;

end.
