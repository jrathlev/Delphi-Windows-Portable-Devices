(* Delphi interface to Windows Portable Devices
  =============================================
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

  manual changes by J. Rathlev
  removed:  _tagpropertykey record (using the definition in Winapi.ActiveX)
  added:    IPortableDevicePropertiesBulk
            IPortableDevicePropertiesBulkCallback
            IPortableDeviceDataStream
            several CLSID definitions
            function SHCreateStreamOnFileEx
  fixed:    IPortableDeviceManager functions return WChar not Word
            IPortableDeviceDataStream interface inherits from IStream
            IPortableDeviceValues boolean values
  replaced: ISequentialStream, IStream (see Winapi.ActiveX)
            tag_inner_PROPVARIANT by TPropVariant (see Winapi.ActiveX)
            all Guids and keys: "var" replaced by "const"

  April 2022
  *)

unit PortableDeviceApi;

{$TYPEDADDRESS OFF} // Unit muss ohne Typüberprüfung für Zeiger compiliert werden.
{$WARN SYMBOL_PLATFORM OFF}
{$WRITEABLECONST ON}
{$VARPROPSETTER ON}
{$ALIGN 4}

interface

uses Winapi.Windows, Winapi.ActiveX, IStreamApi;

// *********************************************************************//
// In der Typbibliothek deklarierte GUIDS. Die folgenden Präfixe werden verwendet:        
//   Typbibliotheken      : LIBID_xxxx
//   CoClasses            : CLASS_xxxx / CLSID:xxxx
//   DISPInterfaces       : DIID_xxxx                                       
//   Nicht-DISP-Interfaces: IID_xxxx                                        
// *********************************************************************//
const
  // Haupt- und Nebenversionen der Typbibliothek
  PortableDeviceApiLibMajorVersion = 1;
  PortableDeviceApiLibMinorVersion = 0;

  LIBID_PortableDeviceApiLib: TGUID = '{1F001332-1A57-4934-BE31-AFFC99F4EE0A}';

  IID_IPortableDevice: TGUID = '{625E2DF8-6392-4CF0-9AD1-3CFA5F17775C}';
  CLASS_PortableDevice: TGUID = '{728A21C5-3D9E-48D7-9810-864848F0F404}';
  IID_IPortableDeviceValues: TGUID = '{6848F6F2-3155-4F86-B6F5-263EEEAB3143}';
  IID_IStorage: TGUID = '{0000000B-0000-0000-C000-000000000046}';
  IID_IEnumSTATSTG: TGUID = '{0000000D-0000-0000-C000-000000000046}';
  IID_IRecordInfo: TGUID = '{0000002F-0000-0000-C000-000000000046}';
  IID_ITypeInfo: TGUID = '{00020401-0000-0000-C000-000000000046}';
  IID_ITypeComp: TGUID = '{00020403-0000-0000-C000-000000000046}';
  IID_ITypeLib: TGUID = '{00020402-0000-0000-C000-000000000046}';
  IID_IPortableDevicePropVariantCollection: TGUID = '{89B2E422-4F1B-4316-BCEF-A44AFEA83EB3}';
  IID_IPortableDeviceKeyCollection: TGUID = '{DADA2357-E0AD-492E-98DB-DD61C53BA353}';
  IID_IPortableDeviceValuesCollection: TGUID = '{6E3F2D79-4E07-48C4-8208-D8C2E5AF4A99}';
  IID_IPropertyStore: TGUID = '{886D8EEB-8CF2-4446-8D02-CDBA1DBDCF99}';
  IID_IPortableDeviceContent: TGUID = '{6A96ED84-7C73-4480-9938-BF5AF477D426}';
  IID_IEnumPortableDeviceObjectIDs: TGUID = '{10ECE955-CF41-4728-BFA0-41EEDF1BBF19}';
  IID_IPortableDeviceProperties: TGUID = '{7F6D695C-03DF-4439-A809-59266BEEE3A6}';
  IID_IPortableDeviceResources: TGUID = '{FD8878AC-D841-4D17-891C-E6829CDB6934}';
  IID_IPortableDeviceCapabilities: TGUID = '{2C8C6DBF-E3DC-4061-BECC-8542E810D126}';
  IID_IPortableDeviceEventCallback: TGUID = '{A8792A31-F385-493C-A893-40F64EB45F6E}';
  IID_IPortableDeviceManager: TGUID = '{A1567595-4C2F-4574-A6FA-ECEF917B9A40}';
  CLASS_PortableDeviceManager: TGUID = '{0AF10CEC-2ECD-4B92-9581-34F6AE0637F3}';
  IID_IPortableDeviceService: TGUID = '{D3BD3A44-D7B5-40A9-98B7-2FA4D01DEC08}';
  CLASS_PortableDeviceService: TGUID = '{EF5DB4C2-9312-422C-9152-411CD9C4DD84}';
  IID_IPortableDeviceServiceCapabilities: TGUID = '{24DBD89D-413E-43E0-BD5B-197F3C56C886}';
  IID_IPortableDeviceContent2: TGUID = '{9B4ADD96-F6BF-4034-8708-ECA72BF10554}';
  IID_IPortableDeviceServiceMethods: TGUID = '{E20333C9-FD34-412D-A381-CC6F2D820DF7}';
  IID_IPortableDeviceServiceMethodCallback: TGUID = '{C424233C-AFCE-4828-A756-7ED7A2350083}';
  IID_IPortableDeviceDispatchFactory: TGUID = '{5E1EAFC3-E3D7-4132-96FA-759C0F9D1E0F}';
  CLASS_PortableDeviceDispatchFactory: TGUID = '{43232233-8338-4658-AE01-0B4AE830B6B0}';
  CLASS_PortableDeviceFTM: TGUID = '{F7C0039A-4762-488A-B4B3-760EF9A1BA9B}';
  CLASS_PortableDeviceServiceFTM: TGUID = '{1649B154-C794-497A-9B03-F3F0121302F3}';
  IID_IPortableDeviceWebControl: TGUID = '{94FC7953-5CA1-483A-8AEE-DF52E7747D00}';
  CLASS_PortableDeviceWebControl: TGUID = '{186DD02C-2DEC-41B5-A7D4-B59056FADE51}';
  IID_IPortableDevicePropertiesBulk: TGUID = '{482b05c0-4056-44ed-9e0f-5e23b009da93}';
  IID_IPortableDevicePropertiesBulkCallback: TGUID = '{9deacb80-11e8-40e3-a9f3-f557986a7845}';
  IID_IPortableDeviceDataStream: TGUID = '{88e04db3-1012-4d64-9996-f703a950d3f4}';

  CLSID_PortableDevice: TGUID = '{728A21C5-3D9E-48D7-9810-864848F0F404}';
  CLSID_PortableDeviceManager: TGUID = '{0AF10CEC-2ECD-4B92-9581-34F6AE0637F3}';
  CLSID_PortableDeviceService: TGUID = '{EF5DB4C2-9312-422C-9152-411CD9C4DD84}';
  CLSID_PortableDeviceDispatchFactory: TGUID = '{43232233-8338-4658-AE01-0B4AE830B6B0}';
  CLSID_PortableDeviceFTM: TGUID = '{F7C0039A-4762-488A-B4B3-760EF9A1BA9B}';
  CLSID_PortableDeviceServiceFTM: TGUID = '{1649B154-C794-497A-9B03-F3F0121302F3}';
  CLSID_PortableDeviceWebControl: TGUID = '{186DD02C-2DEC-41B5-A7D4-B59056FADE51}';
  CLSID_PortableDeviceValues: TGUID = '{0C15D503-D017-47CE-9016-7B3F978721CC}';
  CLSID_PortableDeviceKeyCollection: TGUID = '{DE2D022D-2480-43BE-97F0-D1FA2CF98F4F}';
  CLSID_PortableDevicePropVariantCollection: TGUID = '{08A99E2F-6D6D-4B80-AF5A-BAF2BCBE4CB9}';
  CLSID_PortableDeviceValuesCollection: TGUID = '{3882134D-14CF-4220-9CB4-435F86D83F60}';
  CLSID_WpdSerializer: TGUID = '{0B91A74B-AD7C-4A9D-B563-29EEF9167172}';
    
// *********************************************************************//
// Deklaration von in der Typbibliothek definierten Aufzählungen                     
// *********************************************************************//
// Konstanten für enum tagTYPEKIND
type
  tagTYPEKIND = TOleEnum;
const
  TKIND_ENUM = $00000000;
  TKIND_RECORD = $00000001;
  TKIND_MODULE = $00000002;
  TKIND_INTERFACE = $00000003;
  TKIND_DISPATCH = $00000004;
  TKIND_COCLASS = $00000005;
  TKIND_ALIAS = $00000006;
  TKIND_UNION = $00000007;
  TKIND_MAX = $00000008;

// Konstanten für enum tagDESCKIND
type
  tagDESCKIND = TOleEnum;
const
  DESCKIND_NONE = $00000000;
  DESCKIND_FUNCDESC = $00000001;
  DESCKIND_VARDESC = $00000002;
  DESCKIND_TYPECOMP = $00000003;
  DESCKIND_IMPLICITAPPOBJ = $00000004;
  DESCKIND_MAX = $00000005;

// Konstanten für enum tagFUNCKIND
type
  tagFUNCKIND = TOleEnum;
const
  FUNC_VIRTUAL = $00000000;
  FUNC_PUREVIRTUAL = $00000001;
  FUNC_NONVIRTUAL = $00000002;
  FUNC_STATIC = $00000003;
  FUNC_DISPATCH = $00000004;

// Konstanten für enum tagINVOKEKIND
type
  tagINVOKEKIND = TOleEnum;
const
  INVOKE_FUNC = $00000001;
  INVOKE_PROPERTYGET = $00000002;
  INVOKE_PROPERTYPUT = $00000004;
  INVOKE_PROPERTYPUTREF = $00000008;

// Konstanten für enum tagCALLCONV
type
  tagCALLCONV = TOleEnum;
const
  CC_FASTCALL = $00000000;
  CC_CDECL = $00000001;
  CC_MSCPASCAL = $00000002;
  CC_PASCAL = $00000002;
  CC_MACPASCAL = $00000003;
  CC_STDCALL = $00000004;
  CC_FPFASTCALL = $00000005;
  CC_SYSCALL = $00000006;
  CC_MPWCDECL = $00000007;
  CC_MPWPASCAL = $00000008;
  CC_MAX = $00000009;

// Konstanten für enum tagVARKIND
type
  tagVARKIND = TOleEnum;
const
  VAR_PERINSTANCE = $00000000;
  VAR_STATIC = $00000001;
  VAR_CONST = $00000002;
  VAR_DISPATCH = $00000003;

// Konstanten für enum tagSYSKIND
type
  tagSYSKIND = TOleEnum;
const
  SYS_WIN16 = $00000000;
  SYS_WIN32 = $00000001;
  SYS_MAC = $00000002;
  SYS_WIN64 = $00000003;

type
// *********************************************************************//
// Forward-Deklaration von in der Typbibliothek definierten Typen
// *********************************************************************//
  IPortableDevice = interface;
  IPortableDeviceValues = interface;
  IStorage = interface;
  IEnumSTATSTG = interface;
  IRecordInfo = interface;
  ITypeInfo = interface;
  ITypeComp = interface;
  ITypeLib = interface;
  IPortableDevicePropVariantCollection = interface;
  IPortableDeviceKeyCollection = interface;
  IPortableDeviceValuesCollection = interface;
  IPropertyStore = interface;
  IPortableDeviceContent = interface;
  IEnumPortableDeviceObjectIDs = interface;
  IPortableDeviceProperties = interface;
  IPortableDeviceResources = interface;
  IPortableDeviceCapabilities = interface;
  IPortableDeviceEventCallback = interface;
  IPortableDeviceManager = interface;
  IPortableDeviceService = interface;
  IPortableDeviceServiceCapabilities = interface;
  IPortableDeviceContent2 = interface;
  IPortableDeviceServiceMethods = interface;
  IPortableDeviceServiceMethodCallback = interface;
  IPortableDeviceDispatchFactory = interface;
  IPortableDeviceWebControl = interface;
  IPortableDeviceWebControlDisp = dispinterface;
  IPortableDevicePropertiesBulk = interface;
  IPortableDevicePropertiesBulkCallback = interface;
  IPortableDeviceDataStream = interface;

// *********************************************************************//
// Deklaration von in der Typbibliothek definierten CoClasses
// (HINWEIS: Hier wird jede CoClass ihrem Standard-Interface zugewiesen)              
// *********************************************************************//
  PortableDevice = IPortableDevice;
  PortableDeviceManager = IPortableDeviceManager;
  PortableDeviceService = IPortableDeviceService;
  PortableDeviceDispatchFactory = IPortableDeviceDispatchFactory;
  PortableDeviceFTM = IPortableDevice;
  PortableDeviceServiceFTM = IPortableDeviceService;
  PortableDeviceWebControl = IPortableDeviceWebControl;


// *********************************************************************//
// Deklaration von Strukturen, Unions und Aliasen.                          
// *********************************************************************//
  wirePSAFEARRAY = ^PUserType5; 
  wireSNB = ^tagRemSNB; 
  PUserType6 = ^_FLAGGED_WORD_BLOB; {*}
  PUserType7 = ^_wireVARIANT; {*}
  PUserType14 = ^_wireBRECORD; {*}
  PUserType5 = ^_wireSAFEARRAY; {*}
  PPUserType1 = ^PUserType5; {*}
  PUserType11 = ^tagTYPEDESC; {*}
  PUserType12 = ^tagARRAYDESC; {*}
  PUserType2 = ^tag_inner_PROPVARIANT; {*}
  PUINT1 = ^LongWord; {*}
  PUserType1 = ^_tagpropertykey; {*}
  PUserType3 = ^TGUID; {*}
  PByte1 = ^Byte; {*}
  PUserType4 = ^_FILETIME; {*}
  POleVariant1 = ^OleVariant; {*}
  PUserType8 = ^tagTYPEATTR; {*}
  PUserType9 = ^tagFUNCDESC; {*}
  PUserType10 = ^tagVARDESC; {*}
  PUserType13 = ^tagTLIBATTR; {*}

//  _tagpropertykey = record
//    fmtid: TGUID;
//    pid: LongWord;
//  end;
//  TTagPropertyKey = _tagpropertykey;

//  _FILETIME = record
//    dwLowDateTime: LongWord;
//    dwHighDateTime: LongWord;
//  end;

  tagCLIPDATA = record
    cbSize: LongWord;
    ulClipFmt: Integer;
    pClipData: ^Byte;
  end;

  tagBSTRBLOB = record
    cbSize: LongWord;
    pData: ^Byte;
  end;

  tagBLOB = record
    cbSize: LongWord;
    pBlobData: ^Byte;
  end;

  tagVersionedStream = record
    guidVersion: TGUID;
    pStream: IStream;
  end;

  tagRemSNB = record
    ulCntStr: LongWord;
    ulCntChar: LongWord;
    rgString: ^Word;
  end;

  tagCAC = record
    cElems: LongWord;
    pElems: ^Shortint;
  end;

  tagCAUB = record
    cElems: LongWord;
    pElems: ^Byte;
  end;

  _wireSAFEARR_BSTR = record
    Size: LongWord;
    aBstr: ^PUserType6;
  end;

  _wireSAFEARR_UNKNOWN = record
    Size: LongWord;
    apUnknown: ^IUnknown;
  end;

  _wireSAFEARR_DISPATCH = record
    Size: LongWord;
    apDispatch: ^IDispatch;
  end;

  _FLAGGED_WORD_BLOB = record
    fFlags: LongWord;
    clSize: LongWord;
    asData: ^Word;
  end;


  _wireSAFEARR_VARIANT = record
    Size: LongWord;
    aVariant: ^PUserType7;
  end;


  _wireBRECORD = record
    fFlags: LongWord;
    clSize: LongWord;
    pRecInfo: IRecordInfo;
    pRecord: ^Byte;
  end;


  __MIDL_IOleAutomationTypes_0005 = record
    case Integer of
      0: (lptdesc: PUserType11);
      1: (lpadesc: PUserType12);
      2: (hreftype: LongWord);
  end;

  tagTYPEDESC = record
    DUMMYUNIONNAME: __MIDL_IOleAutomationTypes_0005;
    vt: Word;
  end;

  tagSAFEARRAYBOUND = record
    cElements: LongWord;
    lLbound: Integer;
  end;

  ULONG_PTR = LongWord;

  tagIDLDESC = record
    dwReserved: ULONG_PTR;
    wIDLFlags: Word;
  end;

  DWORD = LongWord; 

{$ALIGN 8}
  tagPARAMDESCEX = record
    cBytes: LongWord;
    varDefaultValue: OleVariant;
  end;

{$ALIGN 4}
  tagPARAMDESC = record
    pparamdescex: ^tagPARAMDESCEX;
    wParamFlags: Word;
  end;

  tagELEMDESC = record
    tdesc: tagTYPEDESC;
    paramdesc: tagPARAMDESC;
  end;

  tagFUNCDESC = record
    memid: Integer;
    lprgscode: ^SCODE;
    lprgelemdescParam: ^tagELEMDESC;
    funckind: tagFUNCKIND;
    invkind: tagINVOKEKIND;
    callconv: tagCALLCONV;
    cParams: Smallint;
    cParamsOpt: Smallint;
    oVft: Smallint;
    cScodes: Smallint;
    elemdescFunc: tagELEMDESC;
    wFuncFlags: Word;
  end;

  __MIDL_IOleAutomationTypes_0006 = record
    case Integer of
      0: (oInst: LongWord);
      1: (lpvarValue: ^OleVariant);
  end;

  tagVARDESC = record
    memid: Integer;
    lpstrSchema: PWideChar;
    DUMMYUNIONNAME: __MIDL_IOleAutomationTypes_0006;
    elemdescVar: tagELEMDESC;
    wVarFlags: Word;
    varkind: tagVARKIND;
  end;

  tagTLIBATTR = record
    guid: TGUID;
    lcid: LongWord;
    syskind: tagSYSKIND;
    wMajorVerNum: Word;
    wMinorVerNum: Word;
    wLibFlags: Word;
  end;

  _wireSAFEARR_BRECORD = record
    Size: LongWord;
    aRecord: ^PUserType14;
  end;

  _wireSAFEARR_HAVEIID = record
    Size: LongWord;
    apUnknown: ^IUnknown;
    iid: TGUID;
  end;

  _BYTE_SIZEDARR = record
    clSize: LongWord;
    pData: ^Byte;
  end;

  _SHORT_SIZEDARR = record
    clSize: LongWord;
    pData: ^Word;
  end;

  _LONG_SIZEDARR = record
    clSize: LongWord;
    pData: ^LongWord;
  end;

  _HYPER_SIZEDARR = record
    clSize: LongWord;
    pData: ^Int64;
  end;

  tagCAI = record
    cElems: LongWord;
    pElems: ^Smallint;
  end;

  tagCAUI = record
    cElems: LongWord;
    pElems: ^Word;
  end;

  tagCAL = record
    cElems: LongWord;
    pElems: ^Integer;
  end;

  tagCAUL = record
    cElems: LongWord;
    pElems: ^LongWord;
  end;

  tagCAH = record
    cElems: LongWord;
    pElems: ^_LARGE_INTEGER;
  end;

  tagCAUH = record
    cElems: LongWord;
    pElems: ^_ULARGE_INTEGER;
  end;

  tagCAFLT = record
    cElems: LongWord;
    pElems: ^Single;
  end;

  tagCADBL = record
    cElems: LongWord;
    pElems: ^Double;
  end;

  tagCABOOL = record
    cElems: LongWord;
    pElems: ^WordBool;
  end;

  tagCASCODE = record
    cElems: LongWord;
    pElems: ^SCODE;
  end;

  tagCACY = record
    cElems: LongWord;
    pElems: ^Currency;
  end;

  tagCADATE = record
    cElems: LongWord;
    pElems: ^TDateTime;
  end;

  tagCAFILETIME = record
    cElems: LongWord;
    pElems: ^_FILETIME;
  end;

  tagCACLSID = record
    cElems: LongWord;
    pElems: ^TGUID;
  end;

  tagCACLIPDATA = record
    cElems: LongWord;
    pElems: ^tagCLIPDATA;
  end;

  tagCABSTR = record
    cElems: LongWord;
    pElems: ^WideString;
  end;

  tagCABSTRBLOB = record
    cElems: LongWord;
    pElems: ^tagBSTRBLOB;
  end;

  tagCALPSTR = record
    cElems: LongWord;
    pElems: ^PAnsiChar;
  end;

  tagCALPWSTR = record
    cElems: LongWord;
    pElems: ^PWideChar;
  end;


  tagCAPROPVARIANT = record
    cElems: LongWord;
    pElems: PUserType2;
  end;

{$ALIGN 8}
  __MIDL___MIDL_itf_PortableDeviceApi_0001_0000_0001 = record
    case Integer of
      0: (cVal: Shortint);
      1: (bVal: Byte);
      2: (iVal: Smallint);
      3: (uiVal: Word);
      4: (lVal: Integer);
      5: (ulVal: LongWord);
      6: (intVal: SYSINT);
      7: (uintVal: SYSUINT);
      8: (hVal: _LARGE_INTEGER);
      9: (uhVal: _ULARGE_INTEGER);
      10: (fltVal: Single);
      11: (dblVal: Double);
      12: (boolVal: WordBool);
      13: (__OBSOLETE__VARIANT_BOOL: WordBool);
      14: (scode: SCODE);
      15: (cyVal: Currency);
      16: (date: TDateTime);
      17: (filetime: _FILETIME);
      18: (puuid: ^TGUID);
      19: (pClipData: ^tagCLIPDATA);
      20: (bstrVal: {NOT_UNION(WideString)}Pointer);
      21: (bstrblobVal: tagBSTRBLOB);
      22: (blob: tagBLOB);
      23: (pszVal: PAnsiChar);
      24: (pwszVal: PWideChar);
      25: (punkVal: {NOT_UNION(IUnknown)}Pointer);
      26: (pdispVal: {NOT_UNION(IDispatch)}Pointer);
      27: (pStream: {NOT_UNION(IStream)}Pointer);
      28: (pStorage: {NOT_UNION(IStorage)}Pointer);
      29: (pVersionedStream: ^tagVersionedStream);
      30: (parray: wirePSAFEARRAY);
      31: (cac: tagCAC);
      32: (caub: tagCAUB);
      33: (cai: tagCAI);
      34: (caui: tagCAUI);
      35: (cal: tagCAL);
      36: (caul: tagCAUL);
      37: (cah: tagCAH);
      38: (cauh: tagCAUH);
      39: (caflt: tagCAFLT);
      40: (cadbl: tagCADBL);
      41: (cabool: tagCABOOL);
      42: (cascode: tagCASCODE);
      43: (cacy: tagCACY);
      44: (cadate: tagCADATE);
      45: (cafiletime: tagCAFILETIME);
      46: (cauuid: tagCACLSID);
      47: (caclipdata: tagCACLIPDATA);
      48: (cabstr: tagCABSTR);
      49: (cabstrblob: tagCABSTRBLOB);
      50: (calpstr: tagCALPSTR);
      51: (calpwstr: tagCALPWSTR);
      52: (capropvar: tagCAPROPVARIANT);
      53: (pcVal: ^Shortint);
      54: (pbVal: ^Byte);
      55: (piVal: ^Smallint);
      56: (puiVal: ^Word);
      57: (plVal: ^Integer);
      58: (pulVal: ^LongWord);
      59: (pintVal: ^SYSINT);
      60: (puintVal: ^SYSUINT);
      61: (pfltVal: ^Single);
      62: (pdblVal: ^Double);
      63: (pboolVal: ^WordBool);
      64: (pdecVal: ^TDecimal);
      65: (pscode: ^SCODE);
      66: (pcyVal: ^Currency);
      67: (pdate: ^TDateTime);
      68: (pbstrVal: ^WideString);
      69: (ppunkVal: {NOT_UNION(^IUnknown)}Pointer);
      70: (ppdispVal: {NOT_UNION(^IDispatch)}Pointer);
      71: (pparray: ^wirePSAFEARRAY);
      72: (pvarVal: PUserType2);
  end;


  tag_inner_PROPVARIANT = record
    vt: Word;
    wReserved1: Byte;
    wReserved2: Byte;
    wReserved3: LongWord;
    __MIDL____MIDL_itf_PortableDeviceApi_0001_00000001: __MIDL___MIDL_itf_PortableDeviceApi_0001_0000_0001;
  end;
  TTagInnerPROPVARIANT = tag_inner_PROPVARIANT;

  __MIDL_IOleAutomationTypes_0004 = record
    case Integer of
      0: (llVal: Int64);
      1: (lVal: Integer);
      2: (bVal: Byte);
      3: (iVal: Smallint);
      4: (fltVal: Single);
      5: (dblVal: Double);
      6: (boolVal: WordBool);
      7: (scode: SCODE);
      8: (cyVal: Currency);
      9: (date: TDateTime);
      10: (bstrVal: ^_FLAGGED_WORD_BLOB);
      11: (punkVal: {NOT_UNION(IUnknown)}Pointer);
      12: (pdispVal: {NOT_UNION(IDispatch)}Pointer);
      13: (parray: ^PUserType5);
      14: (brecVal: ^_wireBRECORD);
      15: (pbVal: ^Byte);
      16: (piVal: ^Smallint);
      17: (plVal: ^Integer);
      18: (pllVal: ^Int64);
      19: (pfltVal: ^Single);
      20: (pdblVal: ^Double);
      21: (pboolVal: ^WordBool);
      22: (pscode: ^SCODE);
      23: (pcyVal: ^Currency);
      24: (pdate: ^TDateTime);
      25: (pbstrVal: ^PUserType6);
      26: (ppunkVal: {NOT_UNION(^IUnknown)}Pointer);
      27: (ppdispVal: {NOT_UNION(^IDispatch)}Pointer);
      28: (pparray: ^PPUserType1);
      29: (pvarVal: ^PUserType7);
      30: (cVal: Shortint);
      31: (uiVal: Word);
      32: (ulVal: LongWord);
      33: (ullVal: Largeuint);
      34: (intVal: SYSINT);
      35: (uintVal: SYSUINT);
      36: (decVal: TDecimal);
      37: (pdecVal: ^TDecimal);
      38: (pcVal: ^Shortint);
      39: (puiVal: ^Word);
      40: (pulVal: ^LongWord);
      41: (pullVal: ^Largeuint);
      42: (pintVal: ^SYSINT);
      43: (puintVal: ^SYSUINT);
  end;

{$ALIGN 4}
  __MIDL_IOleAutomationTypes_0001 = record
    case Integer of
      0: (BstrStr: _wireSAFEARR_BSTR);
      1: (UnknownStr: _wireSAFEARR_UNKNOWN);
      2: (DispatchStr: _wireSAFEARR_DISPATCH);
      3: (VariantStr: _wireSAFEARR_VARIANT);
      4: (RecordStr: _wireSAFEARR_BRECORD);
      5: (HaveIidStr: _wireSAFEARR_HAVEIID);
      6: (ByteStr: _BYTE_SIZEDARR);
      7: (WordStr: _SHORT_SIZEDARR);
      8: (LongStr: _LONG_SIZEDARR);
      9: (HyperStr: _HYPER_SIZEDARR);
  end;

  _wireSAFEARRAY_UNION = record
    sfType: LongWord;
    u: __MIDL_IOleAutomationTypes_0001;
  end;

{$ALIGN 8}
  _wireVARIANT = record
    clSize: LongWord;
    rpcReserved: LongWord;
    vt: Word;
    wReserved1: Word;
    wReserved2: Word;
    wReserved3: Word;
    DUMMYUNIONNAME: __MIDL_IOleAutomationTypes_0004;
  end;


{$ALIGN 4}
  tagTYPEATTR = record
    guid: TGUID;
    lcid: LongWord;
    dwReserved: LongWord;
    memidConstructor: Integer;
    memidDestructor: Integer;
    lpstrSchema: PWideChar;
    cbSizeInstance: LongWord;
    typekind: tagTYPEKIND;
    cFuncs: Word;
    cVars: Word;
    cImplTypes: Word;
    cbSizeVft: Word;
    cbAlignment: Word;
    wTypeFlags: Word;
    wMajorVerNum: Word;
    wMinorVerNum: Word;
    tdescAlias: tagTYPEDESC;
    idldescType: tagIDLDESC;
  end;

  tagARRAYDESC = record
    tdescElem: tagTYPEDESC;
    cDims: Word;
    rgbounds: ^tagSAFEARRAYBOUND;
  end;


  _wireSAFEARRAY = record
    cDims: Word;
    fFeatures: Word;
    cbElements: LongWord;
    cLocks: LongWord;
    uArrayStructs: _wireSAFEARRAY_UNION;
    rgsabound: ^tagSAFEARRAYBOUND;
  end;

// *********************************************************************//
// Interface: IPortableDevice
// Flags:     (0)
// GUID:      {625E2DF8-6392-4CF0-9AD1-3CFA5F17775C}
// *********************************************************************//
  IPortableDevice = interface(IUnknown)
    ['{625E2DF8-6392-4CF0-9AD1-3CFA5F17775C}']
    function Open(pszPnPDeviceID: PWideChar; const pClientInfo: IPortableDeviceValues): HResult; stdcall;
    function SendCommand(dwFlags: LongWord; const pParameters: IPortableDeviceValues; 
                         out ppResults: IPortableDeviceValues): HResult; stdcall;
    function Content(out ppContent: IPortableDeviceContent): HResult; stdcall;
    function Capabilities(out ppCapabilities: IPortableDeviceCapabilities): HResult; stdcall;
    function Cancel: HResult; stdcall;
    function Close: HResult; stdcall;
    function Advise(dwFlags: LongWord; const pCallback: IPortableDeviceEventCallback; 
                    const pParameters: IPortableDeviceValues; out ppszCookie: PWideChar): HResult; stdcall;
    function Unadvise(pszCookie: PWideChar): HResult; stdcall;
    function GetPnPDeviceID(out ppszPnPDeviceID: PWideChar): HResult; stdcall;
  end;

// *********************************************************************//
// Interface: IPortableDeviceValues
// Flags:     (0)
// GUID:      {6848F6F2-3155-4F86-B6F5-263EEEAB3143}
// *********************************************************************//
  IPortableDeviceValues = interface(IUnknown)
    ['{6848F6F2-3155-4F86-B6F5-263EEEAB3143}']
    function GetCount(var pcelt: LongWord): HResult; stdcall;
    function GetAt(index: LongWord; var pKey: TPropertyKey; var pValue: TPropVariant): HResult; stdcall;
    function SetValue(const key: TPropertyKey; const pValue: TPropVariant): HResult; stdcall;
    function GetValue(const key: TPropertyKey; out pValue: TPropVariant): HResult; stdcall;
    function SetStringValue(const key: TPropertyKey; Value: PWideChar): HResult; stdcall;
    function GetStringValue(const key: TPropertyKey; out pValue: PWideChar): HResult; stdcall;
    function SetUnsignedIntegerValue(const key: TPropertyKey; Value: LongWord): HResult; stdcall;
    function GetUnsignedIntegerValue(const key: TPropertyKey; out pValue: LongWord): HResult; stdcall;
    function SetSignedIntegerValue(const key: TPropertyKey; Value: Integer): HResult; stdcall;
    function GetSignedIntegerValue(const key: TPropertyKey; out pValue: Integer): HResult; stdcall;
    function SetUnsignedLargeIntegerValue(const key: TPropertyKey; Value: Largeuint): HResult; stdcall;
    function GetUnsignedLargeIntegerValue(const key: TPropertyKey; out pValue: Largeuint): HResult; stdcall;
    function SetSignedLargeIntegerValue(const key: TPropertyKey; Value: Int64): HResult; stdcall;
    function GetSignedLargeIntegerValue(const key: TPropertyKey; out pValue: Int64): HResult; stdcall;
    function SetFloatValue(const key: TPropertyKey; Value: Single): HResult; stdcall;
    function GetFloatValue(const key: TPropertyKey; out pValue: Single): HResult; stdcall;
    function SetErrorValue(const key: TPropertyKey; Value: HResult): HResult; stdcall;
    function GetErrorValue(const key: TPropertyKey; out pValue: HResult): HResult; stdcall;
    function SetKeyValue(const key: TPropertyKey; const Value: TPropertyKey): HResult; stdcall;
    function GetKeyValue(const key: TPropertyKey; out pValue: TPropertyKey): HResult; stdcall;
    function SetBoolValue(const key: TPropertyKey; Value: BOOL): HResult; stdcall;
    function GetBoolValue(const key: TPropertyKey; out pValue: BOOL): HResult; stdcall;
    function SetIUnknownValue(const key: TPropertyKey; const pValue: IUnknown): HResult; stdcall;
    function GetIUnknownValue(const key: TPropertyKey; out ppValue: IUnknown): HResult; stdcall;
    function SetGuidValue(const key: TPropertyKey; const Value: TGUID): HResult; stdcall;
    function GetGuidValue(const key: TPropertyKey; out pValue: TGUID): HResult; stdcall;
    function SetBufferValue(const key: TPropertyKey; const pValue: Byte; cbValue: LongWord): HResult; stdcall;
    function GetBufferValue(const key: TPropertyKey; out ppValue: PByte1; out pcbValue: LongWord): HResult; stdcall;
    function SetIPortableDeviceValuesValue(const key: TPropertyKey;
                                           const pValue: IPortableDeviceValues): HResult; stdcall;
    function GetIPortableDeviceValuesValue(const key: TPropertyKey;
                                           out ppValue: IPortableDeviceValues): HResult; stdcall;
    function SetIPortableDevicePropVariantCollectionValue(const key: TPropertyKey;
                                                          const pValue: IPortableDevicePropVariantCollection): HResult; stdcall;
    function GetIPortableDevicePropVariantCollectionValue(const key: TPropertyKey;
                                                          out ppValue: IPortableDevicePropVariantCollection): HResult; stdcall;
    function SetIPortableDeviceKeyCollectionValue(const key: TPropertyKey;
                                                  const pValue: IPortableDeviceKeyCollection): HResult; stdcall;
    function GetIPortableDeviceKeyCollectionValue(const key: TPropertyKey;
                                                  out ppValue: IPortableDeviceKeyCollection): HResult; stdcall;
    function SetIPortableDeviceValuesCollectionValue(const key: TPropertyKey;
                                                     const pValue: IPortableDeviceValuesCollection): HResult; stdcall;
    function GetIPortableDeviceValuesCollectionValue(const key: TPropertyKey;
                                                     out ppValue: IPortableDeviceValuesCollection): HResult; stdcall;
    function RemoveValue(const key: TPropertyKey): HResult; stdcall;
    function CopyValuesFromPropertyStore(const pStore: IPropertyStore): HResult; stdcall;
    function CopyValuesToPropertyStore(const pStore: IPropertyStore): HResult; stdcall;
    function Clear: HResult; stdcall;
  end;

// *********************************************************************//
// Interface: IStorage
// Flags:     (0)
// GUID:      {0000000B-0000-0000-C000-000000000046}
// *********************************************************************//
  IStorage = interface(IUnknown)
    ['{0000000B-0000-0000-C000-000000000046}']
    function CreateStream(pwcsName: PWideChar; grfMode: LongWord; reserved1: LongWord; 
                          reserved2: LongWord; out ppstm: IStream): HResult; stdcall;
    function RemoteOpenStream(pwcsName: PWideChar; cbReserved1: LongWord; var reserved1: Byte;
                              grfMode: LongWord; reserved2: LongWord; out ppstm: IStream): HResult; stdcall;
    function CreateStorage(pwcsName: PWideChar; grfMode: LongWord; reserved1: LongWord; 
                           reserved2: LongWord; out ppstg: IStorage): HResult; stdcall;
    function OpenStorage(pwcsName: PWideChar; const pstgPriority: IStorage; grfMode: LongWord; 
                         const snbExclude: tagRemSNB; reserved: LongWord; out ppstg: IStorage): HResult; stdcall;
    function RemoteCopyTo(ciidExclude: LongWord; var rgiidExclude: TGUID;
                          const snbExclude: tagRemSNB; const pstgDest: IStorage): HResult; stdcall;
    function MoveElementTo(pwcsName: PWideChar; const pstgDest: IStorage; pwcsNewName: PWideChar; 
                           grfFlags: LongWord): HResult; stdcall;
    function Commit(grfCommitFlags: LongWord): HResult; stdcall;
    function Revert: HResult; stdcall;
    function RemoteEnumElements(reserved1: LongWord; cbReserved2: LongWord; var reserved2: Byte; 
                                reserved3: LongWord; out ppenum: IEnumSTATSTG): HResult; stdcall;
    function DestroyElement(pwcsName: PWideChar): HResult; stdcall;
    function RenameElement(pwcsOldName: PWideChar; pwcsNewName: PWideChar): HResult; stdcall;
    function SetElementTimes(pwcsName: PWideChar; var pctime: _FILETIME; var patime: _FILETIME; 
                             const pmtime: _FILETIME): HResult; stdcall;
    function SetClass(var clsid: TGUID): HResult; stdcall;
    function SetStateBits(grfStateBits: LongWord; grfMask: LongWord): HResult; stdcall;
    function Stat(out pstatstg: tagSTATSTG; grfStatFlag: LongWord): HResult; stdcall;
  end;

// *********************************************************************//
// Interface: IEnumSTATSTG
// Flags:     (0)
// GUID:      {0000000D-0000-0000-C000-000000000046}
// *********************************************************************//
  IEnumSTATSTG = interface(IUnknown)
    ['{0000000D-0000-0000-C000-000000000046}']
    function RemoteNext(celt: LongWord; out rgelt: tagSTATSTG; out pceltFetched: LongWord): HResult; stdcall;
    function Skip(celt: LongWord): HResult; stdcall;
    function Reset: HResult; stdcall;
    function Clone(out ppenum: IEnumSTATSTG): HResult; stdcall;
  end;

// *********************************************************************//
// Interface: IRecordInfo
// Flags:     (0)
// GUID:      {0000002F-0000-0000-C000-000000000046}
// *********************************************************************//
  IRecordInfo = interface(IUnknown)
    ['{0000002F-0000-0000-C000-000000000046}']
    function RecordInit(pvNew: Pointer): HResult; stdcall;
    function RecordClear(pvExisting: Pointer): HResult; stdcall;
    function RecordCopy(pvExisting: Pointer; pvNew: Pointer): HResult; stdcall;
    function GetGuid(out pguid: TGUID): HResult; stdcall;
    function GetName(out pbstrName: WideString): HResult; stdcall;
    function GetSize(out pcbSize: LongWord): HResult; stdcall;
    function GetTypeInfo(out ppTypeInfo: ITypeInfo): HResult; stdcall;
    function GetField(pvData: Pointer; szFieldName: PWideChar; out pvarField: OleVariant): HResult; stdcall;
    function GetFieldNoCopy(pvData: Pointer; szFieldName: PWideChar; out pvarField: OleVariant; 
                            out ppvDataCArray: Pointer): HResult; stdcall;
    function PutField(wFlags: LongWord; pvData: Pointer; szFieldName: PWideChar; 
                      const pvarField: OleVariant): HResult; stdcall;
    function PutFieldNoCopy(wFlags: LongWord; pvData: Pointer; szFieldName: PWideChar; 
                            const pvarField: OleVariant): HResult; stdcall;
    function GetFieldNames(var pcNames: LongWord; out rgBstrNames: WideString): HResult; stdcall;
    function IsMatchingType(const pRecordInfo: IRecordInfo): Integer; stdcall;
    function RecordCreate: Pointer; stdcall;
    function RecordCreateCopy(pvSource: Pointer; out ppvDest: Pointer): HResult; stdcall;
    function RecordDestroy(pvRecord: Pointer): HResult; stdcall;
  end;

// *********************************************************************//
// Interface: ITypeInfo
// Flags:     (0)
// GUID:      {00020401-0000-0000-C000-000000000046}
// *********************************************************************//
  ITypeInfo = interface(IUnknown)
    ['{00020401-0000-0000-C000-000000000046}']
    function RemoteGetTypeAttr(out ppTypeAttr: PUserType8; out pDummy: DWORD): HResult; stdcall;
    function GetTypeComp(out ppTComp: ITypeComp): HResult; stdcall;
    function RemoteGetFuncDesc(index: SYSUINT; out ppFuncDesc: PUserType9; out pDummy: DWORD): HResult; stdcall;
    function RemoteGetVarDesc(index: SYSUINT; out ppVarDesc: PUserType10; out pDummy: DWORD): HResult; stdcall;
    function RemoteGetNames(memid: Integer; out rgBstrNames: WideString; cMaxNames: SYSUINT; 
                            out pcNames: SYSUINT): HResult; stdcall;
    function GetRefTypeOfImplType(index: SYSUINT; out pRefType: LongWord): HResult; stdcall;
    function GetImplTypeFlags(index: SYSUINT; out pImplTypeFlags: SYSINT): HResult; stdcall;
    function LocalGetIDsOfNames: HResult; stdcall;
    function LocalInvoke: HResult; stdcall;
    function RemoteGetDocumentation(memid: Integer; refPtrFlags: LongWord; 
                                    out pbstrName: WideString; out pBstrDocString: WideString; 
                                    out pdwHelpContext: LongWord; out pBstrHelpFile: WideString): HResult; stdcall;
    function RemoteGetDllEntry(memid: Integer; invkind: tagINVOKEKIND; refPtrFlags: LongWord; 
                               out pBstrDllName: WideString; out pbstrName: WideString; 
                               out pwOrdinal: Word): HResult; stdcall;
    function GetRefTypeInfo(hreftype: LongWord; out ppTInfo: ITypeInfo): HResult; stdcall;
    function LocalAddressOfMember: HResult; stdcall;
    function RemoteCreateInstance(const riid: TGUID; out ppvObj: IUnknown): HResult; stdcall;
    function GetMops(memid: Integer; out pBstrMops: WideString): HResult; stdcall;
    function RemoteGetContainingTypeLib(out ppTLib: ITypeLib; out pIndex: SYSUINT): HResult; stdcall;
    function LocalReleaseTypeAttr: HResult; stdcall;
    function LocalReleaseFuncDesc: HResult; stdcall;
    function LocalReleaseVarDesc: HResult; stdcall;
  end;

// *********************************************************************//
// Interface: ITypeComp
// Flags:     (0)
// GUID:      {00020403-0000-0000-C000-000000000046}
// *********************************************************************//
  ITypeComp = interface(IUnknown)
    ['{00020403-0000-0000-C000-000000000046}']
    function RemoteBind(szName: PWideChar; lHashVal: LongWord; wFlags: Word; 
                        out ppTInfo: ITypeInfo; out pDescKind: tagDESCKIND; 
                        out ppFuncDesc: PUserType9; out ppVarDesc: PUserType10; 
                        out ppTypeComp: ITypeComp; out pDummy: DWORD): HResult; stdcall;
    function RemoteBindType(szName: PWideChar; lHashVal: LongWord; out ppTInfo: ITypeInfo): HResult; stdcall;
  end;

// *********************************************************************//
// Interface: ITypeLib
// Flags:     (0)
// GUID:      {00020402-0000-0000-C000-000000000046}
// *********************************************************************//
  ITypeLib = interface(IUnknown)
    ['{00020402-0000-0000-C000-000000000046}']
    function RemoteGetTypeInfoCount(out pcTInfo: SYSUINT): HResult; stdcall;
    function GetTypeInfo(index: SYSUINT; out ppTInfo: ITypeInfo): HResult; stdcall;
    function GetTypeInfoType(index: SYSUINT; out pTKind: tagTYPEKIND): HResult; stdcall;
    function GetTypeInfoOfGuid(const guid: TGUID; out ppTInfo: ITypeInfo): HResult; stdcall;
    function RemoteGetLibAttr(out ppTLibAttr: PUserType13; out pDummy: DWORD): HResult; stdcall;
    function GetTypeComp(out ppTComp: ITypeComp): HResult; stdcall;
    function RemoteGetDocumentation(index: SYSINT; refPtrFlags: LongWord; 
                                    out pbstrName: WideString; out pBstrDocString: WideString; 
                                    out pdwHelpContext: LongWord; out pBstrHelpFile: WideString): HResult; stdcall;
    function RemoteIsName(szNameBuf: PWideChar; lHashVal: LongWord; out pfName: Integer; 
                          out pBstrLibName: WideString): HResult; stdcall;
    function RemoteFindName(szNameBuf: PWideChar; lHashVal: LongWord; out ppTInfo: ITypeInfo;
                            out rgMemId: Integer; var pcFound: Word; out pBstrLibName: WideString): HResult; stdcall;
    function LocalReleaseTLibAttr: HResult; stdcall;
  end;

// *********************************************************************//
// Interface: IPortableDevicePropVariantCollection
// Flags:     (0)
// GUID:      {89B2E422-4F1B-4316-BCEF-A44AFEA83EB3}
// *********************************************************************//
  IPortableDevicePropVariantCollection = interface(IUnknown)
    ['{89B2E422-4F1B-4316-BCEF-A44AFEA83EB3}']
    function GetCount(var pcElems: LongWord): HResult; stdcall;
    function GetAt(dwIndex: LongWord; var pValue: TPropVariant): HResult; stdcall;
    function Add(const pValue: TPropVariant): HResult; stdcall;
    function GetType(out pvt: Word): HResult; stdcall;
    function ChangeType(vt: Word): HResult; stdcall;
    function Clear: HResult; stdcall;
    function RemoveAt(dwIndex: LongWord): HResult; stdcall;
  end;

// *********************************************************************//
// Interface: IPortableDeviceKeyCollection
// Flags:     (0)
// GUID:      {DADA2357-E0AD-492E-98DB-DD61C53BA353}
// *********************************************************************//
  IPortableDeviceKeyCollection = interface(IUnknown)
    ['{DADA2357-E0AD-492E-98DB-DD61C53BA353}']
    function GetCount(var pcElems: LongWord): HResult; stdcall;
    function GetAt(dwIndex: LongWord; var pKey: TPropertyKey): HResult; stdcall;
    function Add(const key: TPropertyKey): HResult; stdcall;
    function Clear: HResult; stdcall;
    function RemoveAt(dwIndex: LongWord): HResult; stdcall;
  end;

// *********************************************************************//
// Interface: IPortableDeviceValuesCollection
// Flags:     (0)
// GUID:      {6E3F2D79-4E07-48C4-8208-D8C2E5AF4A99}
// *********************************************************************//
  IPortableDeviceValuesCollection = interface(IUnknown)
    ['{6E3F2D79-4E07-48C4-8208-D8C2E5AF4A99}']
    function GetCount(out pcElems: LongWord): HResult; stdcall;
    function GetAt(dwIndex: LongWord; out ppValues: IPortableDeviceValues): HResult; stdcall;
    function Add(const pValues: IPortableDeviceValues): HResult; stdcall;
    function Clear: HResult; stdcall;
    function RemoveAt(dwIndex: LongWord): HResult; stdcall;
  end;

// *********************************************************************//
// Interface: IPropertyStore
// Flags:     (0)
// GUID:      {886D8EEB-8CF2-4446-8D02-CDBA1DBDCF99}
// *********************************************************************//
  IPropertyStore = interface(IUnknown)
    ['{886D8EEB-8CF2-4446-8D02-CDBA1DBDCF99}']
    function GetCount(out cProps: LongWord): HResult; stdcall;
    function GetAt(iProp: LongWord; out pKey: TPropertyKey): HResult; stdcall;
    function GetValue(const key: TPropertyKey; out pv: TPropVariant): HResult; stdcall;
    function SetValue(const key: TPropertyKey; var propvar: TPropVariant): HResult; stdcall;
    function Commit: HResult; stdcall;
  end;

// *********************************************************************//
// Interface: IPortableDeviceContent
// Flags:     (0)
// GUID:      {6A96ED84-7C73-4480-9938-BF5AF477D426}
// *********************************************************************//
  IPortableDeviceContent = interface(IUnknown)
    ['{6A96ED84-7C73-4480-9938-BF5AF477D426}']
    function EnumObjects(dwFlags: LongWord; pszParentObjectID: PWideChar; 
                         const pFilter: IPortableDeviceValues; 
                         out ppenum: IEnumPortableDeviceObjectIDs): HResult; stdcall;
    function Properties(out ppProperties: IPortableDeviceProperties): HResult; stdcall;
    function Transfer(out ppResources: IPortableDeviceResources): HResult; stdcall;
    function CreateObjectWithPropertiesOnly(const pValues: IPortableDeviceValues;
                                            var ppszObjectID: PWideChar): HResult; stdcall;
    function CreateObjectWithPropertiesAndData(const pValues: IPortableDeviceValues; 
                                               out ppData: IStream; 
                                               var pdwOptimalWriteBufferSize: LongWord; 
                                               var ppszCookie: PWideChar): HResult; stdcall;
    function Delete(dwOptions: LongWord; const pObjectIDs: IPortableDevicePropVariantCollection; 
                    var ppResults: IPortableDevicePropVariantCollection): HResult; stdcall;
    function GetObjectIDsFromPersistentUniqueIDs(const pPersistentUniqueIDs: IPortableDevicePropVariantCollection; 
                                                 out ppObjectIDs: IPortableDevicePropVariantCollection): HResult; stdcall;
    function Cancel: HResult; stdcall;
    function Move(const pObjectIDs: IPortableDevicePropVariantCollection; 
                  pszDestinationFolderObjectID: PWideChar; 
                  var ppResults: IPortableDevicePropVariantCollection): HResult; stdcall;
    function Copy(const pObjectIDs: IPortableDevicePropVariantCollection; 
                  pszDestinationFolderObjectID: PWideChar; 
                  var ppResults: IPortableDevicePropVariantCollection): HResult; stdcall;
  end;

// *********************************************************************//
// Interface: IEnumPortableDeviceObjectIDs
// Flags:     (0)
// GUID:      {10ECE955-CF41-4728-BFA0-41EEDF1BBF19}
// *********************************************************************//
  IEnumPortableDeviceObjectIDs = interface(IUnknown)
    ['{10ECE955-CF41-4728-BFA0-41EEDF1BBF19}']
    function Next(cObjects: LongWord; out pObjIDs: PWideChar; var pcFetched: LongWord): HResult; stdcall;
    function Skip(cObjects: LongWord): HResult; stdcall;
    function Reset: HResult; stdcall;
    function Clone(out ppenum: IEnumPortableDeviceObjectIDs): HResult; stdcall;
    function Cancel: HResult; stdcall;
  end;

// *********************************************************************//
// Interface: IPortableDeviceProperties
// Flags:     (0)
// GUID:      {7F6D695C-03DF-4439-A809-59266BEEE3A6}
// *********************************************************************//
  IPortableDeviceProperties = interface(IUnknown)
    ['{7F6D695C-03DF-4439-A809-59266BEEE3A6}']
    function GetSupportedProperties(pszObjectID: PWideChar; out ppKeys: IPortableDeviceKeyCollection): HResult; stdcall;
    function GetPropertyAttributes(pszObjectID: PWideChar; const key: TPropertyKey;
                                   out ppAttributes: IPortableDeviceValues): HResult; stdcall;
    function GetValues(pszObjectID: PWideChar; const pKeys: IPortableDeviceKeyCollection;
                       out ppValues: IPortableDeviceValues): HResult; stdcall;
    function SetValues(pszObjectID: PWideChar; const pValues: IPortableDeviceValues;
                       out ppResults: IPortableDeviceValues): HResult; stdcall;
    function Delete(pszObjectID: PWideChar; const pKeys: IPortableDeviceKeyCollection): HResult; stdcall;
    function Cancel: HResult; stdcall;
  end;

// *********************************************************************//
// Interface: IPortableDevicePropertiesBulk
// Flags:     (0)
// GUID:      {482b05c0-4056-44ed-9e0f-5e23b009da93}
// *********************************************************************//
  IPortableDevicePropertiesBulk = interface(IUnknown)
    ['{482b05c0-4056-44ed-9e0f-5e23b009da93}']
    function QueueGetValuesByObjectList(pObjectIDs: IPortableDevicePropVariantCollection;
                  pKeys: IPortableDeviceKeyCollection;
                  pCallback: IPortableDevicePropertiesBulkCallback;
                  out pContext: TGuid): HResult; stdcall;
    function QueueGetValuesByObjectFormat(var pguidObjectFormat: TGuid;
                  pszParentObjectID: LPCWSTR; dwDepth: DWORD;
                  pKeys: IPortableDeviceKeyCollection;
                  pCallback: IPortableDevicePropertiesBulkCallback;
                  out pContext: TGuid): HResult; stdcall;
    function QueueSetValuesByObjectList(pObjectValues: IPortableDeviceValuesCollection;
                  pCallback: IPortableDevicePropertiesBulkCallback;
                  out pContext: TGuid): HResult; stdcall;
    function Start(const pContext: TGuid): HResult; stdcall;
    function Cancel(const pContext: TGuid): HResult; stdcall;
  end;

// *********************************************************************//
// Interface: IPortableDevicePropertiesBulkCallback
// Flags:     (0)
// GUID:      {9deacb80-11e8-40e3-a9f3-f557986a7845}
// *********************************************************************//
  IPortableDevicePropertiesBulkCallback = interface(IUnknown)
    ['{9deacb80-11e8-40e3-a9f3-f557986a7845}']
    function OnStart(const pContext: TGuid): HResult; stdcall;
    function OnProgress(const pContext: TGuid; pResults: IPortableDeviceValuesCollection): HResult; stdcall;
    function OnEnd(const pContext: TGuid; hrStatus: HResult): HResult; stdcall;
  end;

// *********************************************************************//
// Interface: IPortableDeviceDataStream
// Flags:     (0)
// GUID:      {88e04db3-1012-4d64-9996-f703a950d3f4}
// *********************************************************************//
  IPortableDeviceDataStream = interface(IStream)
    ['{88e04db3-1012-4d64-9996-f703a950d3f4}']
    function GetObjectID(var ppszObjectID : PWideChar): HResult; stdcall;
    function Cancel: HResult; stdcall;
  end;

// *********************************************************************//
// Interface: IPortableDeviceResources
// Flags:     (0)
// GUID:      {FD8878AC-D841-4D17-891C-E6829CDB6934}
// *********************************************************************//
  IPortableDeviceResources = interface(IUnknown)
    ['{FD8878AC-D841-4D17-891C-E6829CDB6934}']
    function GetSupportedResources(pszObjectID: PWideChar; out ppKeys: IPortableDeviceKeyCollection): HResult; stdcall;
    function GetResourceAttributes(pszObjectID: PWideChar; const key: TPropertyKey;
                                   out ppResourceAttributes: IPortableDeviceValues): HResult; stdcall;
    function GetStream(pszObjectID: PWideChar; const key: TPropertyKey; dwMode: LongWord;
                       var pdwOptimalBufferSize: LongWord; out ppStream: IStream): HResult; stdcall;
    function Delete(pszObjectID: PWideChar; const pKeys: IPortableDeviceKeyCollection): HResult; stdcall;
    function Cancel: HResult; stdcall;
    function CreateResource(const pResourceAttributes: IPortableDeviceValues; out ppData: IStream;
                            var pdwOptimalWriteBufferSize: LongWord; var ppszCookie: PWideChar): HResult; stdcall;
  end;

// *********************************************************************//
// Interface: IPortableDeviceCapabilities
// Flags:     (0)
// GUID:      {2C8C6DBF-E3DC-4061-BECC-8542E810D126}
// *********************************************************************//
  IPortableDeviceCapabilities = interface(IUnknown)
    ['{2C8C6DBF-E3DC-4061-BECC-8542E810D126}']
    function GetSupportedCommands(out ppCommands: IPortableDeviceKeyCollection): HResult; stdcall;
    function GetCommandOptions(const Command: TPropertyKey; out ppOptions: IPortableDeviceValues): HResult; stdcall;
    function GetFunctionalCategories(out ppCategories: IPortableDevicePropVariantCollection): HResult; stdcall;
    function GetFunctionalObjects(const Category: TGUID;
                                  out ppObjectIDs: IPortableDevicePropVariantCollection): HResult; stdcall;
    function GetSupportedContentTypes(const Category: TGUID;
                                      out ppContentTypes: IPortableDevicePropVariantCollection): HResult; stdcall;
    function GetSupportedFormats(const ContentType: TGUID;
                                 out ppFormats: IPortableDevicePropVariantCollection): HResult; stdcall;
    function GetSupportedFormatProperties(const Format: TGUID;
                                          out ppKeys: IPortableDeviceKeyCollection): HResult; stdcall;
    function GetFixedPropertyAttributes(const Format: TGUID; const key: TPropertyKey;
                                        out ppAttributes: IPortableDeviceValues): HResult; stdcall;
    function Cancel: HResult; stdcall;
    function GetSupportedEvents(out ppEvents: IPortableDevicePropVariantCollection): HResult; stdcall;
    function GetEventOptions(const Event: TGUID; out ppOptions: IPortableDeviceValues): HResult; stdcall;
  end;

// *********************************************************************//
// Interface: IPortableDeviceEventCallback
// Flags:     (0)
// GUID:      {A8792A31-F385-493C-A893-40F64EB45F6E}
// *********************************************************************//
  IPortableDeviceEventCallback = interface(IUnknown)
    ['{A8792A31-F385-493C-A893-40F64EB45F6E}']
    function OnEvent(const pEventParameters: IPortableDeviceValues): HResult; stdcall;
  end;

// *********************************************************************//
// Interface: IPortableDeviceManager
// Flags:     (0)
// GUID:      {A1567595-4C2F-4574-A6FA-ECEF917B9A40}
// *********************************************************************//
  IPortableDeviceManager = interface(IUnknown)
    ['{A1567595-4C2F-4574-A6FA-ECEF917B9A40}']
    function GetDevices(var pPnPDeviceIDs: PWideChar; var pcPnPDeviceIDs: LongWord): HResult; stdcall;
    function RefreshDeviceList: HResult; stdcall;
    function GetDeviceFriendlyName(pszPnPDeviceID: PWideChar; var pDeviceFriendlyName: WChar;
                                   var pcchDeviceFriendlyName: LongWord): HResult; stdcall;
    function GetDeviceDescription(pszPnPDeviceID: PWideChar; var pDeviceDescription: WChar;
                                  var pcchDeviceDescription: LongWord): HResult; stdcall;
    function GetDeviceManufacturer(pszPnPDeviceID: PWideChar; var pDeviceManufacturer: WChar;
                                   var pcchDeviceManufacturer: LongWord): HResult; stdcall;
    function GetDeviceProperty(pszPnPDeviceID: PWideChar; pszDevicePropertyName: PWideChar; 
                               var pData: Byte; var pcbData: LongWord; var pdwType: LongWord): HResult; stdcall;
    function GetPrivateDevices(var pPnPDeviceIDs: PWideChar; var pcPnPDeviceIDs: LongWord): HResult; stdcall;
  end;

// *********************************************************************//
// Interface: IPortableDeviceService
// Flags:     (0)
// GUID:      {D3BD3A44-D7B5-40A9-98B7-2FA4D01DEC08}
// *********************************************************************//
  IPortableDeviceService = interface(IUnknown)
    ['{D3BD3A44-D7B5-40A9-98B7-2FA4D01DEC08}']
    function Open(pszPnPServiceID: PWideChar; const pClientInfo: IPortableDeviceValues): HResult; stdcall;
    function Capabilities(out ppCapabilities: IPortableDeviceServiceCapabilities): HResult; stdcall;
    function Content(out ppContent: IPortableDeviceContent2): HResult; stdcall;
    function Methods(out ppMethods: IPortableDeviceServiceMethods): HResult; stdcall;
    function Cancel: HResult; stdcall;
    function Close: HResult; stdcall;
    function GetServiceObjectID(out ppszServiceObjectID: PWideChar): HResult; stdcall;
    function GetPnPServiceID(out ppszPnPServiceID: PWideChar): HResult; stdcall;
    function Advise(dwFlags: LongWord; const pCallback: IPortableDeviceEventCallback; 
                    const pParameters: IPortableDeviceValues; out ppszCookie: PWideChar): HResult; stdcall;
    function Unadvise(pszCookie: PWideChar): HResult; stdcall;
    function SendCommand(dwFlags: LongWord; const pParameters: IPortableDeviceValues; 
                         out ppResults: IPortableDeviceValues): HResult; stdcall;
  end;

// *********************************************************************//
// Interface: IPortableDeviceServiceCapabilities
// Flags:     (0)
// GUID:      {24DBD89D-413E-43E0-BD5B-197F3C56C886}
// *********************************************************************//
  IPortableDeviceServiceCapabilities = interface(IUnknown)
    ['{24DBD89D-413E-43E0-BD5B-197F3C56C886}']
    function GetSupportedMethods(out ppMethods: IPortableDevicePropVariantCollection): HResult; stdcall;
    function GetSupportedMethodsByFormat(const Format: TGUID;
                                         out ppMethods: IPortableDevicePropVariantCollection): HResult; stdcall;
    function GetMethodAttributes(const Method: TGUID; out ppAttributes: IPortableDeviceValues): HResult; stdcall;
    function GetMethodParameterAttributes(const Method: TGUID; var Parameter: TPropertyKey;
                                          out ppAttributes: IPortableDeviceValues): HResult; stdcall;
    function GetSupportedFormats(out ppFormats: IPortableDevicePropVariantCollection): HResult; stdcall;
    function GetFormatAttributes(const Format: TGUID; out ppAttributes: IPortableDeviceValues): HResult; stdcall;
    function GetSupportedFormatProperties(const Format: TGUID;
                                          out ppKeys: IPortableDeviceKeyCollection): HResult; stdcall;
    function GetFormatPropertyAttributes(const Format: TGUID; var Property_: TPropertyKey;
                                         out ppAttributes: IPortableDeviceValues): HResult; stdcall;
    function GetSupportedEvents(out ppEvents: IPortableDevicePropVariantCollection): HResult; stdcall;
    function GetEventAttributes(const Event: TGUID; out ppAttributes: IPortableDeviceValues): HResult; stdcall;
    function GetEventParameterAttributes(const Event: TGUID; var Parameter: TPropertyKey;
                                         out ppAttributes: IPortableDeviceValues): HResult; stdcall;
    function GetInheritedServices(dwInheritanceType: LongWord; 
                                  out ppServices: IPortableDevicePropVariantCollection): HResult; stdcall;
    function GetFormatRenderingProfiles(const Format: TGUID;
                                        out ppRenderingProfiles: IPortableDeviceValuesCollection): HResult; stdcall;
    function GetSupportedCommands(out ppCommands: IPortableDeviceKeyCollection): HResult; stdcall;
    function GetCommandOptions(const Command: TPropertyKey; out ppOptions: IPortableDeviceValues): HResult; stdcall;
    function Cancel: HResult; stdcall;
  end;

// *********************************************************************//
// Interface: IPortableDeviceContent2
// Flags:     (0)
// GUID:      {9B4ADD96-F6BF-4034-8708-ECA72BF10554}
// *********************************************************************//
  IPortableDeviceContent2 = interface(IPortableDeviceContent)
    ['{9B4ADD96-F6BF-4034-8708-ECA72BF10554}']
    function UpdateObjectWithPropertiesAndData(pszObjectID: PWideChar; 
                                               const pProperties: IPortableDeviceValues; 
                                               out ppData: IStream; 
                                               var pdwOptimalWriteBufferSize: LongWord): HResult; stdcall;
  end;

// *********************************************************************//
// Interface: IPortableDeviceServiceMethods
// Flags:     (0)
// GUID:      {E20333C9-FD34-412D-A381-CC6F2D820DF7}
// *********************************************************************//
  IPortableDeviceServiceMethods = interface(IUnknown)
    ['{E20333C9-FD34-412D-A381-CC6F2D820DF7}']
    function Invoke(const Method: TGUID; const pParameters: IPortableDeviceValues;
                    var ppResults: IPortableDeviceValues): HResult; stdcall;
    function InvokeAsync(const Method: TGUID; const pParameters: IPortableDeviceValues;
                         const pCallback: IPortableDeviceServiceMethodCallback): HResult; stdcall;
    function Cancel(const pCallback: IPortableDeviceServiceMethodCallback): HResult; stdcall;
  end;

// *********************************************************************//
// Interface: IPortableDeviceServiceMethodCallback
// Flags:     (0)
// GUID:      {C424233C-AFCE-4828-A756-7ED7A2350083}
// *********************************************************************//
  IPortableDeviceServiceMethodCallback = interface(IUnknown)
    ['{C424233C-AFCE-4828-A756-7ED7A2350083}']
    function OnComplete(hrStatus: HResult; const pResults: IPortableDeviceValues): HResult; stdcall;
  end;

// *********************************************************************//
// Interface: IPortableDeviceDispatchFactory
// Flags:     (0)
// GUID:      {5E1EAFC3-E3D7-4132-96FA-759C0F9D1E0F}
// *********************************************************************//
  IPortableDeviceDispatchFactory = interface(IUnknown)
    ['{5E1EAFC3-E3D7-4132-96FA-759C0F9D1E0F}']
    function GetDeviceDispatch(pszPnPDeviceID: PWideChar; out ppDeviceDispatch: IDispatch): HResult; stdcall;
  end;

// *********************************************************************//
// Interface: IPortableDeviceWebControl
// Flags:     (4544) Dual NonExtensible OleAutomation Dispatchable
// GUID:      {94FC7953-5CA1-483A-8AEE-DF52E7747D00}
// *********************************************************************//
  IPortableDeviceWebControl = interface(IDispatch)
    ['{94FC7953-5CA1-483A-8AEE-DF52E7747D00}']
    function GetDeviceFromId(const deviceId: WideString): IDispatch; safecall;
    procedure GetDeviceFromIdAsync(const deviceId: WideString; const pCompletionHandler: IDispatch; 
                                   const pErrorHandler: IDispatch); safecall;
  end;

// *********************************************************************//
// DispIntf:  IPortableDeviceWebControlDisp
// Flags:     (4544) Dual NonExtensible OleAutomation Dispatchable
// GUID:      {94FC7953-5CA1-483A-8AEE-DF52E7747D00}
// *********************************************************************//
  IPortableDeviceWebControlDisp = dispinterface
    ['{94FC7953-5CA1-483A-8AEE-DF52E7747D00}']
    function GetDeviceFromId(const deviceId: WideString): IDispatch; dispid 1;
    procedure GetDeviceFromIdAsync(const deviceId: WideString; const pCompletionHandler: IDispatch; 
                                   const pErrorHandler: IDispatch); dispid 2;
  end;

// *********************************************************************//
// Die Klasse CoPortableDevice stellt die Methoden Create und CreateRemote zur
// Verfügung, um Instanzen des Standard-Interface IPortableDevice, dargestellt
// von CoClass PortableDevice, zu erzeugen. Diese Funktionen können
// von einem Client verwendet werden, der die CoClasses automatisieren
// will, die von dieser Typbibliothek dargestellt werden.                                           
// *********************************************************************//
  CoPortableDevice = class
    class function Create: IPortableDevice;
    class function CreateRemote(const MachineName: string): IPortableDevice;
  end;

// *********************************************************************//
// Die Klasse CoPortableDeviceManager stellt die Methoden Create und CreateRemote zur
// Verfügung, um Instanzen des Standard-Interface IPortableDeviceManager, dargestellt
// von CoClass PortableDeviceManager, zu erzeugen. Diese Funktionen können
// von einem Client verwendet werden, der die CoClasses automatisieren
// will, die von dieser Typbibliothek dargestellt werden.                                           
// *********************************************************************//
  CoPortableDeviceManager = class
    class function Create: IPortableDeviceManager;
    class function CreateRemote(const MachineName: string): IPortableDeviceManager;
  end;

// *********************************************************************//
// Die Klasse CoPortableDeviceService stellt die Methoden Create und CreateRemote zur
// Verfügung, um Instanzen des Standard-Interface IPortableDeviceService, dargestellt
// von CoClass PortableDeviceService, zu erzeugen. Diese Funktionen können
// von einem Client verwendet werden, der die CoClasses automatisieren
// will, die von dieser Typbibliothek dargestellt werden.                                           
// *********************************************************************//
  CoPortableDeviceService = class
    class function Create: IPortableDeviceService;
    class function CreateRemote(const MachineName: string): IPortableDeviceService;
  end;

// *********************************************************************//
// Die Klasse CoPortableDeviceDispatchFactory stellt die Methoden Create und CreateRemote zur
// Verfügung, um Instanzen des Standard-Interface IPortableDeviceDispatchFactory, dargestellt
// von CoClass PortableDeviceDispatchFactory, zu erzeugen. Diese Funktionen können
// von einem Client verwendet werden, der die CoClasses automatisieren
// will, die von dieser Typbibliothek dargestellt werden.                                           
// *********************************************************************//
  CoPortableDeviceDispatchFactory = class
    class function Create: IPortableDeviceDispatchFactory;
    class function CreateRemote(const MachineName: string): IPortableDeviceDispatchFactory;
  end;

// *********************************************************************//
// Die Klasse CoPortableDeviceFTM stellt die Methoden Create und CreateRemote zur
// Verfügung, um Instanzen des Standard-Interface IPortableDevice, dargestellt
// von CoClass PortableDeviceFTM, zu erzeugen. Diese Funktionen können
// von einem Client verwendet werden, der die CoClasses automatisieren
// will, die von dieser Typbibliothek dargestellt werden.                                           
// *********************************************************************//
  CoPortableDeviceFTM = class
    class function Create: IPortableDevice;
    class function CreateRemote(const MachineName: string): IPortableDevice;
  end;

// *********************************************************************//
// Die Klasse CoPortableDeviceServiceFTM stellt die Methoden Create und CreateRemote zur
// Verfügung, um Instanzen des Standard-Interface IPortableDeviceService, dargestellt
// von CoClass PortableDeviceServiceFTM, zu erzeugen. Diese Funktionen können
// von einem Client verwendet werden, der die CoClasses automatisieren
// will, die von dieser Typbibliothek dargestellt werden.                                           
// *********************************************************************//
  CoPortableDeviceServiceFTM = class
    class function Create: IPortableDeviceService;
    class function CreateRemote(const MachineName: string): IPortableDeviceService;
  end;

// *********************************************************************//
// Die Klasse CoPortableDeviceWebControl stellt die Methoden Create und CreateRemote zur
// Verfügung, um Instanzen des Standard-Interface IPortableDeviceWebControl, dargestellt
// von CoClass PortableDeviceWebControl, zu erzeugen. Diese Funktionen können
// von einem Client verwendet werden, der die CoClasses automatisieren
// will, die von dieser Typbibliothek dargestellt werden.                                           
// *********************************************************************//
  CoPortableDeviceWebControl = class
    class function Create: IPortableDeviceWebControl;
    class function CreateRemote(const MachineName: string): IPortableDeviceWebControl;
  end;

{ ---------------------------------------------------------------- }
implementation

uses System.Win.ComObj;

class function CoPortableDevice.Create: IPortableDevice;
begin
  Result := CreateComObject(CLASS_PortableDevice) as IPortableDevice;
end;

class function CoPortableDevice.CreateRemote(const MachineName: string): IPortableDevice;
begin
  Result := CreateRemoteComObject(MachineName, CLASS_PortableDevice) as IPortableDevice;
end;

class function CoPortableDeviceManager.Create: IPortableDeviceManager;
begin
  Result := CreateComObject(CLASS_PortableDeviceManager) as IPortableDeviceManager;
end;

class function CoPortableDeviceManager.CreateRemote(const MachineName: string): IPortableDeviceManager;
begin
  Result := CreateRemoteComObject(MachineName, CLASS_PortableDeviceManager) as IPortableDeviceManager;
end;

class function CoPortableDeviceService.Create: IPortableDeviceService;
begin
  Result := CreateComObject(CLASS_PortableDeviceService) as IPortableDeviceService;
end;

class function CoPortableDeviceService.CreateRemote(const MachineName: string): IPortableDeviceService;
begin
  Result := CreateRemoteComObject(MachineName, CLASS_PortableDeviceService) as IPortableDeviceService;
end;

class function CoPortableDeviceDispatchFactory.Create: IPortableDeviceDispatchFactory;
begin
  Result := CreateComObject(CLASS_PortableDeviceDispatchFactory) as IPortableDeviceDispatchFactory;
end;

class function CoPortableDeviceDispatchFactory.CreateRemote(const MachineName: string): IPortableDeviceDispatchFactory;
begin
  Result := CreateRemoteComObject(MachineName, CLASS_PortableDeviceDispatchFactory) as IPortableDeviceDispatchFactory;
end;

class function CoPortableDeviceFTM.Create: IPortableDevice;
begin
  Result := CreateComObject(CLASS_PortableDeviceFTM) as IPortableDevice;
end;

class function CoPortableDeviceFTM.CreateRemote(const MachineName: string): IPortableDevice;
begin
  Result := CreateRemoteComObject(MachineName, CLASS_PortableDeviceFTM) as IPortableDevice;
end;

class function CoPortableDeviceServiceFTM.Create: IPortableDeviceService;
begin
  Result := CreateComObject(CLASS_PortableDeviceServiceFTM) as IPortableDeviceService;
end;

class function CoPortableDeviceServiceFTM.CreateRemote(const MachineName: string): IPortableDeviceService;
begin
  Result := CreateRemoteComObject(MachineName, CLASS_PortableDeviceServiceFTM) as IPortableDeviceService;
end;

class function CoPortableDeviceWebControl.Create: IPortableDeviceWebControl;
begin
  Result := CreateComObject(CLASS_PortableDeviceWebControl) as IPortableDeviceWebControl;
end;

class function CoPortableDeviceWebControl.CreateRemote(const MachineName: string): IPortableDeviceWebControl;
begin
  Result := CreateRemoteComObject(MachineName, CLASS_PortableDeviceWebControl) as IPortableDeviceWebControl;
end;

end.
