(* Delphi interface to selected ActiveX components
  ================================================
  Created by Delphi 10 Seattle from "PortableDeviceApi.dll"
  LIBID: {1F001332-1A57-4934-BE31-AFFC99F4EE0A}
  Notes:
    Symbol 'type' renamed to 'type_'
    Parameter 'Property' in IPortableDeviceServiceCapabilities.GetFormatPropertyAttributes changed to 'Property_'

  © Dr. J. Rathlev, D-24222 Schwentinental (kontakt(a)rathlev-home.de)

  The contents of this file may be used under the terms of the
  Mozilla Public License ("MPL") or
  GNU Lesser General Public License Version 2 or later (the "LGPL")

  Software distributed under this License is distributed on an "AS IS" basis,
  WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for
  the specific language governing rights and limitations under the License.

  The definitions in this unit replace some declarations in Winpai.ActiveX:
    ISequentialStream, IStream (see Winapi.ActiveX)
    tag_inner_PROPVARIANT by TPropVariant (see Winapi.ActiveX)

  June 2022
  *)

unit IStreamApi;

interface

uses Winapi.Windows, Winapi.ActiveX;

const
  IID_ISequentialStream: TGUID = '{0C733A30-2A1C-11CE-ADE5-00AA0044773D}';
  IID_IStream: TGUID = '{0000000C-0000-0000-C000-000000000046}';

  shlwapi32 = 'shlwapi.dll';

type
// *********************************************************************//
// Forward-Deklaration von in der Typbibliothek definierten Typen
// *********************************************************************//
  ISequentialStream = interface;
  IStream = interface;

{$ALIGN 8}
  _LARGE_INTEGER = record
    QuadPart: Int64;
  end;

  _ULARGE_INTEGER = record
    QuadPart: Largeuint;
  end;

  tagSTATSTG = record
    pwcsName: PWideChar;
    dwtype: LongWord;
    cbSize: _ULARGE_INTEGER;
    mtime: _FILETIME;
    ctime: _FILETIME;
    atime: _FILETIME;
    grfMode: LongWord;
    grfLocksSupported: LongWord;
    clsid: TGUID;
    grfStateBits: LongWord;
    reserved: LongWord;
  end;
  TStatStg = tagSTATSTG;

{$ALIGN 4}

// *********************************************************************//
// Interface: ISequentialStream
// Flags:     (0)
// GUID:      {0C733A30-2A1C-11CE-ADE5-00AA0044773D}
// *********************************************************************//
  ISequentialStream = interface(IUnknown)
    ['{0C733A30-2A1C-11CE-ADE5-00AA0044773D}']
    function Read(out pv: Byte; cb: LongWord; out pcbRead: LongWord): HResult; stdcall;
    function Write(var pv: Byte; cb: LongWord; out pcbWritten: LongWord): HResult; stdcall;
  end;

// *********************************************************************//
// Interface: IStream
// Flags:     (0)
// GUID:      {0000000C-0000-0000-C000-000000000046}
// *********************************************************************//
  IStream = interface(ISequentialStream)
    ['{0000000C-0000-0000-C000-000000000046}']
    function Seek(dlibMove: _LARGE_INTEGER; dwOrigin: LongWord;
                        out plibNewPosition: _ULARGE_INTEGER): HResult; stdcall;
    function SetSize(libNewSize: _ULARGE_INTEGER): HResult; stdcall;
    function CopyTo(pstm: IStream; cb: _ULARGE_INTEGER; out pcbRead: _ULARGE_INTEGER;
                        out pcbWritten: _ULARGE_INTEGER): HResult; stdcall;
    function Commit(grfCommitFlags: LongWord): HResult; stdcall;
    function Revert: HResult; stdcall;
    function LockRegion(libOffset: _ULARGE_INTEGER; cb: _ULARGE_INTEGER; dwLockType: LongWord): HResult; stdcall;
    function UnlockRegion(libOffset: _ULARGE_INTEGER; cb: _ULARGE_INTEGER; dwLockType: LongWord): HResult; stdcall;
    function Stat(out pstatstg: tagSTATSTG; grfStatFlag: LongWord): HResult; stdcall;
    function Clone(out ppstm: IStream): HResult; stdcall;
  end;

{ ---------------------------------------------------------------- }
function SHCreateStreamOnFileEx(pszFile: LPCWSTR; grfMode,dwAttributes: DWORD; fCreate : BOOL;
  pstmTemplate : IStream; out ppstm: IStream): HRESULT; stdcall;
{$EXTERNALSYM SHCreateStreamOnFileEx}

implementation

function SHCreateStreamOnFileEx; external shlwapi32 name 'SHCreateStreamOnFileEx';

end.
