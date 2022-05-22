(* Delphi 10 program
  Delphi transcription of WPD API Sample
  ======================================
  Demonstrates the following using the WPD API:
  - Enumerate portable devices
  - Enumerate content on a portable device
  - Query the capabilities of a portable device
  - Read/Write properties for content on a portable device
  - Transfer content on/off a portable device
  - Register/Unregister for portable device events

   provided by Microsoft on GiTHub:
   https://github.com/microsoft/Windows-classic-samples/tree/main/Samples/Win7Samples/multimedia/wpd/wpdapisample/cpp

   Delphi adaption
   © Dr. J. Rathlev, D-24222 Schwentinental (kontakt(a)rathlev-home.de)

   The contents of this file may be used under the terms of the
   Mozilla Public License ("MPL") or
   GNU Lesser General Public License Version 2 or later (the "LGPL")

   Software distributed under this License is distributed on an "AS IS" basis,
   WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for
   the specific language governing rights and limitations under the License.

   Vers. 1 - May 2022
   *)

program WpdSample;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  Winapi.ActiveX,
  Winapi.Windows,
  Winapi.CommDlg,
  System.StrUtils,
  System.Win.ComObj,
  PortableDeviceDefs,
  PortableDeviceApi;

const
  CLIENT_NAME         = 'Delphi WPD Sample Application';
  CLIENT_MAJOR_VER    = 1;
  CLIENT_MINOR_VER    = 0;
  CLIENT_REVISION     = 0;

// This number controls how many object identifiers are requested during each call
// to IEnumPortableDeviceObjectIDs::Next()
  NUM_OBJECTS_TO_REQUEST = 10;

  ImgFilter = 'JPEG (*.JPG)|*.JPG|JPEG (*.JPEG)|*.JPEG|JPG (*.JPE)|*.JPE|JPG (*.JFIF)|*.JFIF';
  MusicFilter ='MP3 (*.MP3)|*.MP3';
  ContactFilter = 'VCARD (*.VCF)|*.VCF';
  JpgExt = 'jpg';
  Mp3Ext = 'mp3';
  VcfExt = 'vcf';

type
  TCharArray = array of PWideChar;

var
  BulkPropertyOperationEvent :  THandle;
  eventCookie                : string;

function ErrorMsg (const s : string; hr : HResult) : string;
begin
  Result:='* '+s+Format('- Returned HRESULT = $%.8x: %s',[hr,SysErrorMessage(hr)]);
  end;

procedure WriteErrMsg (const s : string; hr : HResult); overload;
begin
  writeln('==> ',ErrorMsg(s,hr));
  end;

procedure WriteErrMsg (const s : string); overload;
begin
  writeln('==> * ',s);
  end;

//===================================================================
// from "DeviceCapabilities.cpp"

// Get a friendly name for a passed in functional
// category.  If the category is not known by this function
// the GUID will be displayed in string form.
function FunctionalCategoryAsString (const functionalCategory : TGuid) : string;
begin
  if functionalCategory=WPD_FUNCTIONAL_CATEGORY_STORAGE then Result:='WPD_FUNCTIONAL_CATEGORY_STORAGE'
  else if functionalCategory=WPD_FUNCTIONAL_CATEGORY_STILL_IMAGE_CAPTURE then Result:='WPD_FUNCTIONAL_CATEGORY_STILL_IMAGE_CAPTURE'
  else if functionalCategory=WPD_FUNCTIONAL_CATEGORY_AUDIO_CAPTURE then Result:='WPD_FUNCTIONAL_CATEGORY_AUDIO_CAPTURE'
  else if functionalCategory=WPD_FUNCTIONAL_CATEGORY_SMS  then Result:='WPD_FUNCTIONAL_CATEGORY_SMS'
  else if functionalCategory=WPD_FUNCTIONAL_CATEGORY_RENDERING_INFORMATION then Result:='WPD_FUNCTIONAL_CATEGORY_RENDERING_INFORMATION'
  else Result:=GuidToString(functionalCategory);
  end;

// Displays a friendly name for a passed in event
// If the event is not known by this function
// the GUID will be displayed in string form.
function EventAsString (const event : TGuid) : string;
begin
  if event=WPD_EVENT_OBJECT_ADDED then Result:='WPD_EVENT_OBJECT_ADDED'
  else if event=WPD_EVENT_OBJECT_REMOVED then Result:='WPD_EVENT_OBJECT_REMOVED'
  else if event=WPD_EVENT_OBJECT_UPDATED then Result:='WPD_EVENT_OBJECT_UPDATED'
  else if event=WPD_EVENT_DEVICE_RESET then Result:='WPD_EVENT_DEVICE_RESET'
  else if event=WPD_EVENT_DEVICE_CAPABILITIES_UPDATED then Result:='WPD_EVENT_DEVICE_CAPABILITIES_UPDATED'
  else if event=WPD_EVENT_STORAGE_FORMAT then Result:='WPD_EVENT_STORAGE_FORMAT'
  else Result:=GuidToString(event);
  end;

// Get a friendly name for a passed in content type
// If the content type is not known by this function
// the GUID will be displayed in string form.
function ContenTypeAsString (const contentType : TGuid) : string;
begin
  if contentType=WPD_CONTENT_TYPE_FUNCTIONAL_OBJECT then Result:='WPD_CONTENT_TYPE_FUNCTIONAL_OBJECT'
  else if contentType=WPD_CONTENT_TYPE_FOLDER then Result:='WPD_CONTENT_TYPE_FOLDER'
  else if contentType=WPD_CONTENT_TYPE_IMAGE then Result:='WPD_CONTENT_TYPE_IMAGE'
  else if contentType=WPD_CONTENT_TYPE_DOCUMENT then Result:='WPD_CONTENT_TYPE_DOCUMENT'
  else if contentType=WPD_CONTENT_TYPE_CONTACT then Result:='WPD_CONTENT_TYPE_CONTACT'
  else if contentType=WPD_CONTENT_TYPE_AUDIO then Result:='WPD_CONTENT_TYPE_AUDIO'
  else if contentType=WPD_CONTENT_TYPE_PLAYLIST then Result:='WPD_CONTENT_TYPE_PLAYLIST'
  else if contentType=WPD_CONTENT_TYPE_VIDEO then Result:='WPD_CONTENT_TYPE_VIDEO'
  else if contentType=WPD_CONTENT_TYPE_TASK then Result:='WPD_CONTENT_TYPE_TASK'
  else if contentType=WPD_CONTENT_TYPE_APPOINTMENT then Result:='WPD_CONTENT_TYPE_APPOINTMENT'
  else if contentType=WPD_CONTENT_TYPE_EMAIL then Result:='WPD_CONTENT_TYPE_EMAIL'
  else if contentType=WPD_CONTENT_TYPE_MEMO then Result:='WPD_CONTENT_TYPE_MEMO'
  else if contentType=WPD_CONTENT_TYPE_UNSPECIFIED then Result:='WPD_CONTENT_TYPE_UNSPECIFIED'
  else Result:=GuidToString(contentType);
  end;

// Display the basic event options for the passed in event.
function EventOptionsAsString (capabilities : IPortableDeviceCapabilities; const event : TGuid) : string;
var
  hr  : HResult;
  isBroadcastEvent : bool;
  eventOptions : IPortableDeviceValues;
begin
  hr:=capabilities.GetEventOptions(event,eventOptions);
  if succeeded(hr) then begin
    Result:='Event Options: ';
    hr:=eventOptions.GetBoolValue(WPD_EVENT_OPTION_IS_BROADCAST_EVENT,isBroadcastEvent);
    if succeeded(hr) then Result:=Result+Format('WPD_EVENT_OPTION_IS_BROADCAST_EVENT = %s',[BoolToStr(isBroadcastEvent,true)])
    else Result:=Result+ErrorMsg('Failed to get WPD_EVENT_OPTION_IS_BROADCAST_EVENT (assuming FALSE)',hr);
    end
  else Result:=ErrorMsg('Failed to get event options',hr);
  end;

// Display all content types contained in an IPortableDevicePropVariantCollection
// NOTE: These values are assumed to be in VT_CLSID VarType format.
procedure DisplayContentTypes (contentTypes : IPortableDevicePropVariantCollection);
var
  hr   : HResult;
  nc,i : cardinal;
  contentType : TPropVariant;
begin
  if contentTypes=nil then begin
    WriteErrMsg ('A nullptr IPortableDevicePropVariantCollection interface pointer was received');
    Exit;
    end;
  // Get the total number of content types in the collection.
  hr:=contentTypes.GetCount(nc);
  if succeeded(hr) then begin
    // Loop through the collection and displaying each content type found.
    // This loop prints a comma-separated list of the content types.
    if nc>0 then for i:=0 to nc-1 do begin
      hr:=contentTypes.GetAt(i,contentType);
      if succeeded(hr) then begin
        // We have a content type.  It is assumed that
        // content types are returned as VT_CLSID varTypes.
        if (contentType.vt=VT_CLSID) and (contentType.pwszVal<>nil) then begin
          // Display the content types separated by commas
          write(ContenTypeAsString(contentType.puuid^));
          if i+1<nc then write(',');
          end
        else WriteErrMsg ('Invalid functional object identifier found');
        end;
      PropVariantClear(contentType);
      end
    else write('<no functional objects found>');
    end;
  end;

// Display all functional object identifiers contained in an IPortableDevicePropVariantCollection
// NOTE: These values are assumed to be in VT_LPWSTR VarType format.
procedure DisplayFunctionalObjectIDs (functionalObjectIDs : IPortableDevicePropVariantCollection);
var
  hr   : HResult;
  nc,i : cardinal;
  objectID   : TPropVariant;
begin
  // Get the total number of object identifiers in the collection.
  hr:=functionalObjectIDs.GetCount(nc);
  if succeeded(hr) then begin
    // Loop through the collection and displaying each object identifier found.
    // This loop prints a comma-separated list of the object identifiers.
    if nc>0 then for i:=0 to nc-1 do begin
      hr:=functionalObjectIDs.GetAt(i,objectID);
      if succeeded(hr) then begin
        // We have a functional object identifier.  It is assumed that
        // object identifiers are returned as VT_LPWSTR varTypes.
        if (objectID.vt=VT_LPWSTR) and (objectID.pwszVal<>nil) then begin
          // Display the object identifiers separated by commas
          write(Format('%s',[objectID.pwszVal]));
          if i+1<nc then write(',');
          end
        else WriteErrMsg ('Invalid functional object identifier found');
        end;
      PropVariantClear(objectID);
      end
    else write('<no functional objects found>');
    end;
  end;

// List supported content types the device supports
procedure ListSupportedContentTypes (device : IPortableDevice);
var
  hr   : HResult;
  nc,i : cardinal;
  pv   : TPropVariant;
  capabilities  : IPortableDeviceCapabilities;
  functionalCategories,
  contentTypes  : IPortableDevicePropVariantCollection;
begin
  // Get an IPortableDeviceCapabilities interface from the IPortableDevice interface to
  // access the device capabilities-specific methods.
  hr:=device.Capabilities(capabilities);
  if failed(hr) then WriteErrMsg('Failed to get IPortableDeviceCapabilities from IPortableDevice',hr)
  else begin
    // Get all functional categories supported by the device.
    // We will use these categories to enumerate functional objects
    // that fall within them.
    hr:=capabilities.GetFunctionalCategories(functionalCategories);
    if failed(hr) then WriteErrMsg ('Failed to get functional categories from the device',hr)
    else begin
      // Get the number of functional categories found on the device.
      hr:=functionalCategories.GetCount(nc);
      if failed(hr) then WriteErrMsg ('Failed to get number of functional categories',hr)
      else begin
        writeln(Format('%u Functional Categories found on the device',[nc]));
        // Loop through each functional category and display its name and supported content types.
        if nc>0 then for i:=0 to nc-1 do begin
          hr:=functionalCategories.GetAt(i,pv);
          if succeeded(hr) then begin
            // We have a functional category.  It is assumed that
            // functional categories are returned as VT_CLSID varTypes.
            if (pv.vt=VT_CLSID) and (pv.puuid<>nil) then begin
              // Display the functional category name
              writeln('Functional Category: ',FunctionalCategoryAsString(pv.puuid^));
              // Display the content types supported for this category
              hr:=capabilities.GetSupportedContentTypes(pv.puuid^,contentTypes);
              if succeeded(hr) then begin
                write('Supported Content Types: ');
                DisplayContentTypes(contentTypes);
                writeln;
                end
              else WriteErrMsg ('Failed to get functional objects',hr);
              end
            else WriteErrMsg ('Invalid functional category found');
            end;
          PropVariantClear(pv);
          end;
        end;
      end;
    end;
  end;

// List all functional objects on the device
procedure ListFunctionalObjects (device : IPortableDevice);
var
  hr   : HResult;
  nc   : cardinal;
  i    : integer;
  pv   : TPropVariant;
  capabilities  : IPortableDeviceCapabilities;
  functionalCategories,
  functionalObjectIDs   : IPortableDevicePropVariantCollection;
begin
  // Get an IPortableDeviceCapabilities interface from the IPortableDevice interface to
  // access the device capabilities-specific methods.
  hr:=device.Capabilities(capabilities);
  if failed(hr) then WriteErrMsg('Failed to get IPortableDeviceCapabilities from IPortableDevice',hr)
  else begin
    // Get all functional categories supported by the device.
    // We will use these categories to enumerate functional objects
    // that fall within them.
    hr:=capabilities.GetFunctionalCategories(functionalCategories);
    if failed(hr) then WriteErrMsg ('Failed to get functional categories from the device',hr)
    else begin
      // Get the number of functional categories found on the device.
      hr:=functionalCategories.GetCount(nc);
      if failed(hr) then WriteErrMsg ('Failed to get number of functional categories',hr)
      else begin
        writeln(Format('%u Functional Categories found on the device',[nc]));
        // Loop through each functional category and get the list of
        // functional object identifiers associated with a particular
        // category.
        for i:=0 to nc-1 do begin
          hr:=functionalCategories.GetAt(i,pv);
          if succeeded(hr) then begin
            // We have a functional category.  It is assumed that
            // functional categories are returned as VT_CLSID varTypes.
            if (pv.vt=VT_CLSID) and (pv.puuid<>nil) then begin
              // Display the functional category name
              writeln('Functional Category: ',FunctionalCategoryAsString(pv.puuid^));
              // Display the object identifiers for all
              // functional objects within this category
              hr:=capabilities.GetFunctionalObjects(pv.puuid^,functionalObjectIDs);
              if succeeded(hr) then begin
                write('Functional Objects: ');
                DisplayFunctionalObjectIDs(functionalObjectIDs);
                writeln;
                end
              else WriteErrMsg ('Failed to get functional objects',hr);
              end
            else WriteErrMsg ('Invalid functional category found');
            end;
          PropVariantClear(pv);
          end;
        end;
      end;
    end;
  end;

// List all functional categories on the device
procedure ListFunctionalCategories (device : IPortableDevice);
var
  hr   : HResult;
  nc,i : cardinal;
  pv   : TPropVariant;
  capabilities  : IPortableDeviceCapabilities;
  functionalCategories : IPortableDevicePropVariantCollection;
begin
  // Get an IPortableDeviceCapabilities interface from the IPortableDevice interface to
  // access the device capabilities-specific methods.
  hr:=device.Capabilities(capabilities);
  if failed(hr) then WriteErrMsg('Failed to get IPortableDeviceCapabilities from IPortableDevice',hr)
  else begin
    // Get all functional categories supported by the device.
    hr:=capabilities.GetFunctionalCategories(functionalCategories);
    if failed(hr) then WriteErrMsg ('Failed to get functional categories from the device',hr)
    else begin
      // Get the number of functional categories found on the device.
      hr:=functionalCategories.GetCount(nc);
      if failed(hr) then WriteErrMsg ('Failed to get number of functional categories',hr)
      else begin
        writeln(Format('%u Functional Categories found on the device',[nc]));
        // Loop through each functional category and display its name
        if nc>0 then for i:=0 to nc-1 do begin
          hr:=functionalCategories.GetAt(i,pv);
          if succeeded(hr) then begin
            // We have a functional category.  It is assumed that
            // functional categories are returned as VT_CLSID varTypes.
            if (pv.vt=VT_CLSID) and (pv.puuid<>nil) then
               // Display the functional category name
               writeln('  ',FunctionalCategoryAsString(pv.puuid^));
            end;
          PropVariantClear(pv);
          end;
        end;
      end;
    end;
  end;

// Determines if a device supports a particular functional category.
function SupportsFunctionalCategory (device : IPortableDevice; const functionalCategory : TGuid) : boolean;
var
  hr   : HResult;
  nc,i : cardinal;
  pv   : TPropVariant;
  capabilities  : IPortableDeviceCapabilities;
  functionalCategories  : IPortableDevicePropVariantCollection;
begin
  Result:=false;
  // Get an IPortableDeviceCapabilities interface from the IPortableDevice interface to
  // access the device capabilities-specific methods.
  hr:=device.Capabilities(capabilities);
  if failed(hr) then WriteErrMsg('Failed to get IPortableDeviceCapabilities from IPortableDevice',hr)
  else begin
    // Get all functional categories supported by the device.
    // We will use these categories to search for a particular functional category.
    // There is typically only 1 of these types of functional categories.
    hr:=capabilities.GetFunctionalCategories(functionalCategories);
    if failed(hr) then WriteErrMsg('Failed to get functional categories from the device',hr)
    else begin
      // Get the number of functional categories found on the device.
      hr:=functionalCategories.GetCount(nc);
      if failed(hr) then WriteErrMsg('Failed to get umber of functional categories',hr)
      else begin
        // Loop through each functional category and find the passed in category
        if nc>0 then for i:=0 to nc-1 do begin
          hr:=functionalCategories.GetAt(i,pv);
          if succeeded(hr) then begin
            // We have a functional category.  It is assumed that
            // functional categories are returned as VT_CLSID varTypes.
            if (pv.vt=VT_CLSID) and (pv.puuid<>nil) then Result:=functionalCategory=pv.puuid^
            else WriteErrMsg('Invalid functional category found');
            end;
          PropVariantClear(pv);
          // If the device supports the category, exit the for loop.
          // NOTE: We are exiting after calling PropVariantClear to make
          // sure we free any allocated data in the PROPVARIANT returned
          // from the GetAt() method call.
          if Result then Break;
          end;
        end;
      end;
    end;
  end;

// Determines if a device supports a particular command.
function SupportsCommand (device : IPortableDevice; command : TPropertyKey) : boolean;
var
  hr  : HResult;
  nc,i : cardinal;
  key  : TPropertyKey;
  capabilities  : IPortableDeviceCapabilities;
  commands : IPortableDeviceKeyCollection;
begin
  Result:=false;
  // Get an IPortableDeviceCapabilities interface from the IPortableDevice interface to
  // access the device capabilities-specific methods.
  hr:=device.Capabilities(capabilities);
  if failed(hr) then WriteErrMsg('Failed to get IPortableDeviceCapabilities from IPortableDevice',hr)
  else begin
    // Get all commands supported by the device.
    // We will use these commands to search for a particular functional category.
    hr:=capabilities.GetSupportedCommands(commands);
    if failed(hr) then WriteErrMsg('Failed to get supported commands from the device',hr)
    else begin
      // Get the number of supported commands found on the device.
      hr:=commands.GetCount(nc);
      if failed(hr) then WriteErrMsg('Failed to get number of supported commands',hr)
      else begin
        // Loop through each functional category and find the passed in category
        if nc>0 then for i:=0 to nc-1 do begin
          hr:=commands.GetAt(i,key);
          if succeeded(hr) then begin
            Result:=command=key;
            if Result then Break;
            end;
          end;
        end;
      end;
    end;
  end;

// Reads the WPD_RENDERING_INFORMATION_PROFILES properties on the device.
function ReadProfileInformationProperties (device : IPortableDevice; const functionalObjectID : string;
                                           var renderingInfoProfiles : IPortableDeviceValuesCollection) : HResult;
var
  thr  : HResult;
  renderingInfoProfilesTemp : IPortableDeviceValuesCollection;
  content : IPortableDeviceContent;
  properties  : IPortableDeviceProperties;
  propertiesToRead : IPortableDeviceKeyCollection;
  objectProperties     : IPortableDeviceValues;
begin
  // Get an IPortableDeviceContent interface from the IPortableDevice interface to
  // access the content-specific methods.
  Result:=device.Content(content);
  if failed(Result) then WriteErrMsg('Failed to get IPortableDeviceContent from IPortableDevice',Result)
  else begin
    // Get an IPortableDeviceProperties interface from the IPortableDeviceContent interface
    // to access the property-specific methods.
    Result:=Content.Properties(properties);
    if failed(Result) then WriteErrMsg ('Failed to get IPortableDeviceProperties from IPortableDevice',Result)
    else begin
      // CoCreate an IPortableDeviceKeyCollection interface to hold the the property keys
      // we wish to read WPD_RENDERING_INFORMATION_PROFILES)
      Result:=CoCreateInstance(CLSID_PortableDeviceKeyCollection,nil,CLSCTX_INPROC_SERVER,
                      IPortableDeviceKeyCollection,propertiesToRead);
      if succeeded(Result) then begin
        // Populate the IPortableDeviceKeyCollection with the keys we wish to read.
        // NOTE: We are not handling any special error cases here so we can proceed with
        // adding as many of the target properties as we can.
        thr:=propertiesToRead.Add(WPD_RENDERING_INFORMATION_PROFILES);
        if failed(thr) then WriteErrMsg ('Failed to add WPD_RENDERING_INFORMATION_PROFILES to IPortableDeviceKeyCollection',thr)
        end;
      // Call GetValues() passing the collection of specified PROPERTYKEYs.
      if succeeded(Result) then begin
        Result:=properties.GetValues(PChar(functionalObjectID), // The object whose properties we are reading
                           propertiesToRead,                       // The properties we want to read
                           objectProperties);                      // Driver supplied property values for the specified object
        if failed(Result) then WriteErrMsg (Format('Failed to get all properties for object "%s"',[functionalObjectID]),Result);
        end;
      // Read the WPD_RENDERING_INFORMATION_PROFILES
      if succeeded(Result) then begin
        Result:=objectProperties.GetIPortableDeviceValuesCollectionValue(WPD_RENDERING_INFORMATION_PROFILES,renderingInfoProfilesTemp);
        if failed(Result) then WriteErrMsg ('Failed to get WPD_RENDERING_INFORMATION_PROFILES from rendering information',Result);
        end;
      // QueryInterface the interface into the out-going parameters.
      if succeeded(Result) then renderingInfoProfiles:=renderingInfoProfilesTemp;
      end;
    end;
  end;

procedure DisplayExpectedValues (expectedValues : IPortableDeviceValues);
var
  hr   : HResult;
  formAttribute,
  rangeMin,rangeMax,
  rangeStep          : cardinal;
begin
  formAttribute:=WPD_PROPERTY_ATTRIBUTE_FORM_UNSPECIFIED;
  // 1) Determine what type of valid values should be displayed by reading the
  //    WPD_PROPERTY_ATTRIBUTE_FORM property.
  hr:=expectedValues.GetUnsignedIntegerValue(WPD_PROPERTY_ATTRIBUTE_FORM,formAttribute);
  if failed(hr) then WriteErrMsg ('Failed to get WPD_PROPERTY_ATTRIBUTE_FORM from expected value set',hr)
  else begin
    rangeMin:=0; rangeMax:=0; rangeStep:=0;
    case formAttribute of
    WPD_PROPERTY_ATTRIBUTE_FORM_RANGE : begin
      hr:=expectedValues.GetUnsignedIntegerValue(WPD_PROPERTY_ATTRIBUTE_RANGE_MIN,rangeMin);
      if failed(hr) then WriteErrMsg ('Failed to get WPD_PROPERTY_ATTRIBUTE_RANGE_MIN from expected values collection',hr);
      hr:=expectedValues.GetUnsignedIntegerValue(WPD_PROPERTY_ATTRIBUTE_RANGE_MAX,rangeMax);
      if failed(hr) then WriteErrMsg ('Failed to get WPD_PROPERTY_ATTRIBUTE_RANGE_MAX from expected values collection',hr);
      hr:=expectedValues.GetUnsignedIntegerValue(WPD_PROPERTY_ATTRIBUTE_RANGE_STEP,rangeStep);
      if failed(hr) then WriteErrMsg ('Failed to get WPD_PROPERTY_ATTRIBUTE_RANGE_STEP from expected values collection',hr);
      writeln(Format('MIN: %u, MAX: %u, STEP: %u',[rangeMin,rangeMax,rangeStep]));
      end;
    else writeln(Format('DisplayExpectedValues helper function did not display attributes for form %u',[formAttribute]));
      end;
    end;
  end;

// Displays a rendering profile.
procedure DisplayRenderingProfile (profile : IPortableDeviceValues);
var
  hr   : HResult;
  totalBitrate,
  channelCount,
  audioFormatCode : cardinal;
  expectedValues  : IPortableDeviceValues;
  objectFormat    : TGuid;
begin
  // Display WPD_MEDIA_TOTAL_BITRATE
  hr:=profile.GetUnsignedIntegerValue(WPD_MEDIA_TOTAL_BITRATE,totalBitrate);
  if succeeded(hr) then writeln(Format('Total Bitrate: %u',[totalBitrate]))
  else if hr=DISP_E_TYPEMISMATCH then begin
    hr:=profile.GetIPortableDeviceValuesValue(WPD_MEDIA_TOTAL_BITRATE,expectedValues);
    if succeeded(hr) then begin
      write('Total Bitrate: ');
      DisplayExpectedValues(expectedValues);
      end
    // If we are still a failure here, report the error
    else WriteErrMsg ('Failed to get WPD_MEDIA_TOTAL_BITRATE from rendering profile',hr);
    end;
  // Display WPD_AUDIO_CHANNEL_COUNT
  hr:=profile.GetUnsignedIntegerValue(WPD_AUDIO_CHANNEL_COUNT,channelCount);
  if succeeded(hr) then writeln(Format('Channel Count: %u',[channelCount]))
  else WriteErrMsg ('Failed to get WPD_AUDIO_CHANNEL_COUNT from rendering profile',hr);
  // Display WPD_AUDIO_FORMAT_CODE
  hr:=profile.GetUnsignedIntegerValue(WPD_AUDIO_FORMAT_CODE,audioFormatCode);
  if succeeded(hr) then writeln(Format('Audio Format Code: %u',[audioFormatCode]))
  else WriteErrMsg ('Failed to get WPD_AUDIO_FORMAT_CODE from rendering profile',hr);
  // Display WPD_OBJECT_FORMAT
  objectFormat:=WPD_OBJECT_FORMAT_UNSPECIFIED;
  hr:=profile.GetGuidValue(WPD_OBJECT_FORMAT,objectFormat);
  if succeeded(hr) then writeln(Format('Object Format: %s',[GuidToString(objectFormat)]))
  else WriteErrMsg ('Failed to get WPD_OBJECT_FORMAT from rendering profile',hr);
  end;

// List rendering capabilities the device supports
procedure ListRenderingCapabilityInformation (device : IPortableDevice);
var
  hr   : HResult;
  nc,i : cardinal;
  pv   : TPropVariant;
  capabilities  : IPortableDeviceCapabilities;
  renderingInfoObjects  : IPortableDevicePropVariantCollection;
  renderingInfoProfiles  : IPortableDeviceValuesCollection;
  profiles  : IPortableDeviceValues;
begin
  if not SupportsFunctionalCategory(device,WPD_FUNCTIONAL_CATEGORY_RENDERING_INFORMATION) then
    writeln('This device does not support device rendering information to display')
  else begin
    // Get an IPortableDeviceCapabilities interface from the IPortableDevice interface to
    // access the device capabilities-specific methods.
    hr:=device.Capabilities(capabilities);
    if failed(hr) then WriteErrMsg('Failed to get IPortableDeviceCapabilities from IPortableDevice',hr)
    else begin
      // Get the functional object identifier for the rendering information object
      hr:=capabilities.GetFunctionalObjects(WPD_FUNCTIONAL_CATEGORY_RENDERING_INFORMATION,renderingInfoObjects);
      if failed(hr) then WriteErrMsg ('Failed to get functional objects',hr)
      else begin
        // Assume the device only has one rendering information object for this example.
        // We are going to request the first Object Identifier found in the collection.
        hr:=renderingInfoObjects.GetAt(0,pv);
        if succeeded(hr) and (pv.vt=VT_LPWSTR) and (pv.pwszVal<>nil) then begin
          hr:=ReadProfileInformationProperties(device,pv.pwszVal,renderingInfoProfiles);
          // Error output statements are performed by the helper function, so they
          // are omitted here.

          // Display all rendering profiles
          if succeeded(hr) then begin
            // Get the number of profiles supported by the device
            hr:=renderingInfoProfiles.GetCount(nc);
            if failed(hr) then WriteErrMsg ('Failed to get number of profiles supported by the device',hr);
            writeln(Format('%u Rendering Profiles are supported by this device',[nc]));
            if succeeded(hr) then begin
              if nc>0 then for i:=0 to nc-1 do begin
                hr:=renderingInfoProfiles.GetAt(i,profiles);
                if succeeded(hr) then begin
                  writeln(Format('Profile #%u:',[i]));
                  DisplayRenderingProfile(profiles);
                  writeln;
                  end
                else WriteErrMsg (Format('Failed to get rendering profile at index "%u"',[i]),hr)
                end;
              end;
            end;
          end
        else WriteErrMsg ('Failed to get first rendering object''s identifier',hr);
        PropVariantClear(pv);
        end;
      end;
    end;
  end;

// List all supported events on the device
procedure ListSupportedEvents (device : IPortableDevice);
var
  hr   : HResult;
  nc,i : cardinal;
  pv   : TPropVariant;
  capabilities  : IPortableDeviceCapabilities;
  events  : IPortableDevicePropVariantCollection;
begin
  // Get an IPortableDeviceCapabilities interface from the IPortableDevice interface to
  // access the device capabilities-specific methods.
  hr:=device.Capabilities(capabilities);
  if failed(hr) then WriteErrMsg('Failed to get IPortableDeviceCapabilities from IPortableDevice',hr)
  else begin
    // Get all events supported by the device.
    hr:=capabilities.GetSupportedEvents(events);
    if failed(hr) then WriteErrMsg ('Failed to get supported events from the device',hr)
    else begin
      // Get the number of supported events found on the device.
      hr:=events.GetCount(nc);
      if failed(hr) then WriteErrMsg ('Failed to get number of supported events',hr);
      end;
    writeln(Format('%u Supported Events found on the device',[nc]));
    // Loop through each event and display its name
    if succeeded(hr) then begin
      if nc>0 then for i:=0 to nc-1 do begin
        hr:=events.GetAt(i,pv);
        if succeeded(hr) then begin
          // We have an event.  It is assumed that
          // events are returned as VT_CLSID varTypes.
          if (pv.vt=VT_CLSID) and (pv.puuid<>nil) then begin
            writeln(EventAsString(pv.puuid^));
            writeln(EventOptionsAsString(capabilities,pv.puuid^));
            end
          end;
        PropVariantClear(pv);
        end;
      end;
    end;
  end;

//===================================================================
// from "ContentEnumeration.cpp"

// Recursively called function which enumerates using the specified
// object identifier as the parent and populates the returned object
// identifiers into an IPortableDevicePropVariantCollection object.
procedure RecursiveEnumerateAndCopyToCollection(const objectID : string;
    content : IPortableDeviceContent; objectIDs : IPortableDevicePropVariantCollection);
var
  hr   : HResult;
  numFetched,i : cardinal;
  pv   : TPropVariant;
  enumObjectIDs : IEnumPortableDeviceObjectIDs;
  objectIDArray : TCharArray;
begin
  // Allocated a new string in a PROPVARIANT so we can add it to our
  // collection object.
  hr:=InitPropVariantFromString(PChar(objectID),pv);
  if failed(hr) then begin
    WriteErrMsg (Format('Failed to copy object identifier "%s"',[objectID]),hr); Exit;
    end;
  // Add the object identifier...
  hr:=objectIDs.Add(pv);
  // Free the allocated string in the PROPVARIANT
  PropVariantClear(pv);
  // If we failed to add the object identifier, return immediately.
  if failed(hr) then begin
    WriteErrMsg (Format('Failed to add object identifier "%s" to the IPortableDevicePropVariantCollection',[objectID]),hr); Exit;
    end;
  // Get an IEnumPortableDeviceObjectIDs interface by calling EnumObjects with the
  // specified parent object identifier.
  hr:=content.EnumObjects(0,PChar(objectID),nil,enumObjectIDs);
  if failed(hr) then WriteErrMsg ('Failed to get IEnumPortableDeviceObjectIDs from IPortableDeviceContent',hr);
  // Loop calling Next() while S_OK is being returned.
  while hr=S_OK do begin
    SetLength(objectIDArray,NUM_OBJECTS_TO_REQUEST);
    hr:=enumObjectIDs.Next (NUM_OBJECTS_TO_REQUEST, // Number of objects to request on each Next() call
                   objectIDArray[0],                // PWSTR array which will be populated on each Next() call
                   numFetched);                     // Number of objects written to the PWSTR array
    if succeeded(hr) then begin
      // Traverse the results of the Next() operation and recursively enumerate
      // Remember to free all returned object identifiers using CoTaskMemFree()
      if numFetched>0 then for i:=0 to numFetched-1 do if objectIDArray[i]<>nil then begin
        RecursiveEnumerateAndCopyToCollection(objectIDArray[i],Content,objectIDs);
        CoTaskMemFree(objectIDArray[i]); objectIDArray[i]:=nil;
        end;
      end;
    objectIDArray:=nil;
    end;
  end;

// Enumerate all content on the device starting with the
// "DEVICE" object and populates the returned object identifiers
// into an IPortableDevicePropVariantCollection
function CreateIPortableDevicePropVariantCollectionWithAllObjectIDs(content : IPortableDeviceContent;
    out objectIDs : IPortableDevicePropVariantCollection) : HResult;
begin
  // CoCreate an IPortableDevicePropVariantCollection interface to hold the the object identifiers
  Result:=CoCreateInstance(CLSID_PortableDevicePropVariantCollection,nil,CLSCTX_INPROC_SERVER,
                       IID_IPortableDevicePropVariantCollection,objectIDs);
  if succeeded(Result) then begin
        RecursiveEnumerateAndCopyToCollection(WPD_DEVICE_OBJECT_ID,content,objectIDs);
    end;
  end;

//===================================================================
// from "ContentProperties.cpp"

// Get a property assumed to be in string form - refer to "DisplayStringProperty"
function StringPropertyAsString (properties : IPortableDeviceValues; key : TPropertyKey; const keyname : string) : string;
var
  hr  : HResult;
  value : PWideChar;
begin
  hr:=properties.GetStringValue(key,value);
  if succeeded(hr) then begin
    // Get the length of the string value so we
    // can output <empty string value> if one is encountered.
    if length(keyname)=0 then begin
      if length(value)>0 then Result:=value
      else Result:='<empty string value>';
      end
    else begin
      if length(value)>0 then Result:=Format('%s: %s',[keyname,value])
      else Result:=Format('%s: <empty string value>',[keyname]);
      end;
  // Free the allocated string returned from the
  // GetStringValue method
    end
  else Result:=Format('%s: <Not Found>',[keyname]);
  CoTaskMemFree(value); value:=nil;
  end;

// Get a property assumed to be in GUID form - refer to "DisplayGuidProperty"
function GuidPropertyAsString  (properties : IPortableDeviceValues; key : TPropertyKey; const keyname : string) : string;
var
  hr  : HResult;
  value : TGuid;
begin
  hr:=properties.GetGuidValue(key,value);
  if succeeded(hr) then Result:=Format('%s: %s',[keyname,value.ToString])
  else Result:=Format('%s: <Not Found>',[keyname]);
  end;

//-------------------------------------------------------------------
// IPortableDevicePropertiesBulkCallback implementation for use with
// IPortableDevicePropertiesBulk operations.
type
  TGetBulkValuesCallback = class (TInterfacedObject, IPortableDevicePropertiesBulkCallback)
  public
    function OnStart(const pContext: TGuid): HResult; stdcall;
    function OnProgress(const pContext: TGuid; pResults: IPortableDeviceValuesCollection): HResult; stdcall;
    function OnEnd(const pContext: TGuid; hrStatus: HResult): HResult; stdcall;
    end;

function TGetBulkValuesCallback.OnStart(const pContext: TGuid): HResult; stdcall;
begin
  writeln(Format('*** BULK Property operation starting, context = %s',[pContext.ToString]));
  Result:=S_OK;
  end;

function TGetBulkValuesCallback.OnProgress(const pContext: TGuid; pResults: IPortableDeviceValuesCollection): HResult; stdcall;
var
  i,n : cardinal;
  objectProperties : IPortableDeviceValues;
begin
  Result:=pResults.GetCount(n);
  // Display the returned properties to the user.
  // NOTE: We are reading for expected properties, which were setup in the
  // QueueGetXXXXXX bulk operation call.
  if succeeded(Result) then begin
    writeln(Format('Received next batch of %u object value elements..., context = %s',[n,pContext.ToString]));
    if n>0 then for i:=0 to n-1 do begin
      Result:=pResults.GetAt(i,objectProperties);
      if succeeded(Result) then begin
        writeln(StringPropertyAsString(objectProperties,WPD_OBJECT_PARENT_ID,'WPD_OBJECT_PARENT_ID'));
        writeln(StringPropertyAsString(objectProperties,WPD_OBJECT_ID,'WPD_OBJECT_ID'));
        writeln(StringPropertyAsString(objectProperties,WPD_OBJECT_NAME,'WPD_OBJECT_NAME'));
        writeln(StringPropertyAsString(objectProperties,WPD_OBJECT_PERSISTENT_UNIQUE_ID,'WPD_OBJECT_PERSISTENT_UNIQUE_ID'));
        writeln(GuidPropertyAsString (objectProperties,WPD_OBJECT_CONTENT_TYPE,'WPD_OBJECT_CONTENT_TYPE'));
        writeln(GuidPropertyAsString (objectProperties,WPD_OBJECT_FORMAT,'WPD_OBJECT_FORMAT'));
        writeln;
        end
      else WriteErrMsg(Format('Failed to get IPortableDeviceValues from IPortableDeviceValuesCollection at index "%u"',[i]),Result);
      end;
    end;
  end;

function TGetBulkValuesCallback.OnEnd(const pContext: TGuid; hrStatus: HResult): HResult; stdcall;
begin
  writeln(Format('*** BULK Property operation ending, context = %s',[pContext.ToString]));
  writeln(Format('    status = $%.8x: ',[hrStatus,SysErrorMessage(hrStatus)]));
  // This assumes that we are only performing a single operation
  // at a time, so no check is needed on the context when setting
  // the operation complete event.
  if BulkPropertyOperationEvent<>0 then SetEvent(BulkPropertyOperationEvent);
  Result:=S_OK;
  end;

//-------------------------------------------------------------------
// Reads a set of properties for all objects.
procedure ReadContentPropertiesBulk (device : IPortableDevice);
var
  hr,thr   : HResult;
  callback : TGetBulkValuesCallback;
  Content : IPortableDeviceContent;
  Properties : IPortableDeviceProperties;
  PropertiesBulk : IPortableDevicePropertiesBulk;
  PropertiesToRead : IPortableDeviceKeyCollection;
  objectIDs : IPortableDevicePropVariantCollection;
  context : TGuid;
begin
  // 1) Get an IPortableDeviceContent interface from the IPortableDevice interface to
  // access the content-specific methods.
  hr:=device.Content(content);
  if failed(hr) then WriteErrMsg ('Failed to get IPortableDeviceContent from IPortableDevice',hr)
  else begin
    // 2) Get an IPortableDeviceProperties interface from the IPortableDeviceContent interface
    // to access the property-specific methods.
    hr:=Content.Properties(Properties);
    if failed(hr) then WriteErrMsg ('Failed to get IPortableDeviceProperties from IPortableDevice',hr)
    else begin
    // 3) Check to see if the driver supports BULK property operations by call QueryInterface
    // on the IPortableDeviceProperties interface for IPortableDevicePropertiesBulk
      hr:=Properties.QueryInterface(IID_IPortableDevicePropertiesBulk,PropertiesBulk);
      if failed(hr) then WriteErrMsg ('This driver does not support BULK property operations.',hr);
      end;
    // 4) CoCreate an IPortableDeviceKeyCollection interface to hold the the property keys
    // we wish to read.
    if succeeded(hr) then begin
      hr:=CoCreateInstance(CLSID_PortableDeviceKeyCollection,nil,
                           CLSCTX_INPROC_SERVER,IPortableDeviceKeyCollection,PropertiesToRead);
      if failed(hr) then WriteErrMsg ('Failed to CoCreate IPortableDeviceKeyCollection to hold the property keys to read',hr);
      end;
    if succeeded(hr) then begin
      // 5) Populate the IPortableDeviceKeyCollection with the keys we wish to read.
      // NOTE: We are not handling any special error cases here so we can proceed with
      // adding as many of the target properties as we can.
      thr:=PropertiesToRead.Add(WPD_OBJECT_PARENT_ID);
      if failed(thr) then WriteErrMsg ('Failed to add WPD_OBJECT_PARENT_ID to IPortableDeviceKeyCollection',thr);
      thr:=PropertiesToRead.Add(WPD_OBJECT_ID);
      if failed(thr) then WriteErrMsg ('Failed to add WPD_OBJECT_ID to IPortableDeviceKeyCollection',thr);
      thr:=PropertiesToRead.Add(WPD_OBJECT_NAME);
      if failed(thr) then WriteErrMsg ('Failed to add WPD_OBJECT_NAME to IPortableDeviceKeyCollection',thr);
      thr:=PropertiesToRead.Add(WPD_OBJECT_PERSISTENT_UNIQUE_ID);
      if failed(thr) then WriteErrMsg ('Failed to add WPD_OBJECT_PERSISTENT_UNIQUE_ID to IPortableDeviceKeyCollection',thr);
      thr:=PropertiesToRead.Add(WPD_OBJECT_FORMAT);
      if failed(thr) then WriteErrMsg ('Failed to add WPD_OBJECT_FORMAT to IPortableDeviceKeyCollection',thr);
      thr:=PropertiesToRead.Add(WPD_OBJECT_CONTENT_TYPE);
      if failed(thr) then WriteErrMsg ('Failed to add WPD_OBJECT_CONTENT_TYPE to IPortableDeviceKeyCollection',thr);
      end;
    // 6) Create an instance of the IPortableDevicePropertiesBulkCallback object.
    if succeeded(hr) then begin
      callback:=TGetBulkValuesCallback.Create;
      if callback=nil then begin
        hr:=E_OUTOFMEMORY;
        WriteErrMsg ('Failed to allocate memory for TGetBulkValuesCallback object',hr);
        end;
      end;
    // 7) Call our helper function CreateIPortableDevicePropVariantCollectionWithAllObjectIDs
    // to enumerate and create an IPortableDevicePropVariantCollection with the object
    // identifiers needed to perform the bulk operation on.
    if succeeded(hr) then hr:=CreateIPortableDevicePropVariantCollectionWithAllObjectIDs(content,objectIDs);
    // 8) Call QueueGetValuesByObjectList to initialize the Asynchronous
    // property operation.
    if succeeded(hr) then begin
      hr:=PropertiesBulk.QueueGetValuesByObjectList(objectIDs,PropertiesToRead,callback,context);
      // 9) Call Start() to actually begin the property operation
      if succeeded(hr) then begin
        // Cleanup any previously created global event handles.
        if BulkPropertyOperationEvent<>0 then begin
          CloseHandle(BulkPropertyOperationEvent); BulkPropertyOperationEvent:=0;
          end;
        // In order to create a simpler to follow example we create and wait infinitly
        // for the bulk property operation to complete and ignore any errors.
        // Production code should be written in a more robust manner.
        // Create the global event handle to wait on for the bulk operation
        // to complete.
        BulkPropertyOperationEvent:=CreateEvent(nil,false,false,nil);
        if BulkPropertyOperationEvent<>0 then begin
          // Call Start() to actually begin the Asynchronous bulk operation.
          hr:=PropertiesBulk.Start(context);
          if failed(hr) then WriteErrMsg ('Failed to start property operation',hr)
          end
        else WriteErrMsg ('Failed to create the global event handle to wait on for the bulk operation. Aborting operation',hr);
        end
      else WriteErrMsg ('QueueGetValuesByObjectList Failed',hr);
      end;
    // In order to create a simpler to follow example we will wait infinitly for the operation
    // to complete and ignore any errors.  Production code should be written in a more
    // robust manner.
    if succeeded(hr) then begin
      if BulkPropertyOperationEvent<>0 then WaitForSingleObject(BulkPropertyOperationEvent,INFINITE);
      end;
    // Cleanup any created global event handles before exiting..
    if BulkPropertyOperationEvent<>0 then begin
      CloseHandle(BulkPropertyOperationEvent); BulkPropertyOperationEvent:=0;
      end;
    end;
  end;

// Writes a set of properties for all objects.
procedure WriteContentPropertiesBulk (device : IPortableDevice);
var
  hr       : HResult;
  nc,i     : cardinal;
  nn       : string;
  context  : TGuid;
  objectID : TPropVariant;
  callback : TGetBulkValuesCallback;
  Content : IPortableDeviceContent;
  Properties : IPortableDeviceProperties;
  PropertiesBulk : IPortableDevicePropertiesBulk;
  PropertiesToWrite : IPortableDeviceValuesCollection;
  objectIDs : IPortableDevicePropVariantCollection;
  newvalues : IPortableDeviceValues;
begin
  // 1) Get an IPortableDeviceContent interface from the IPortableDevice interface to
  // access the content-specific methods.
  hr:=device.Content(content);
  if failed(hr) then WriteErrMsg ('Failed to get IPortableDeviceContent from IPortableDevice',hr)
  else begin
    // 2) Get an IPortableDeviceProperties interface from the IPortableDeviceContent interface
    // to access the property-specific methods.
    hr:=Content.Properties(Properties);
    if failed(hr) then WriteErrMsg ('Failed to get IPortableDeviceProperties from IPortableDevice',hr)
    else begin
    // 3) Check to see if the driver supports BULK property operations by call QueryInterface
    // on the IPortableDeviceProperties interface for IPortableDevicePropertiesBulk
      hr:=Properties.QueryInterface(IID_IPortableDevicePropertiesBulk,PropertiesBulk);
      if failed(hr) then WriteErrMsg ('This driver does not support BULK property operations.',hr);
      end;
    // 4) CoCreate an IPortableDeviceValuesCollection interface to hold the the properties
    // we wish to write.
    if succeeded(hr) then begin
      hr:=CoCreateInstance(CLSID_PortableDeviceKeyCollection,nil,
                           CLSCTX_INPROC_SERVER,IPortableDeviceKeyCollection,PropertiesToWrite);
      if failed(hr) then WriteErrMsg ('Failed to CoCreate IPortableDeviceKeyCollection for bulk property values',hr);
      end;
    // 5) Create an instance of the IPortableDevicePropertiesBulkCallback object.
    if succeeded(hr) then begin
      callback:=TGetBulkValuesCallback.Create;
      if callback=nil then begin
        hr:=E_OUTOFMEMORY;
        WriteErrMsg ('Failed to allocate TGetBulkValuesCallback',hr);
        end;
      end;
    // 6) Call our helper function CreateIPortableDevicePropVariantCollectionWithAllObjectIDs
    // to enumerate and create an IPortableDevicePropVariantCollection with the object
    // identifiers needed to perform the bulk operation on.
    if succeeded(hr) then hr:=CreateIPortableDevicePropVariantCollectionWithAllObjectIDs(content,objectIDs);
    if succeeded(hr) then begin
      hr:=objectIDs.GetCount(nc);
      if failed(hr) then WriteErrMsg ('Failed to get number of objectIDs from IPortableDevicePropVariantCollection',hr);
      end;
    // 7) Iterate through object list and add appropriate IPortableDeviceValues to collection
    if succeeded(hr) then begin
      if nc>0 then for i:=0 to nc-1 do begin
        hr:=CoCreateInstance(CLSID_PortableDeviceValues,nil,
                             CLSCTX_INPROC_SERVER,IPortableDeviceValues,newvalues);
        if failed(hr) then WriteErrMsg ('Failed to CoCreate CLSID_PortableDeviceValues',hr);
        // Get the Object ID whose properties we will set
        if hr=S_OK then begin
          hr:=objectIDs.GetAt(i,objectID);
          if failed(hr) then WriteErrMsg ('Failed to get next Object ID from list',hr);
          end;
        // Save them into the IPortableDeviceValues so the driver knows which object this proeprty set belongs to
        if hr=S_OK then begin
          hr:=newvalues.SetStringValue(WPD_OBJECT_ID,objectID.pwszVal);
          if failed(hr) then WriteErrMsg ('Failed to set WPD_OBJECT_ID',hr);
          end;
        // Set the new values.  In this sample, we attempt to set the name property.
        if hr=S_OK then begin
          write(Format('NewName%u',[i])); readln(nn);
          if length(nn)=0 then begin
            hr:=E_ABORT; writeln('The operation was cancelled.');
            end;
          if hr=S_OK then begin
            hr:=newvalues.SetStringValue(WPD_OBJECT_NAME,PChar(nn));
            if failed(hr) then WriteErrMsg ('Failed to set WPD_OBJECT_NAME',hr);
            end;
          end;
        // Add this property set to the collection
        if hr=S_OK then begin
          hr:=PropertiesToWrite.Add(newvalues);
          if failed(hr) then WriteErrMsg ('Failed to add values to collection',hr);
          end;
        PropVariantClear(objectID);
        end;
      end;
    // 8) Call QueueSetValuesByObjectList to initialize the Asynchronous
    // property operation.
    if succeeded(hr) then begin
      hr:=PropertiesBulk.QueueSetValuesByObjectList(PropertiesToWrite,callback,context);
      // 9) Call Start() to actually begin the property operation
      if succeeded(hr) then begin
        // Cleanup any previously created global event handles.
        if BulkPropertyOperationEvent<>0 then begin
          CloseHandle(BulkPropertyOperationEvent); BulkPropertyOperationEvent:=0;
          end;
        // In order to create a simpler to follow example we create and wait infinitly
        // for the bulk property operation to complete and ignore any errors.
        // Production code should be written in a more robust manner.
        // Create the global event handle to wait on for the bulk operation
        // to complete.
        BulkPropertyOperationEvent:=CreateEvent(nil,false,false,nil);
        if BulkPropertyOperationEvent<>0 then begin
          // Call Start() to actually begin the Asynchronous bulk operation.
          hr:=PropertiesBulk.Start(context);
          if failed(hr) then WriteErrMsg ('Failed to start property operation',hr)
          end
        else WriteErrMsg ('Failed to create the global event handle to wait on for the bulk operation. Aborting operation',hr);
        end
      else WriteErrMsg ('QueueGetValuesByObjectList Failed',hr);
      end;
    // In order to create a simpler to follow example we will wait infinitly for the operation
    // to complete and ignore any errors.  Production code should be written in a more
    // robust manner.
    if succeeded(hr) then begin
      if BulkPropertyOperationEvent<>0 then WaitForSingleObject(BulkPropertyOperationEvent,INFINITE);
      end;
    // Cleanup any created global event handles before exiting..
    if BulkPropertyOperationEvent<>0 then begin
      CloseHandle(BulkPropertyOperationEvent); BulkPropertyOperationEvent:=0;
      end;
    end;
  end;

// Reads a set of properties for all objects of a particular format. (e.g. MP3)
procedure ReadContentPropertiesBulkFilteringByFormat (device : IPortableDevice);
var
  hr,thr   : HResult;
  context  : TGuid;
  callback : TGetBulkValuesCallback;
  Content  : IPortableDeviceContent;
  Properties : IPortableDeviceProperties;
  PropertiesBulk : IPortableDevicePropertiesBulk;
  PropertiesToRead : IPortableDeviceKeyCollection;
const
  DEPTH = 100;
begin
  // 1) Get an IPortableDeviceContent interface from the IPortableDevice interface to
  // access the content-specific methods.
  hr:=device.Content(content);
  if failed(hr) then WriteErrMsg ('Failed to get IPortableDeviceContent from IPortableDevice',hr)
  else begin
    // 2) Get an IPortableDeviceProperties interface from the IPortableDeviceContent interface
    // to access the property-specific methods.
    hr:=Content.Properties(Properties);
    if failed(hr) then WriteErrMsg ('Failed to get IPortableDeviceProperties from IPortableDevice',hr)
    else begin
      // 3) Check to see if the driver supports BULK property operations by call QueryInterface
      // on the IPortableDeviceProperties interface for IPortableDevicePropertiesBulk
      hr:=Properties.QueryInterface(IID_IPortableDevicePropertiesBulk,PropertiesBulk);
      if failed(hr) then WriteErrMsg ('This driver does not support BULK property operations.',hr);
      end;
    // 4) CoCreate an IPortableDeviceValuesCollection interface to hold the the properties
    // we wish to write.
    if succeeded(hr) then begin
      hr:=CoCreateInstance(CLSID_PortableDeviceKeyCollection,nil,
                           CLSCTX_INPROC_SERVER,IPortableDeviceKeyCollection,PropertiesToRead);
      if failed(hr) then WriteErrMsg ('Failed to CoCreate IPortableDeviceKeyCollection to hold the property keys to read',hr);
      end;
    if succeeded(hr) then begin
      // 5) Populate the IPortableDeviceKeyCollection with the keys we wish to read.
      // NOTE: We are not handling any special error cases here so we can proceed with
      // adding as many of the target properties as we can.
      if PropertiesToRead<>nil then begin
        thr:=PropertiesToRead.Add(WPD_OBJECT_PARENT_ID);
        if failed(thr) then WriteErrMsg ('Failed to add WPD_OBJECT_PARENT_ID to IPortableDeviceKeyCollection',thr);
        thr:=PropertiesToRead.Add(WPD_OBJECT_NAME);
        if failed(thr) then WriteErrMsg ('Failed to add WPD_OBJECT_NAME to IPortableDeviceKeyCollection',thr);
        thr:=PropertiesToRead.Add(WPD_OBJECT_PERSISTENT_UNIQUE_ID);
        if failed(thr) then WriteErrMsg ('Failed to add WPD_OBJECT_PERSISTENT_UNIQUE_ID to IPortableDeviceKeyCollection',thr);
        thr:=PropertiesToRead.Add(WPD_OBJECT_FORMAT);
        if failed(thr) then WriteErrMsg ('Failed to add WPD_OBJECT_FORMAT to IPortableDeviceKeyCollection',thr);
        thr:=PropertiesToRead.Add(WPD_OBJECT_CONTENT_TYPE);
        if failed(thr) then WriteErrMsg ('Failed to add WPD_OBJECT_CONTENT_TYPE to IPortableDeviceKeyCollection',thr);
        end;
      end;
    // 6) Create an instance of the IPortableDevicePropertiesBulkCallback object.
    if succeeded(hr) then begin
      callback:=TGetBulkValuesCallback.Create;
      if callback=nil then begin
        hr:=E_OUTOFMEMORY;
        WriteErrMsg ('Failed to allocate memory for TGetBulkValuesCallback object',hr);
        end;
      end;
    // 7) Call QueueGetValuesByObjectFormat to initialize the Asynchronous
    // property operation.
    if succeeded(hr) then begin
      hr:=PropertiesBulk.QueueGetValuesByObjectFormat(WPD_OBJECT_FORMAT_MP3,WPD_DEVICE_OBJECT_ID,
                                                      DEPTH,propertiesToRead,callback,context);
      // 9) Call Start() to actually begin the property operation
      if succeeded(hr) then begin
        // Cleanup any previously created global event handles.
        if BulkPropertyOperationEvent<>0 then begin
          CloseHandle(BulkPropertyOperationEvent); BulkPropertyOperationEvent:=0;
          end;
        // In order to create a simpler to follow example we create and wait infinitly
        // for the bulk property operation to complete and ignore any errors.
        // Production code should be written in a more robust manner.
        // Create the global event handle to wait on for the bulk operation
        // to complete.
        BulkPropertyOperationEvent:=CreateEvent(nil,false,false,nil);
        if BulkPropertyOperationEvent<>0 then begin
          // Call Start() to actually begin the Asynchronous bulk operation.
          hr:=PropertiesBulk.Start(context);
          if failed(hr) then WriteErrMsg ('Failed to start property operation',hr)
          end
        else WriteErrMsg ('Failed to create the global event handle to wait on for the bulk operation. Aborting operation',hr);
        end
      else WriteErrMsg ('QueueGetValuesByObjectList Failed',hr);
      end;
    // In order to create a simpler to follow example we will wait infinitly for the operation
    // to complete and ignore any errors.  Production code should be written in a more
    // robust manner.
    if succeeded(hr) then begin
      if BulkPropertyOperationEvent<>0 then WaitForSingleObject(BulkPropertyOperationEvent,INFINITE);
      end;
    // Cleanup any created global event handles before exiting..
    if BulkPropertyOperationEvent<>0 then begin
      CloseHandle(BulkPropertyOperationEvent); BulkPropertyOperationEvent:=0;
      end;
    end;
  end;

//===================================================================
// from "DeviceEvents.cpp"

// IPortableDeviceEventCallback implementation for use with
// device events.
type
  TPortableDeviceEventsCallback = class (TInterfacedObject, IPortableDeviceEventCallback)
  public
    function OnEvent(const eventParameters : IPortableDeviceValues): HResult; stdcall;
    end;

function TPortableDeviceEventsCallback.OnEvent (const eventParameters : IPortableDeviceValues): HResult;
begin
  writeln('"***************************'+sLineBreak+'** Device event received **'+sLineBreak+'***************************');
  writeln(StringPropertyAsString(eventParameters,WPD_EVENT_PARAMETER_PNP_DEVICE_ID,'WPD_EVENT_PARAMETER_PNP_DEVICE_ID'));
  writeln(GuidPropertyAsString(eventParameters,WPD_EVENT_PARAMETER_EVENT_ID,' WPD_EVENT_PARAMETER_EVENT_ID'));
  Result:=S_OK;
  end;

procedure RegisterForEventNotifications (device : IPortableDevice; var eventCookie : string);
var
  hr   : HResult;
  tempEventCookie : PWideChar;
  callback : TPortableDeviceEventsCallback;
begin
  // Check to see if we already have an event registration cookie.  If so,
  // then avoid registering again.
  // NOTE: An application can register for events as many times as they want.
  //       This sample only keeps a single registration cookie around for
  //       simplicity.
  if length(eventCookie)>0 then writeln('This application has already registered to receive device events.')
  else begin
    eventCookie:='';
    // Create an instance of the callback object.  This will be called when events
    // are received.
    callback:=TPortableDeviceEventsCallback.Create;
    if callback=nil then begin
      hr:=E_OUTOFMEMORY;
      WriteErrMsg ('Failed to allocate memory for TPortableDeviceEventsCallback object',hr);
      end
    else hr:=S_OK;
    // Call Advise to register the callback and receive events.
    if (hr=S_OK) then begin
      device.Advise(0,callback,nil,tempEventCookie);
      if failed(hr) then WriteErrMsg ('Failed to register for device events',hr);
      end;
    if (hr=S_OK) then begin
      eventCookie:=tempEventCookie;
      writeln(Format('This application has registered for device event notifications and was returned the registration cookie "%s"',[eventCookie]));
      end;
    CoTaskMemFree(tempEventCookie); tempEventCookie:=nil;
    end;
  end;

procedure UnregisterForEventNotifications (device : IPortableDevice; const eventCookie : string);
var
  hr   : HResult;
begin
  if device<>nil then begin
    hr:=device.Unadvise(PChar(eventCookie));
    if failed(hr) then WriteErrMsg (Format('Failed to unregister for device events using registration cookie "%s"',[eventCookie]),hr)
    else writeln(Format('This application used the registration cookie "%s" to unregister from receiving device event notifications',[eventCookie]));
    end;
  end;

//===================================================================
// new function: get object name from ObjectID  - JR May 2022
function GetObjectInfo (const objectID : string; Content : IPortableDeviceContent) : string;
var
  hr   : HResult;
  objectProperties : IPortableDeviceValues;
  properties  : IPortableDeviceProperties;
  PropertiesToRead : IPortableDeviceKeyCollection;
begin
  Result:='';
  hr:=Content.Properties(properties);
  if failed(hr) then Result:=ErrorMsg('Failed to get IPortableDeviceProperties from IPortableDevice',hr)
  else begin
    // CoCreate an IPortableDeviceKeyCollection interface to hold the the property keys
    hr:=CoCreateInstance(CLSID_PortableDeviceKeyCollection,nil,CLSCTX_INPROC_SERVER,
                          IPortableDeviceKeyCollection,PropertiesToRead);
    end;
  if succeeded(hr) then begin
    // Populate the IPortableDeviceKeyCollection with WPD_OBJECT_NAME.
    PropertiesToRead.Add(WPD_OBJECT_NAME);
    PropertiesToRead.Add(WPD_OBJECT_FORMAT);
    hr:=properties.GetValues(PChar(objectID),    // The object whose properties we are reading
                      PropertiesToRead,   // The properties we want to read
                      objectProperties);  // Driver supplied property values for the specified object
    if failed(hr) then Result:=ErrorMsg(Format('Failed to get properties for object "%s"',[objectID]),hr)
    else Result:=StringPropertyAsString(objectProperties,WPD_OBJECT_NAME,'');
    end;
  end;

//===================================================================
// from "ContentEnumeration.cpp"

// Recursively called function which enumerates using the specified
// object identifier as the parent.
procedure RecursiveEnumerate (const objectID : string; Content : IPortableDeviceContent; level : cardinal = 0);
var
  hr   : HResult;
  enumObjectIDs : IEnumPortableDeviceObjectIDs;
  numFetched,i  : cardinal;
  objectIDArray : TCharArray;
begin
  // Print the object identifier being used as the parent during enumeration.
  writeln('Object ID: ',objectID,' - ':(10-length(ObjectID)+2*level),GetObjectInfo(objectID,Content));
  // Get an IEnumPortableDeviceObjectIDs interface by calling EnumObjects with the
  // specified parent object identifier.
  hr:=Content.EnumObjects(0,PWideChar(objectID),nil,enumObjectIDs);
  if failed(hr) then WriteErrMsg ('Failed to get IEnumPortableDeviceObjectIDs from IPortableDeviceContent',hr);
  while hr=S_OK do begin
    SetLength(objectIDArray,NUM_OBJECTS_TO_REQUEST);
    hr:=enumObjectIDs.Next(NUM_OBJECTS_TO_REQUEST,objectIDArray[0],numFetched);
    if succeeded(hr) then begin
      // Traverse the results of the Next() operation and recursively enumerate
      // Remember to free all returned object identifiers using CoTaskMemFree()
      if numFetched>0 then for i:=0 to numFetched-1 do if objectIDArray[i]<>nil then begin
        RecursiveEnumerate(objectIDArray[i],Content,level+1);
        CoTaskMemFree(objectIDArray[i]); objectIDArray[i]:=nil;
        end;
      end;
    objectIDArray:=nil;
    end;
  end;

// Enumerate all content on the device
procedure EnumerateAllContent (device : IPortableDevice);
var
  hr   : HResult;
  Content : IPortableDeviceContent;
begin
  // Get an IPortableDeviceContent interface from the IPortableDevice interface to
  // access the content-specific methods.
  hr:=device.Content(Content);
  if failed(hr) then WriteErrMsg ('Failed to get IPortableDeviceContent from IPortableDevice',hr)
  else begin
    writeln;
  // Enumerate content starting from the "DEVICE" object.
    RecursiveEnumerate(WPD_DEVICE_OBJECT_ID,content);
    end;
  end;

function SendHintsCommand (device : IPortableDevice; const contentType : TGuid; var results : IPortableDeviceValues) : boolean;
var
  hr   : HResult;
  params : IPortableDeviceValues;
begin
  Result:=false; results:=nil;
  hr:=CoCreateInstance(CLSID_PortableDeviceValues,nil,CLSCTX_INPROC_SERVER,
                        IPortableDeviceValues,params);
  if succeeded(hr) then begin
    Result:=succeeded(params.SetGuidValue(WPD_PROPERTY_COMMON_COMMAND_CATEGORY,
                            WPD_COMMAND_DEVICE_HINTS_GET_CONTENT_LOCATION.fmtid))
      and succeeded(params.SetUnsignedIntegerValue(WPD_PROPERTY_COMMON_COMMAND_ID,
                                         WPD_COMMAND_DEVICE_HINTS_GET_CONTENT_LOCATION.pid))
      and succeeded(params.SetGuidValue(WPD_PROPERTY_DEVICE_HINTS_CONTENT_TYPE,contentType))
      and succeeded(device.SendCommand(0,params,results));
    end;
  end;

procedure ReadHintsResults (properties : IPortableDeviceProperties; results : IPortableDeviceValues);
var
  nc,i : cardinal;
  folderIDs : IPortableDevicePropVariantCollection;
  folderID : TPropVariant;
  folderProperties : IPortableDeviceValues;
  folderPersistentUniqueID : PWideChar;
begin
  // Get the collection
  if results.GetIPortableDevicePropVariantCollectionValue(WPD_PROPERTY_DEVICE_HINTS_CONTENT_LOCATIONS,folderIDs)=S_OK then begin
    // Get the count of folders
    if succeeded(folderIDs.GetCount(nc)) then begin
      if nc>0 then for i:=0 to nc-1 do begin
        if succeeded(folderIDs.GetAt(i,folderID)) then begin
          if folderID.vt=VT_LPWSTR then begin
            // Get the properties for this item
            if succeeded(properties.GetValues(folderID.pwszVal,nil,folderProperties)) then begin
              // Get the persistent unique object id
              if succeeded(folderProperties.GetStringValue(WPD_OBJECT_PERSISTENT_UNIQUE_ID,folderPersistentUniqueID)) then begin
                writeln(Format('"%s" (%s)',[folderID.pwszVal,folderPersistentUniqueID]));
                CoTaskMemFree(folderPersistentUniqueID);
                end;
              end;
            end
          else WriteErrMsg (Format('Driver returned unexpected PROVARIANT Type: %u',[folderID.vt]));
          end;
        PropVariantClear(folderID);
        end;
      end;
    end;
  end;

procedure ReadHintLocations  (device : IPortableDevice);
const
  formatTypes : array of PGuid = [@WPD_CONTENT_TYPE_IMAGE,@WPD_CONTENT_TYPE_VIDEO];
  formatTypeStrings : array of string = ['WPD_CONTENT_TYPE_IMAGE','WPD_CONTENT_TYPE_VIDEO'];
var
  hr   : HResult;
  i    : integer;
  Content : IPortableDeviceContent;
  properties : IPortableDeviceProperties;
  results        : IPortableDeviceValues;
begin
  // Get an IPortableDeviceContent interface from the IPortableDevice interface to
  // access the content-specific methods.
  hr:=device.Content(Content);
  if failed(hr) then WriteErrMsg ('Failed to get IPortableDeviceContent from IPortableDevice',hr)
  else begin
    hr:=Content.Properties(properties);
    if succeeded(hr) then begin
      // Loop through some typical content types supported by Portable Devices
      for i:=0 to High(formatTypes) do begin
        writeln(Format('Folders for content type "%s": ',[formatTypeStrings[i]]));
        if SendHintsCommand(device,formatTypes[i]^,results) then ReadHintsResults(properties,results);
        end;
      end;
    end;
  end;

//===================================================================
// from "ContentTransfer.cpp"

// Reads a string property from the IPortableDeviceProperties
// interface and returns it
function GetStringValue (Properties  : IPortableDeviceProperties; objectID : string;
              key : TPropertyKey; var value : string) : HResult;
var
  hr   : HResult;
  objectProperties  : IPortableDeviceValues;
  propertiesToRead  : IPortableDeviceKeyCollection;
  stringValue   : PWideChar;
begin
  // 1) CoCreate an IPortableDeviceKeyCollection interface to hold the the property key
  // we wish to read.
  Result:=CoCreateInstance(CLSID_PortableDeviceKeyCollection,nil,CLSCTX_INPROC_SERVER,
              IPortableDeviceKeyCollection,propertiesToRead);
  // 2) Populate the IPortableDeviceKeyCollection with the keys we wish to read.
  // NOTE: We are not handling any special error cases here so we can proceed with
  // adding as many of the target properties as we can.
  if succeeded(Result) then begin
    hr:=propertiesToRead.Add(key);
    if failed(hr) then WriteErrMsg ('Failed to add PROPERTYKEY to IPortableDeviceKeyCollection',hr)
    end;
  // 3) Call GetValues() passing the collection of specified PROPERTYKEYs.
  if succeeded(Result) then begin
    Result:=Properties.GetValues(PChar(objectID),propertiesToRead,objectProperties);
    // The error is handled by the caller, which also displays an error message to the user.
    end;
    // 4) Extract the string value from the returned property collection
  if succeeded(Result) then begin
    Result:=objectProperties.GetStringValue(key,stringValue);
    if succeeded(Result) then value:=stringValue // Assign the newly read string to the result
    else WriteErrMsg ('Failed to find property in IPortableDeviceValues',Result);
    CoTaskMemFree(stringValue); stringValue:=nil;
    end;
  end;

// Copies data from a source stream to a destination stream using the
// specified transferSizeBytes as the temporary buffer size.
// requires IStream definition from PortableDeviceApi
function StreamCopy(destStream,sourceStream : IStream; transferSizeBytes : DWord;
    var bytesWrittenOut: DWord) : HResult;
var
  tbuf : array of byte;
  tbr,tbw,br,bw : cardinal;
begin
  bytesWrittenOut:=0; tbr:=0; tbw:=0;
  // Allocate a temporary buffer (of Optimal transfer size) for the read results to
  // be written to.
  SetLength(tbuf,transferSizeBytes);
  repeat
    // Read object data from the source stream
    Result:=sourceStream.Read(tbuf[0],transferSizeBytes,br);
    if succeeded(Result) then begin
      if br>0 then begin
        // Write object data to the destination stream
        inc(tbr,br);     // Calculating total bytes read from device for debugging purposes only
        Result:=destStream.Write(tbuf[0],br,bw);
        if failed(Result) then WriteErrMsg (Format('Failed to write %u bytes of object data to the destination stream',[br]),Result)
        else begin
          inc(tbw,bw);
         // Output Read/Write operation information only if we have received data and if no error has occured so far.
          writeln(Format('Read %u bytes from the source stream...Wrote %u bytes to the destination stream...',[br,bw]));
          end;
        end;
      end
    else WriteErrMsg (Format('Failed to read %u bytes from the source stream',[transferSizeBytes]),Result);
    until failed(Result) or (br=0);
  // If we are successful, set bytesWrittenOut before exiting.
  if succeeded(Result) then bytesWrittenOut:=tbw;
  tbuf:=nil;
  end;

// Transfers a selected object's data (WPD_RESOURCE_DEFAULT) to a temporary file.
procedure TransferContentFromDevice (device : IPortableDevice);
var
  hr   : HResult;
  sel,fn    : string;
  otsz,tbw  : cardinal;
  Content   : IPortableDeviceContent;
  Resources : IPortableDeviceResources;
  Properties  : IPortableDeviceProperties;
  objectDataStream,
  finalFileStream : IStream;
begin
  // Prompt user to enter an object identifier on the device to transfer.
  write('Enter the identifier of the object you wish to transfer: '); readln(sel);
  if length(sel)=0 then Exit;

  // 1) get an IPortableDeviceContent interface from the IPortableDevice interface to
  // access the content-specific methods.
  hr:=device.Content(content);
  if failed(hr) then WriteErrMsg ('Failed to get IPortableDeviceContent from IPortableDevice',hr)
  else begin
    // 2) Get an IPortableDeviceResources interface from the IPortableDeviceContent interface to
    // access the resource-specific methods.
    hr:=Content.Transfer(Resources);
    if failed(hr) then WriteErrMsg ('Failed to get IPortableDeviceResources from IPortableDeviceContent',hr)
    else begin
      otsz:=0;
      // 3) Get the IStream (with READ access) and the optimal transfer buffer size
      // to begin the transfer.
      hr:=Resources.GetStream(PChar(sel),   // Identifier of the object we want to transfer
              WPD_RESOURCE_DEFAULT,         // We are transferring the default resource (which is the entire object's data)
              STGM_READ,                    // Opening a stream in READ mode, because we are reading data from the device.
              otsz,                         // Driver supplied optimal transfer size
              objectDataStream);
      if failed(hr) then WriteErrMsg ('Failed to get IStream (representing object data on the device) from IPortableDeviceResources',hr)
      else begin
      // 4) Read the WPD_OBJECT_ORIGINAL_FILE_NAME property so we can properly name the
      // transferred object.  Some content objects may not have this property, so a
      // fall-back case has been provided below. (i.e. Creating a file named <objectID>.data )
        hr:=Content.Properties(Properties);
        if succeeded(hr) then begin
          hr:=GetStringValue(Properties,PChar(sel),WPD_OBJECT_ORIGINAL_FILE_NAME,fn);
          if failed(hr) then begin
            WriteErrMsg (Format('Failed to read WPD_OBJECT_ORIGINAL_FILE_NAME on object "%s"',[sel]),hr);
            // Create a temporary file name
            fn:=Format('%s.data',[sel]);
            end;
          end
        else WriteErrMsg ('Failed to get IPortableDeviceProperties from IPortableDeviceContent',hr);
        end;
      // 5) Create a destination for the data to be written to.  In this example we are
      // creating a temporary file which is named the same as the object identifier string.
      if succeeded(hr) then begin
        hr:=SHCreateStreamOnFileEx(PChar(fn),STGM_CREATE or STGM_WRITE,FILE_ATTRIBUTE_NORMAL,false,nil,finalFileStream);
        if failed(hr) then
          WriteErrMsg (Format('Failed to create a temporary file named (%s) to transfer object (%s)',[fn,sel]),hr);
        end;
      // 6) Read on the object's data stream and write to the final file's data stream using the
      // driver supplied optimal transfer buffer size.
      if succeeded(hr) then begin
        tbw:=0;
        // Since we have IStream-compatible interfaces, call our helper function
        // that copies the contents of a source stream into a destination stream.
        hr:=StreamCopy(finalFileStream,              // Destination (The Final File to transfer to)
                       objectDataStream, // Source (The Object's data to transfer from)
                       otsz,             // The driver specified optimal transfer buffer size
                       tbw);             // The total number of bytes transferred from device to the finished file
        if failed(hr) then WriteErrMsg ('Failed to transfer object from device',hr)
        else writeln(Format('Transferred object "%s" to "%s"',[sel,fn]));
        end;
      end;
    end;
  end;

procedure DeleteContentFromDevice (device : IPortableDevice);
var
  hr   : HResult;
  sel     : string;
  pv      : TPropVariant;
  Content : IPortableDeviceContent;
  pnul,
  objectsToDelete  : IPortableDevicePropVariantCollection;
begin
  // Prompt user to enter an object identifier on the device to delete.
  write('Enter the identifier of the object you wish to delete: '); readln(sel);
  if length(sel)=0 then Exit;

  // 1) get an IPortableDeviceContent interface from the IPortableDevice interface to
  // access the content-specific methods.
  hr:=device.Content(content);
  if failed(hr) then WriteErrMsg ('Failed to get IPortableDeviceContent from IPortableDevice',hr)
  else begin
    // 2) CoCreate an IPortableDevicePropVariantCollection interface to hold the the object identifiers
    // to delete.
    //
    // NOTE: This is a collection interface so more than 1 object can be deleted at a time.
    //       This sample only deletes a single object.
    hr:=CoCreateInstance(CLSID_PortableDevicePropVariantCollection,nil,CLSCTX_INPROC_SERVER,
                          IPortableDevicePropVariantCollection,objectsToDelete);
    if succeeded(hr) then begin
      // Initialize a PROPVARIANT structure with the object identifier string
      // that the user selected above. Notice we are allocating memory for the
      // PWSTR value.  This memory will be freed when PropVariantClear() is called below.
      hr:=InitPropVariantFromString(pchar(sel),pv);
      if succeeded(hr) then begin
        // Add the object identifier to the objects-to-delete list
        // (We are only deleting 1 in this example)
        hr:=objectsToDelete.Add(pv);
        if succeeded(hr) then begin
          pnul:=nil;
          // Attempt to delete the object from the device
          hr:=Content.Delete(PORTABLE_DEVICE_DELETE_NO_RECURSION,   // Deleting with no recursion
                             objectsToDelete,                       // Object(s) to delete
                             pnul);                                 // Object(s) that failed to delete (we are only deleting 1, so we can pass nullptr here)
          if succeeded(hr) then begin
            // An S_OK return lets the caller know that the deletion was successful
            if hr=S_OK then writeln(Format('The object "%s" was deleted from the device.',[sel]))
            // An S_FALSE return lets the caller know that the deletion failed.
            // The caller should check the returned IPortableDevicePropVariantCollection
            // for a list of object identifiers that failed to be deleted.
            else writeln(Format('The object "%s" failed to be deleted from the device.',[sel]));
            end
          else WriteErrMsg ('Failed to delete an object from the device',hr);
          end
        else WriteErrMsg ('Failed to delete an object from the device because we could no add the object identifier string to the IPortableDevicePropVariantCollection',hr);
        end
      else begin
        hr:=E_OUTOFMEMORY;
        WriteErrMsg ('Failed to delete an object from the device because we could not allocate memory for the object identifier string',hr);
        end;
      // Free any allocated values in the PROPVARIANT before exiting
      PropVariantClear(pv);
      end
    else WriteErrMsg ('Failed to delete an object from the device because we were returned a nullptr IPortableDevicePropVariantCollection interface pointer',hr);
    end;
  end;

// Moves a selected object (which is already on the device) to another location on the device.
procedure MoveContentAlreadyOnDevice (device : IPortableDevice);
var
  hr   : HResult;
  sel,dest : string;
  pv       : TPropVariant;
  Content  : IPortableDeviceContent;
  pnul,
  objectsToMove : IPortableDevicePropVariantCollection;
begin
  // Check if the device supports the move command needed to perform this operation
  if not SupportsCommand(device,WPD_COMMAND_OBJECT_MANAGEMENT_MOVE_OBJECTS) then
    writeln('This device does not support the move operation (i.e. The WPD_COMMAND_OBJECT_MANAGEMENT_MOVE_OBJECTS command)')
  else begin
    // Prompt user to enter an object identifier on the device to move.
    write('Enter the identifier of the object you wish to move: '); readln(sel);
    if length(sel)=0 then Exit;
    write(Format('Enter the identifier of the object you wish to move "%s" to: ',[sel])); readln(dest);
    if length(dest)=0 then Exit;

    // 1) get an IPortableDeviceContent interface from the IPortableDevice interface to
    // access the content-specific methods.
    hr:=device.Content(content);
    if failed(hr) then WriteErrMsg ('Failed to get IPortableDeviceContent from IPortableDevice',hr)
    else begin
      // 2) CoCreate an IPortableDevicePropVariantCollection interface to hold the the object identifiers
      // to move.
      // NOTE: This is a collection interface so more than 1 object can be deleted at a time.
      //       This sample only deletes a single object.
      hr:=CoCreateInstance(CLSID_PortableDevicePropVariantCollection,nil,CLSCTX_INPROC_SERVER,
                            IPortableDevicePropVariantCollection,objectsToMove);
      if succeeded(hr) then begin
        // Initialize a PROPVARIANT structure with the object identifier string
        // that the user selected above. Notice we are allocating memory for the
        // PWSTR value.  This memory will be freed when PropVariantClear() is
        // called below.
        hr:=InitPropVariantFromString(pchar(sel),pv);
        if succeeded(hr) then begin
          // Add the object identifier to the objects-to-move list
          // (We are only moving 1 in this example)
          hr:=objectsToMove.Add(pv);
          if succeeded(hr) then begin
          // Attempt to move the object on the device
            pnul:=nil;
            hr:=content.Move(objectsToMove,          // Object(s) to move
                             PChar(dest),  // Folder to move to
                             pnul);        // Object(s) that failed to delete (we are only moving 1, so we can pass nullptr here)
            if succeeded(hr) then begin
              // An S_OK return lets the caller know that the deletion was successful
              if hr=S_OK then writeln(Format('The object "%s" was moved on the device.',[sel]))
              // An S_FALSE return lets the caller know that the move failed.
              // The caller should check the returned IPortableDevicePropVariantCollection
              // for a list of object identifiers that failed to be moved.
              else writeln(Format('The object "%s" failed to be moved on the device.',[sel]));
              end
            else WriteErrMsg ('Failed to move an object on the device',hr);
            end
          else WriteErrMsg ('Failed to move an object on the device because we could no add the object identifier string to the IPortableDevicePropVariantCollection',hr);
          end
        else begin
          hr:=E_OUTOFMEMORY;
          WriteErrMsg ('Failed to move an object on the device because we could not allocate memory for the object identifier string',hr);
          end;
        // Free any allocated values in the PROPVARIANT before exiting
        PropVariantClear(pv);
        end
      else WriteErrMsg ('Failed to CoCreateInstance CLSID_PortableDevicePropVariantCollection',hr);
      end;
    end;
  end;

// Fills out the required properties for ALL content types...
function GetRequiredPropertiesForAllContentTypes (objectProperties : IPortableDeviceValues;
                      const parentObjectID,filePath : string; fileStream : IStream) : HResult;
var
  statstg : tagSTATSTG;
  fn : string;
begin
  // Set the WPD_OBJECT_PARENT_ID
  Result:=objectProperties.SetStringValue(WPD_OBJECT_PARENT_ID,PChar(parentObjectID));
  if failed(Result) then WriteErrMsg ('Failed to set WPD_OBJECT_PARENT_ID',Result)
  else begin
    FillChar(statstg,sizeof(tagSTATSTG),0);
    Result:=fileStream.Stat(statstg,STATFLAG_NONAME);
    if succeeded(Result) then begin
      Result:=objectProperties.SetUnsignedLargeIntegerValue(WPD_OBJECT_SIZE,statstg.cbSize.QuadPart);
      if failed(Result) then WriteErrMsg ('Failed to set WPD_OBJECT_SIZE',Result);
      end
    else WriteErrMsg ('Failed to get file''s total size',Result);
    end;
  if succeeded(Result) then begin
    // Set the WPD_OBJECT_ORIGINAL_FILE_NAME by splitting the file path
    // into a separate filename.
    fn:=ExtractFilename(filePath);
    if length(fn)>0 then begin
      Result:=objectProperties.SetStringValue(WPD_OBJECT_ORIGINAL_FILE_NAME,PChar(fn));
      if failed(Result) then WriteErrMsg ('Failed to set WPD_OBJECT_ORIGINAL_FILE_NAME',Result);
      end
    else begin
      Result:=E_INVALIDARG;
      WriteErrMsg ('Failed to extract the filename from the file path',Result)
      end;
    end;
  if succeeded(Result) then begin
    fn:=ChangeFileExt(fn,'');
    Result:=objectProperties.SetStringValue(WPD_OBJECT_NAME,PChar(fn));
    if failed(Result) then WriteErrMsg ('Failed to set WPD_OBJECT_NAME',Result)
    end;
  end;

// Fills out the required properties for WPD_CONTENT_TYPE_IMAGE
function GetRequiredPropertiesForImageContentTypes(objectProperties : IPortableDeviceValues) : HResult;
begin
  // Set the WPD_OBJECT_CONTENT_TYPE to WPD_CONTENT_TYPE_IMAGE because we are
  // creating/transferring image content to the device.
  Result:=ObjectProperties.SetGuidValue(WPD_OBJECT_CONTENT_TYPE,WPD_CONTENT_TYPE_IMAGE);
  if failed(Result) then WriteErrMsg ('Failed to set WPD_OBJECT_CONTENT_TYPE to WPD_CONTENT_TYPE_IMAGE',Result)
  else begin
    // Set the WPD_OBJECT_FORMAT to WPD_OBJECT_FORMAT_EXIF because we are
    // creating/transferring image content to the device.
    Result:=ObjectProperties.SetGuidValue(WPD_OBJECT_FORMAT,WPD_OBJECT_FORMAT_EXIF);
    if failed(Result) then WriteErrMsg ('Failed to set WPD_OBJECT_FORMAT to WPD_OBJECT_FORMAT_EXIF',Result);
    end;
  end;

// Fills out the required properties for WPD_CONTENT_TYPE_AUDIO
function GetRequiredPropertiesForMusicContentTypes(objectProperties : IPortableDeviceValues) : HResult;
begin
  // Set the WPD_OBJECT_CONTENT_TYPE to WPD_CONTENT_TYPE_AUDIO because we are
  // creating/transferring music content to the device.
  Result:=ObjectProperties.SetGuidValue(WPD_OBJECT_CONTENT_TYPE,WPD_CONTENT_TYPE_AUDIO);
  if failed(Result) then WriteErrMsg ('Failed to set WPD_OBJECT_CONTENT_TYPE to WPD_CONTENT_TYPE_AUDIO',Result)
  else begin
    // Set the WPD_OBJECT_FORMAT to WPD_OBJECT_FORMAT_MP3 because we are
    // creating/transferring music content to the device.
    Result:=ObjectProperties.SetGuidValue(WPD_OBJECT_FORMAT,WPD_OBJECT_FORMAT_MP3);
    if failed(Result) then WriteErrMsg ('Failed to set WPD_OBJECT_FORMAT to WPD_OBJECT_FORMAT_MP3',Result);
    end;
  end;

// Fills out the required properties for WPD_CONTENT_TYPE_CONTACT
function  GetRequiredPropertiesForContactContentTypes(objectProperties : IPortableDeviceValues) : HResult;
begin
  // Set the WPD_OBJECT_CONTENT_TYPE to WPD_CONTENT_TYPE_CONTACT because we are
  // creating/transferring contact content to the device.
  Result:=ObjectProperties.SetGuidValue(WPD_OBJECT_CONTENT_TYPE,WPD_CONTENT_TYPE_CONTACT);
  if failed(Result) then WriteErrMsg ('Failed to set WPD_OBJECT_CONTENT_TYPE to WPD_CONTENT_TYPE_CONTACT',Result)
  else begin
    // Set the WPD_OBJECT_FORMAT to WPD_OBJECT_FORMAT_VCARD2 because we are
    // creating/transferring contact content to the device. (This is Version 2 of
    // the VCARD file.  If you have Version 3, use WPD_OBJECT_FORMAT_VCARD3 as the
    // format)
    Result:=ObjectProperties.SetGuidValue(WPD_OBJECT_FORMAT,WPD_OBJECT_FORMAT_VCARD2);
    if failed(Result) then WriteErrMsg ('Failed to set WPD_OBJECT_FORMAT to WPD_OBJECT_FORMAT_VCARD2',Result);
    end;
  end;

// Fills out the required properties for specific WPD content types.
function GetRequiredPropertiesForContentType(const contentType : TGuid; parentObjectID,filePath : string;
                      fileStream : IStream; var objectProperties : IPortableDeviceValues) : HResult;
var
  objectPropertiesTemp  : IPortableDeviceValues;
begin
  // CoCreate an IPortableDeviceValues interface to hold the the object information
  Result:=CoCreateInstance(CLSID_PortableDeviceValues,nil,CLSCTX_INPROC_SERVER,
                      IPortableDeviceValues,objectPropertiesTemp);
  if succeeded(Result) then begin
    if objectPropertiesTemp<>nil then begin
      // Fill out required properties for ALL content types
      Result:=GetRequiredPropertiesForAllContentTypes(objectPropertiesTemp,parentObjectID,filePath,fileStream);
        if succeeded(Result) then begin
        // Fill out required properties for specific content types.
        // NOTE: If the content type is unknown to this function then
        // only the required properties will be written.  This is enough
        // for transferring most generic content types.
        if contentType=WPD_CONTENT_TYPE_IMAGE then Result:=GetRequiredPropertiesForImageContentTypes(objectPropertiesTemp)
        else if contentType=WPD_CONTENT_TYPE_AUDIO then Result:=GetRequiredPropertiesForMusicContentTypes(objectPropertiesTemp)
        else if contentType=WPD_CONTENT_TYPE_CONTACT then Result:=GetRequiredPropertiesForContactContentTypes(objectPropertiesTemp);
        end
      else WriteErrMsg ('Failed to get required properties common to ALL content types',Result);
      if succeeded(Result) then objectProperties:=objectPropertiesTemp;
      end
    else begin
      Result:=E_UNEXPECTED;
      WriteErrMsg ('Failed to create property information because we were returned a nullptr IPortableDeviceValues interface pointer',Result);
      end;
    end
  end;

// Convert Delphi filter string ("|" delimiter) to Windows filter string (#0 delimiter)
function AllocFilterStr(const S: string): string;
var
  P: PChar;
begin
  Result := '';
  if S <> '' then begin
    Result := S + #0;  // double null terminators
    P := AnsiStrScan(PChar(Result), '|');
    while P <> nil do begin
      P^ := #0;
      Inc(P);
      P := AnsiStrScan(P, '|');
      end;
    end;
  end;

// Transfers a user selected file to the device
procedure TransferContentToDevice (device : IPortableDevice; const contentType : TGuid;
                  const fileTypeFilter,defaultFileExtension : string);
var
  hr   : HResult;
  dest,tf,fp : string;
  ofn        : TOpenFilename;
  otsz,tbw   : cardinal;
  pnul,nco   : PWChar;
  Content    : IPortableDeviceContent;
  fileStream,tempStream : IStream;
  finalObjectDataStream : IPortableDeviceDataStream;
  finalObjectProperties : IPortableDeviceValues;
begin
  // Prompt user to enter an object identifier for the parent object on the device to transfer.
  write('Enter the identifier of the parent object which the file will be transferred under: '); readln(dest);
  if length(dest)=0 then Exit;

  // 1) get an IPortableDeviceContent interface from the IPortableDevice interface to
  // access the content-specific methods.
  hr:=device.Content(content);
  if failed(hr) then WriteErrMsg ('Failed to get IPortableDeviceContent from IPortableDevice',hr)
  else begin
    // 2) Present the user with a File Open dialog.  Our sample is
    // restricting the types to user-specified forms.
    FillChar(ofn,SizeOf(TOpenFilename),0);
    with ofn do begin
      lStructSize:=sizeof(TOpenFilename);
      hwndOwner:=0;
      nMaxFile:=MAX_PATH;
      SetLength(fp,nMaxFile+2);
      lpstrFile:=PChar(fp);
      FillChar(lpstrFile^,(nMaxFile+2)*SizeOf(Char),0);
      tf:=AllocFilterStr(fileTypeFilter);
      lpstrFilter:=PChar(tf);
      nFilterIndex:=1;
      lpstrDefExt:=PChar(defaultFileExtension);
      end;
    if GetOpenFileName(ofn) then begin
      // 3) Open the image file and add required properties about the file being transferred
      // Open the selected file as an IStream.  This will simplify reading the
      // data and writing to the device.
      hr:=SHCreateStreamOnFileEx(PChar(fp),STGM_READ,FILE_ATTRIBUTE_NORMAL,false,nil,fileStream);
      if succeeded(hr) then begin
        // Get the required properties needed to properly describe the data being
        // transferred to the device.
        hr:=GetRequiredPropertiesForContentType(contentType,              // Content type of the data
                                                dest,                     // Parent to transfer the data under
                                                fp,                       // Full file path to the data file
                                                fileStream,                      // Open IStream that contains the data
                                                finalObjectProperties);                     // Returned properties describing the data
        if failed(hr) then WriteErrMsg ('Failed to get required properties needed to transfer a file to the device',hr)
        else begin
          pnul:=nil;
          // 4) Transfer for the content to the device
          hr:=Content.CreateObjectWithPropertiesAndData(finalObjectProperties,      // Properties describing the object data
                                                tempStream,       // Returned object data stream (to transfer the data to)
                                                otsz,     // Returned optimal buffer size to use during transfer
                                                pnul);
          // Once we have a the IStream returned from CreateObjectWithPropertiesAndData,
          // QI for IPortableDeviceDataStream so we can use the additional methods
          // to get more information about the object (i.e. The newly created object
          // identifier on the device)
          if succeeded(hr) then begin
            hr:=tempStream.QueryInterface(IID_IPortableDeviceDataStream,finalObjectDataStream);
            if failed(hr) then WriteErrMsg ('Failed to QueryInterface for IPortableDeviceDataStream',hr);
            end;
          // Since we have IStream-compatible interfaces, call our helper function
          // that copies the contents of a source stream into a destination stream.
          if succeeded(hr) then begin
            hr:=StreamCopy(finalObjectDataStream,        // Destination (The Final File to transfer to)
                           fileStream,        // Source (The Object's data to transfer from)
                           otsz,       // The driver specified optimal transfer buffer size
                           tbw);       // The total number of bytes transferred from device to the finished file
            if failed(hr) then WriteErrMsg ('Failed to transfer object to device',hr);
            end
          else WriteErrMsg ('Failed to get IStream (representing destination object data on the device) from IPortableDeviceContent',hr);
          end;
        // After transferring content to the device, the client is responsible for letting the
        // driver know that the transfer is complete by calling the Commit() method
        // on the IPortableDeviceDataStream interface.
        if succeeded(hr) then begin
          hr:=finalObjectDataStream.Commit(STGC_DEFAULT);
          if failed(hr) then WriteErrMsg ('Failed to commit object to device',hr);
          end;
        // Some clients may want to know the object identifier of the newly created
        // object.  This is done by calling GetObjectID() method on the
        // IPortableDeviceDataStream interface.
        if succeeded(hr) then begin
          hr:=finalObjectDataStream.GetObjectID(nco);
          if succeeded(hr) then writeln(Format('The file "%s" was transferred to the device.'+sLineBreak
                                               +'The newly created object''s ID is "%s"',[Trim(fp),nco]))
          else WriteErrMsg ('Failed to get the newly transferred object''s identifier from the device',hr);
          CoTaskMemFree(nco); nco:=nil;
          end;
        end
      else WriteErrMsg (Format('Failed to open file named (%s) to transfer to device',[fp]),hr);
      end
    else writeln('The transfer operation was cancelled.');
    end;
  end;

// Fills out the required properties for a properties-only
// contact named "Max Mustermann".  This is a hard-coded
// contact.
function GetRequiredPropertiesForPropertiesOnlyContact   (const parentObjectID : string;
                      var objectProperties : IPortableDeviceValues) : HResult;
var
  objectPropertiesTemp  : IPortableDeviceValues;
const
  ContactName = 'Max Mustermann';
  Phone = '0123-456789';
begin
  // CoCreate an IPortableDeviceValues interface to hold the the object information
  Result:=CoCreateInstance(CLSID_PortableDeviceValues,nil,CLSCTX_INPROC_SERVER,
                      IPortableDeviceValues,objectPropertiesTemp);
  if succeeded(Result) then begin
    if objectPropertiesTemp<>nil then begin
      // Set the WPD_OBJECT_PARENT_ID
      Result:=objectPropertiesTemp.SetStringValue(WPD_OBJECT_PARENT_ID,PChar(parentObjectID));
      if failed(Result) then WriteErrMsg ('Failed to set WPD_OBJECT_PARENT_ID',Result)
      else begin
        // Set the WPD_OBJECT_NAME.
        Result:=objectPropertiesTemp.SetStringValue(WPD_OBJECT_NAME,PChar(ContactName));
        if failed(Result) then WriteErrMsg ('Failed to set WPD_OBJECT_NAME',Result);
        end;
      // Set the WPD_OBJECT_CONTENT_TYPE to WPD_CONTENT_TYPE_CONTACT because we are
      // creating contact content on the device.
      if succeeded(Result) then begin
        Result:=objectPropertiesTemp.SetGuidValue(WPD_OBJECT_CONTENT_TYPE,WPD_CONTENT_TYPE_CONTACT);
        if failed(Result) then WriteErrMsg ('Failed to set WPD_OBJECT_CONTENT_TYPE to WPD_CONTENT_TYPE_CONTACT',Result);
        end;
      // Set the WPD_CONTACT_DISPLAY_NAME to "Max Mustermann"
      if succeeded(Result) then begin
        Result:=objectPropertiesTemp.SetStringValue(WPD_CONTACT_DISPLAY_NAME,PChar(ContactName));
        if failed(Result) then WriteErrMsg ('Failed to set WPD_CONTACT_DISPLAY_NAME',Result);
        end;
      // Set the WPD_CONTACT_PRIMARY_PHONE to "0123-456789"
      if succeeded(Result) then begin
        Result:=objectPropertiesTemp.SetStringValue(WPD_CONTACT_PRIMARY_PHONE,PChar(Phone));
        if failed(Result) then WriteErrMsg ('Failed to set WPD_CONTACT_PRIMARY_PHONE',Result);
        end;
      if succeeded(Result) then objectProperties:=objectPropertiesTemp;
      end
    else begin
      Result:=E_UNEXPECTED;
      WriteErrMsg ('Failed to create property information because we were returned a nullptr IPortableDeviceValues interface pointer',Result);
      end;
    end;
  end;

// Creates a properties-only object on the device which is
// WPD_CONTENT_TYPE_CONTACT specific.
// NOTE: This function creates a hard-coded contact for
// "Max Mustermann" always.
procedure TransferContactToDevice (device : IPortableDevice);
var
  hr   : HResult;
  sel      : string;
  Content  : IPortableDeviceContent;
  finalObjectProperties : IPortableDeviceValues;
  newlyCreatedObject : PWideChar;
begin
  // Prompt user to enter an object identifier for the parent object on the device to transfer.
  write('Enter the identifier of the parent object which the contact will be transferred under: '); readln(sel);
  if length(sel)=0 then Exit;

  // 1) get an IPortableDeviceContent interface from the IPortableDevice interface to
  // access the content-specific methods.
  hr:=device.Content(content);
  if failed(hr) then WriteErrMsg ('Failed to get IPortableDeviceContent from IPortableDevice',hr)
  else begin
    // 2) Get the properties that describe the object being created on the device
    hr:=GetRequiredPropertiesForPropertiesOnlyContact(sel,                    // Parent to transfer the data under
                                                      finalObjectProperties); // Returned properties describing the data
    if failed(hr) then WriteErrMsg ('Failed to get required properties needed to transfer an image file to the device',hr)
    else begin
      // 3) Transfer the content to the device by creating a properties-only object
      hr:=Content.CreateObjectWithPropertiesOnly(finalObjectProperties,newlyCreatedObject);      // Properties describing the object data
      if succeeded(hr) then writeln(Format('The contact was transferred to the device.'+sLineBreak
                                          +'The newly created object''s ID is "%s"',[newlyCreatedObject]))
      else WriteErrMsg ('Failed to transfer contact object to the device',hr);
      CoTaskMemFree(newlyCreatedObject); newlyCreatedObject:=nil;
      end;
    end;
  end;

function GetRequiredPropertiesForFolder (const parentObjectID,folderName : string;
                      var objectProperties : IPortableDeviceValues) : HResult;
var
  objectPropertiesTemp  : IPortableDeviceValues;
begin
  // CoCreate an IPortableDeviceValues interface to hold the the object information
  Result:=CoCreateInstance(CLSID_PortableDeviceValues,nil,CLSCTX_INPROC_SERVER,
                      IPortableDeviceValues,objectPropertiesTemp);
  if succeeded(Result) then begin
    if objectPropertiesTemp<>nil then begin
      // Set the WPD_OBJECT_PARENT_ID
      Result:=objectPropertiesTemp.SetStringValue(WPD_OBJECT_PARENT_ID,PChar(parentObjectID));
      if failed(Result) then WriteErrMsg ('Failed to set WPD_OBJECT_PARENT_ID',Result)
      else begin
        // Set the WPD_OBJECT_NAME.
        Result:=objectPropertiesTemp.SetStringValue(WPD_OBJECT_NAME,PChar(folderName));
        if failed(Result) then WriteErrMsg ('Failed to set WPD_OBJECT_NAME',Result);
        end;
      // Set the WPD_OBJECT_CONTENT_TYPE to WPD_CONTENT_TYPE_FOLDER because we are
      // creating contact content on the device.
      if succeeded(Result) then begin
        Result:=objectPropertiesTemp.SetGuidValue(WPD_OBJECT_CONTENT_TYPE,WPD_CONTENT_TYPE_FOLDER);
        if failed(Result) then WriteErrMsg ('Failed to set WPD_OBJECT_CONTENT_TYPE to WPD_CONTENT_TYPE_FOLDER',Result);
        end;
      if succeeded(Result) then objectProperties:=objectPropertiesTemp;
      end
    else begin
      Result:=E_UNEXPECTED;
      WriteErrMsg ('Failed to create property information because we were returned a nullptr IPortableDeviceValues interface pointer',Result);
      end;
    end;
  end;

// Creates a properties-only object on the device which is
// WPD_CONTENT_TYPE_FOLDER specific.
procedure CreateFolderOnDevice (device : IPortableDevice);
var
  hr   : HResult;
  sel,dir  : string;
  Content  : IPortableDeviceContent;
  finalObjectProperties : IPortableDeviceValues;
  newlyCreatedObject      : PWideChar;
begin
  // Prompt user to enter an object identifier for the parent object on the device to transfer.
  write('Enter the identifier of the parent object which the folder will be created under: '); readln(sel);
  if length(sel)=0 then Exit;

  // Prompt user to enter an object identifier for the parent object on the device to transfer.
  write('Enter the name of the the folder to create: '); readln(dir);
  if length(dir)=0 then Exit;

  // 1) Get an IPortableDeviceContent interface from the IPortableDevice interface to
  // access the content-specific methods.
  hr:=device.Content(content);
  if failed(hr) then WriteErrMsg ('Failed to get IPortableDeviceContent from IPortableDevice',hr)
  else begin
    // 2) Get the properties that describe the object being created on the device
    hr:=GetRequiredPropertiesForFolder(sel,      // Parent to create the folder under
                                       dir,      // Folder Name
                                       finalObjectProperties);     // Returned properties describing the folder
    if failed(hr) then WriteErrMsg ('Failed to get required properties needed to transfer an image file to the device',hr)
    else begin
      // 3) Transfer the content to the device by creating a properties-only object
      hr:=Content.CreateObjectWithPropertiesOnly(finalObjectProperties,newlyCreatedObject);      // Properties describing the object data
      if succeeded(hr) then writeln(Format('The folder "%s" was created on the device.'+sLineBreak
                                          +'The newly created object''s ID is "%s"',[dir,newlyCreatedObject]))
      else WriteErrMsg ('Failed to create a new folder on the device',hr);
      CoTaskMemFree(newlyCreatedObject); newlyCreatedObject:=nil;
      end;
    end;
  end;

// Transfers a user selected file to the device as a new WPD_RESOURCE_CONTACT_PHOTO resource
procedure CreateContactPhotoResourceOnDevice (device : IPortableDevice);
var
  hr   : HResult;
  sel,tf,fp : string;
  otsz,tbw  : cardinal;
  pnul      : PWChar;
  statstg   : tagSTATSTG;
  ofn       : TOpenFilename;
  Content   : IPortableDeviceContent;
  resourceAttributes : IPortableDeviceValues;
  resources          : IPortableDeviceResources;
  resourceStream,fileStream : IStream;
begin
  // Prompt user to enter an object identifier for the object to which we will add a Resource.
  write('Enter the identifier of the object to which we will add a photograph: '); readln(sel);
  if length(sel)=0 then Exit;

  // 1) Get an IPortableDeviceContent interface from the IPortableDevice interface to
  // access the content-specific methods.
  hr:=device.Content(content);
  if failed(hr) then WriteErrMsg ('Failed to get IPortableDeviceContent from IPortableDevice',hr)
  else begin
    // 2) Get an IPortableDeviceResources interface from the IPortableDeviceContent to
    // access the resource-specific  methods.
    hr:=Content.Transfer(resources);
    if failed(hr) then WriteErrMsg ('Failed to get IPortableDeviceResources from IPortableDeviceContent',hr)
    else begin
      // 3) Present the user with a File Open dialog.  Our sample is
      // restricting the types to user-specified forms.
      with ofn do begin
        lStructSize:=sizeof(TOpenFilename);
        hwndOwner:=0;
        nMaxFile:=MAX_PATH;
        SetLength(fp,nMaxFile+2);
        lpstrFile:=PChar(fp);
        FillChar(lpstrFile^,(nMaxFile+2)*SizeOf(Char),0);
        tf:=AllocFilterStr(ImgFilter);
        lpstrFilter:=PChar(tf);
        nFilterIndex:=1;
        lpstrDefExt:=PChar(JpgExt);
        end;
      if GetOpenFileName(ofn) then begin
       // 4) Open the file and add required properties about the resource being transferred
       // Open the selected file as an IStream.  This will simplify reading the
       // data and writing to the device.
        hr:=SHCreateStreamOnFileEx(PChar(fp),STGM_READ,FILE_ATTRIBUTE_NORMAL,false,nil,fileStream);
        if succeeded(hr) then begin
          // CoCreate the IPortableDeviceValues to hold the resource attributes
          hr:=CoCreateInstance(CLSID_PortableDeviceValues,nil,CLSCTX_INPROC_SERVER,
                               IPortableDeviceValues,resourceAttributes);
          if succeeded(hr) then begin
            // Fill in the necessary information regarding this resource
            // Set the WPD_OBJECT_ID.  This informs the driver which object this request is intended for.
            hr:=resourceAttributes.SetStringValue(WPD_OBJECT_ID,PChar(sel));
            if failed(hr) then WriteErrMsg ('Failed to set WPD_OBJECT_ID when creating a resource',hr)
            // Set the WPD_RESOURCE_ATTRIBUTE_RESOURCE_KEY to WPD_RESOURCE_CONTACT_PHOTO
            else begin
              hr:=resourceAttributes.SetKeyValue(WPD_RESOURCE_ATTRIBUTE_RESOURCE_KEY,WPD_RESOURCE_CONTACT_PHOTO);
              if failed(hr) then WriteErrMsg ('Failed to set WPD_RESOURCE_ATTRIBUTE_RESOURCE_KEY, WPD_RESOURCE_CONTACT_PHOTO',hr)
              end;
            // Set the WPD_RESOURCE_ATTRIBUTE_TOTAL_SIZE by requesting the total size of the
            // data stream.
            if succeeded(hr) then begin
              hr:=fileStream.Stat(statstg,STATFLAG_NONAME);
              if succeeded(hr) then begin
                hr:=resourceAttributes.SetUnsignedLargeIntegerValue(WPD_RESOURCE_ATTRIBUTE_TOTAL_SIZE,statstg.cbSize.QuadPart);
                if failed(hr) then WriteErrMsg ('Failed to set WPD_RESOURCE_ATTRIBUTE_TOTAL_SIZE',hr)
                end
              else WriteErrMsg ('Failed to get file''s total size',hr);
              end;
            // Set the WPD_RESOURCE_ATTRIBUTE_FORMAT to WPD_OBJECT_FORMAT_EXIF because we are
            // creating a contact photo resource with JPG image data.
            if succeeded(hr) then begin
              hr:=resourceAttributes.SetGuidValue(WPD_RESOURCE_ATTRIBUTE_FORMAT,WPD_OBJECT_FORMAT_EXIF);
              if failed(hr) then WriteErrMsg ('Failed to set WPD_RESOURCE_ATTRIBUTE_FORMAT to WPD_OBJECT_FORMAT_EXIF',hr);
              end
            end;
          end;
        if failed(hr) then WriteErrMsg (Format('Failed to open file named "%s" to transfer to device',[Trim(fp)]),hr)
       // 5) Transfer for the content to the device
        else begin
          pnul:=nil;
          hr:=resources.CreateResource(resourceAttributes,      // Properties describing this resource
                                 resourceStream,       // Returned resource data stream (to transfer the data to)
                                 otsz,     // Returned optimal buffer size to use during transfer
                                 pnul);
          // Since we have IStream-compatible interfaces, call our helper function
          // that copies the contents of a source stream into a destination stream.
          if succeeded(hr) then begin
            hr:=StreamCopy(resourceStream,         // Destination (The Final File to transfer to)
                           fileStream,        // Source (The Object's data to transfer from)
                           otsz,       // The driver specified optimal transfer buffer size
                           tbw);       // The total number of bytes transferred from device to the finished file
            if failed(hr) then WriteErrMsg ('Failed to transfer object from device',hr);
            end
          else WriteErrMsg ('Failed to get IStream (representing destination object data on the device) from IPortableDeviceContent',hr);
          end;
        // After transferring content to the device, the client is responsible for letting the
        // driver know that the transfer is complete by calling the Commit() method
        // on the IPortableDeviceDataStream interface.
        if succeeded(hr) then begin
          hr:=resourceStream.Commit(STGC_DEFAULT);
          if failed(hr) then WriteErrMsg ('Failed to commit object to device',hr)
          else writeln(Format('The photograph "%s" was added to the device',[Trim(fp)]));
          end;
        end
      else writeln('The transfer operation was cancelled.');
      end;
    end;
  end;

//===================================================================
// from "ContentProperties.cpp"

// Reads properties for the user specified object.
procedure ReadContentProperties (device : IPortableDevice);
var
  hr,thr   : HResult;
  sel      : string;
  Content  : IPortableDeviceContent;
  objectProperties : IPortableDeviceValues;
  properties       : IPortableDeviceProperties;
  propertiesToRead : IPortableDeviceKeyCollection;
begin
  // Prompt user to enter an object identifier on the device to read properties from.
  write('Enter the identifier of the object you wish to read properties from: '); readln(sel);
  if length(sel)=0 then Exit;

  // 1) Get an IPortableDeviceContent interface from the IPortableDevice interface to
  // access the content-specific methods.
  hr:=device.Content(content);
  if failed(hr) then WriteErrMsg ('Failed to get IPortableDeviceContent from IPortableDevice',hr)
  else begin
    // 2) Get an IPortableDeviceProperties interface from the IPortableDeviceContent interface
    // to access the property-specific methods.
    hr:=Content.Properties(properties);
    if failed(hr) then WriteErrMsg ('Failed to get IPortableDeviceProperties from IPortableDevice',hr)
    else begin
      // 3) CoCreate an IPortableDeviceKeyCollection interface to hold the the property keys
      hr:=CoCreateInstance(CLSID_PortableDeviceKeyCollection,nil,CLSCTX_INPROC_SERVER,
                           IPortableDeviceKeyCollection,propertiesToRead);
      end;
    if succeeded(hr) then begin
      // 4) Populate the IPortableDeviceKeyCollection with the keys we wish to read.
      // NOTE: We are not handling any special error cases here so we can proceed with
      // adding as many of the target properties as we can.
      thr:=propertiesToRead.Add(WPD_OBJECT_PARENT_ID);
      if failed(thr) then WriteErrMsg ('Failed to add WPD_OBJECT_PARENT_ID to IPortableDeviceKeyCollection',thr);
      thr:=propertiesToRead.Add(WPD_OBJECT_ID);
      if failed(thr) then WriteErrMsg ('Failed to add WPD_OBJECT_ID to IPortableDeviceKeyCollection',thr);
      thr:=propertiesToRead.Add(WPD_OBJECT_NAME);
      if failed(thr) then WriteErrMsg ('Failed to add WPD_OBJECT_NAME to IPortableDeviceKeyCollection',thr);
      thr:=propertiesToRead.Add(WPD_OBJECT_PERSISTENT_UNIQUE_ID);
      if failed(thr) then WriteErrMsg ('Failed to add WPD_OBJECT_PERSISTENT_UNIQUE_ID to IPortableDeviceKeyCollection',thr);
      thr:=propertiesToRead.Add(WPD_OBJECT_FORMAT);
      if failed(thr) then WriteErrMsg ('Failed to add WPD_OBJECT_FORMAT to IPortableDeviceKeyCollection',thr);
      thr:=propertiesToRead.Add(WPD_OBJECT_CONTENT_TYPE);
      if failed(thr) then WriteErrMsg ('Failed to add WPD_OBJECT_CONTENT_TYPE to IPortableDeviceKeyCollection',thr);
      end;
    // 5) Call GetValues() passing the collection of specified PROPERTYKEYs.
    if succeeded(hr) then begin
      hr:=properties.GetValues(PChar(sel),         // The object whose properties we are reading
                        propertiesToRead,                // The properties we want to read
                        objectProperties);               // Driver supplied property values for the specified object
      if failed(hr) then WriteErrMsg (Format('Failed to get all properties for object "%s"',[sel]),hr)
      end;
    // 6) Display the returned property values to the user
    if succeeded(hr) then begin
      writeln(StringPropertyAsString(objectProperties,WPD_OBJECT_PARENT_ID,'WPD_OBJECT_PARENT_ID'));
      writeln(StringPropertyAsString(objectProperties,WPD_OBJECT_ID,'WPD_OBJECT_ID'));
      writeln(StringPropertyAsString(objectProperties,WPD_OBJECT_NAME,'WPD_OBJECT_NAME'));
      writeln(StringPropertyAsString(objectProperties,WPD_OBJECT_PERSISTENT_UNIQUE_ID,'WPD_OBJECT_PERSISTENT_UNIQUE_ID'));
      writeln(GuidPropertyAsString (objectProperties,WPD_OBJECT_CONTENT_TYPE,'WPD_OBJECT_CONTENT_TYPE'));
      writeln(GuidPropertyAsString (objectProperties,WPD_OBJECT_FORMAT,'WPD_OBJECT_FORMAT'));
      end;
    end;
  end;

// Writes properties on the user specified object.
procedure WriteContentProperties (device : IPortableDevice);
var
  hr   : HResult;
  sel,nn   : string;
  cw       : bool;
  Content      : IPortableDeviceContent;
  objectPropertiesToWrite,
  propertyWriteResults,
  attributes          : IPortableDeviceValues;
  properties          : IPortableDeviceProperties;
begin
  // Prompt user to enter an object identifier on the device to write properties on.
  write('Enter the identifier of the object you wish to write properties on: '); readln(sel);
  if length(sel)=0 then Exit;

  // 1) Get an IPortableDeviceContent interface from the IPortableDevice interface to
  // access the content-specific methods.
  hr:=device.Content(content);
  if failed(hr) then WriteErrMsg ('Failed to get IPortableDeviceContent from IPortableDevice',hr)
  else begin
    cw:=false;
    // 2) Get an IPortableDeviceProperties interface from the IPortableDeviceContent interface
    // to access the property-specific methods.
    hr:=Content.Properties(properties);
    if failed(hr) then WriteErrMsg ('Failed to get IPortableDeviceProperties from IPortableDevice',hr)
    else begin
      // 3) Check the property attributes to see if we can write/change the WPD_OBJECT_NAME property.
      hr:=properties.GetPropertyAttributes(PChar(sel),WPD_OBJECT_NAME,attributes);
      if succeeded(hr) then begin
        hr:=attributes.GetBoolValue(WPD_PROPERTY_ATTRIBUTE_CAN_WRITE,cw);
        if succeeded(hr) then begin
          if cw then writeln('The attribute WPD_PROPERTY_ATTRIBUTE_CAN_WRITE for the WPD_OBJECT_NAME reports TRUE'+sLineBreak
                            +'This means that the property can be changed/updated')
          else writeln('The attribute WPD_PROPERTY_ATTRIBUTE_CAN_WRITE for the WPD_OBJECT_NAME reports FALSE'+sLineBreak
                            +'This means that the property cannot be changed/updated');
          end
        else WriteErrMsg (Format('Failed to get the WPD_PROPERTY_ATTRIBUTE_CAN_WRITE value from WPD_OBJECT_NAME on object "%s"',[sel]),hr);
        end;
      end;
    if cw then begin
      // 4) Prompt the user for the new value of the WPD_OBJECT_NAME property only if the property attributes report
      // that it can be changed/updated.
      write(Format('Enter the new WPD_OBJECT_NAME for the object "%s": ',[sel])); readln(nn);
      if length(nn)=0 then Exit;

      // 5) CoCreate an IPortableDeviceValues interface to hold the the property values
      // we wish to write.
      hr:=CoCreateInstance(CLSID_PortableDeviceValues,nil,CLSCTX_INPROC_SERVER,
                           IPortableDeviceValues,objectPropertiesToWrite);
      if succeeded(hr) and (objectPropertiesToWrite<>nil) then begin
        hr:=objectPropertiesToWrite.SetStringValue(WPD_OBJECT_NAME,PChar(nn));
        if failed(hr) then WriteErrMsg ('Failed to add WPD_OBJECT_NAME to IPortableDeviceValues',hr);
        end;
      // 6) Call SetValues() passing the collection of specified PROPERTYKEYs.
      if succeeded(hr) then begin
        hr:=properties.SetValues(PChar(sel),        // The object whose properties we are setting
                          objectPropertiesToWrite,               // The properties we want to set
                          propertyWriteResults);              // Driver supplied property result values for the property set operation
        if failed(hr) then WriteErrMsg (Format('Failed to set properties for object "%s"',[sel]),hr)
        else writeln(Format('The WPD_OBJECT_NAME property on object "%s" was written successfully (Read the properties again to see the updated value)',[sel]));
        end;
      end;
    end;
  end;

// Retreives the object identifier for the persistent unique identifier
procedure GetObjectIdentifierFromPersistentUniqueIdentifier (device : IPortableDevice);
var
  hr   : HResult;
  sel  : string;
  Content      : IPortableDeviceContent;
  persistentUniqueID,
  objectID     : TPropVariant;
  persistentUniqueIDs,
  objectIDs    : IPortableDevicePropVariantCollection;
begin
  // Prompt user to enter an object identifier on the device to write properties on.
  write('Enter the Persistant Unique Identifier of the object you wish to convert into an object identifier: '); readln(sel);
  if length(sel)=0 then Exit;

  // 1) Get an IPortableDeviceContent interface from the IPortableDevice interface to
  // access the content-specific methods.
  hr:=device.Content(content);
  if failed(hr) then WriteErrMsg ('Failed to get IPortableDeviceContent from IPortableDevice',hr)
  else begin
    // 2) CoCreate an IPortableDevicePropVariantCollection interface to hold the the Unique Identifiers
    // to query for Object Identifiers.
    // NOTE: This is a collection interface so more than 1 identifier can be requested at a time.
    //       This sample only requests a single unique identifier.
    hr:=CoCreateInstance(CLSID_PortableDevicePropVariantCollection,nil,CLSCTX_INPROC_SERVER,
                          IPortableDevicePropVariantCollection,persistentUniqueIDs);
    if succeeded(hr) then begin
      // Initialize a PROPVARIANT structure with the persistent unique identifier string
      // that the user selected above. This memory will be freed when PropVariantClear() is
      // called below.
      hr:=InitPropVariantFromString(pchar(sel),persistentUniqueID);
      if succeeded(hr) then begin
        // Add the object identifier to the objects-to-delete list
        // (We are only deleting 1 in this example)
        hr:=persistentUniqueIDs.Add(persistentUniqueID);
        if succeeded(hr) then begin
          // 3) Attempt to get the unique idenifier for the object from the device
          hr:=content.GetObjectIDsFromPersistentUniqueIDs(persistentUniqueIDs,objectIDs);
          if succeeded(hr) then begin
            hr:=objectIDs.GetAt(0,objectID);
            if succeeded(hr) then writeln(Format('The persistent unique identifier "%s" relates to object identifier "%s" on the device',[sel,objectID.pwszVal]))
            else WriteErrMsg (Format('Failed to get the object identifier for "%s" from the IPortableDevicePropVariantCollection',[sel]),hr);
            PropVariantClear(objectID);
            end
          else WriteErrMsg (Format('Failed to get the object identifier from persistent object identifier "%s"',[sel]),hr);
          end
        else WriteErrMsg ('Failed to get the object identifier from persistent object idenifier because we could no add the persistent object identifier string to the IPortableDevicePropVariantCollection',hr)
        end
      else begin
        hr:=E_OUTOFMEMORY;
        WriteErrMsg ('Failed to get the object identifier because we could no allocate memory for the persistent object identifier string',hr);
        end;
      // Free any allocated values in the PROPVARIANT before exiting
      PropVariantClear(persistentUniqueID);
      end;
    end;
  end;

//===================================================================
// from "ContentTransfer.cpp"

// Fills out properties that accompany updating an object's data...
function GetPropertiesForUpdateData (const filePath : string; fileStream : IStream;
                                     var objectProperties : IPortableDeviceValues) : HResult;
var
  statstg : tagSTATSTG;
  fn : string;
begin
  objectProperties:=nil;
  // CoCreate an IPortableDeviceValues interface to hold the the object information
  Result:=CoCreateInstance(CLSID_PortableDeviceValues,nil,CLSCTX_INPROC_SERVER,IPortableDeviceValues,objectProperties);
  if succeeded(Result) then begin
    // Set the WPD_OBJECT_SIZE by requesting the total size of the
    // data stream.
    Result:=fileStream.Stat(statstg,STATFLAG_NONAME);
    if succeeded(Result) then begin
      Result:=objectProperties.SetUnsignedLargeIntegerValue(WPD_OBJECT_SIZE,statstg.cbSize.QuadPart);
      if failed(Result) then WriteErrMsg ('Failed to Failed to set WPD_OBJECT_SIZE',Result)
      end
    else WriteErrMsg ('Failed to get file''s total size',Result);
    // Set the WPD_OBJECT_ORIGINAL_FILE_NAME by splitting the file path
    // into a separate filename.
    fn:=ExtractFilename(filePath);
    if length(fn)>0 then begin
      Result:=objectProperties.SetStringValue(WPD_OBJECT_ORIGINAL_FILE_NAME,PChar(fn));
      if failed(Result) then WriteErrMsg ('Failed to set WPD_OBJECT_ORIGINAL_FILE_NAME',Result);
      end
    else begin
      Result:=E_INVALIDARG;
      WriteErrMsg ('Failed to extract the filename from the file path',Result)
      end;
    // Set the WPD_OBJECT_NAME.  We are using the  file name without its file extension in this
    // example for the object's name.  The object name could be a more friendly name like
    // "This Cool Song" or "That Cool Picture".
    if succeeded(Result) then begin
      fn:=ChangeFileExt(fn,'');
      Result:=objectProperties.SetStringValue(WPD_OBJECT_NAME,PChar(fn))
      end;
    end;
  end;

// Updates a selected object's properties and data (WPD_RESOURCE_DEFAULT).
procedure UpdateContentOnDevice (device : IPortableDevice; const contentType : TGuid;
                                 const fileTypeFilter,defaultFileExtension : string);
var
  hr   : HResult;
  sel,fp,tf   : string;
  otsz,tbw : cardinal;
  ofn         : TOpenFilename;
  fileStream,tempStream : IStream;
  Content               : IPortableDeviceContent;
  content2              : IPortableDeviceContent2;
  properties            : IPortableDeviceProperties;
  objectProperties      : IPortableDeviceValues;
  objectContentType     : TGuid;
  finalObjectDataStream : IPortableDeviceDataStream;
  finalObjectProperties : IPortableDeviceValues;
begin
  // Prompt user to enter an object identifier for the object on the device to update.
  write('Enter the identifier of the object to update: '); readln(sel);
  if length(sel)=0 then Exit;

  // 1) Get an IPortableDeviceContent interface from the IPortableDevice interface to
  // access the content-specific methods.
  hr:=device.Content(content);
  if failed(hr) then WriteErrMsg ('Failed to get IPortableDeviceContent from IPortableDevice',hr)
  else begin
    hr:=content.QueryInterface(IID_IPortableDeviceContent2,content2);
    if failed(hr) then WriteErrMsg ('Failed to get IPortableDeviceContent2 from IPortableDeviceContent',hr)
    else begin
      // 2) (Optional) Check if the object is of the correct content type. This also ensures the user-specified object ID is valid.
      hr:=content2.Properties(properties);
      if failed(hr) then WriteErrMsg ('Failed to get IPortableDeviceProperties from IPortableDeviceContent2',hr)
      else begin
        hr:=properties.GetValues(PChar(sel),nil,objectProperties);
        if failed(hr) then WriteErrMsg (Format('Failed to get all properties for object (%s)',[sel]),hr)
        else begin
          hr:=objectProperties.GetGuidValue(WPD_OBJECT_CONTENT_TYPE,objectContentType);
          if failed(hr) then WriteErrMsg (Format('Failed to get WPD_OBJECT_CONTENT_TYPE for object (%s)',[sel]),hr)
          else if objectContentType<>contentType then begin
            hr:=E_INVALIDARG;
            WriteErrMsg (Format('Object (%s) is not of the correct content type',[sel]),hr)
            end;
          end;
        end;
      end;
    end;
  // 3) Present the user with a File Open dialog.  Our sample is
  // restricting the types to user-specified forms.
  if succeeded(hr) then begin
    FillChar(ofn,SizeOf(TOpenFilename),0);
    with ofn do begin
      lStructSize:=sizeof(TOpenFilename);
      hwndOwner:=0;
      nMaxFile:=MAX_PATH;
      SetLength(fp,nMaxFile+2);
      lpstrFile:=PChar(fp);
      FillChar(lpstrFile^,(nMaxFile+2)*SizeOf(Char),0);
      tf:=AllocFilterStr(fileTypeFilter);
      lpstrFilter:=PChar(tf);
      nFilterIndex:=1;
      lpstrDefExt:=PChar(defaultFileExtension);
      end;
    // 4) Open the file and add required properties about the file being transferred
    if GetOpenFileName(ofn) then begin
      // Open the selected file as an IStream.  This will simplify reading the
      // data and writing to the device.
      hr:=SHCreateStreamOnFileEx(PChar(fp),STGM_READ,FILE_ATTRIBUTE_NORMAL,false,nil,fileStream);
      if succeeded(hr) then begin
        // Get the required properties needed to properly describe the data being
        // transferred to the device.
        hr:=GetPropertiesForUpdateData (fp,                     // Full file path to the data file
                                        fileStream,             // Open IStream that contains the data
                                        finalObjectProperties); // Returned properties describing the data
        if failed(hr) then WriteErrMsg ('Failed to get properties needed to transfer a file to the device',hr);
        end
      else WriteErrMsg (Format('Failed to open file named (%s) to transfer to device',[fp]),hr);
      // 5) Transfer for the content to the device
      if succeeded(hr) then begin
        hr:=content2.UpdateObjectWithPropertiesAndData(PChar(sel),
                                                       finalObjectProperties,      // Properties describing the object data
                                                       tempStream,                 // Returned object data stream (to transfer the data to)
                                                       otsz);                      // Returned optimal buffer size to use during transfer
        // Once we have a the IStream returned from UpdateObjectWithPropertiesAndData,
        // QI for IPortableDeviceDataStream so we can use the additional methods
        // to get more information about the object (i.e. The newly created object
        // identifier on the device)
        if succeeded(hr) then begin
          hr:=tempStream.QueryInterface(IID_IPortableDeviceDataStream,finalObjectDataStream);
          if failed(hr) then WriteErrMsg ('Failed to QueryInterface for IPortableDeviceDataStream',hr)
          end;
        // Since we have IStream-compatible interfaces, call our helper function
        // that copies the contents of a source stream into a destination stream.
        if succeeded(hr) then begin
          tbw:=0;
          hr:=StreamCopy (finalObjectDataStream, // Destination (The Object to transfer to)
                          fileStream,            // Source (The File data to transfer from)
                          otsz,                  // The driver specified optimal transfer buffer size
                          tbw);                  // The total number of bytes transferred from file to the device
          if failed(hr) then WriteErrMsg ('Failed to transfer object data to device',hr);
          end
        else WriteErrMsg ('Failed to get IStream (representing destination object data on the device) from UpdateObjectWithPropertiesAndData',hr);
        // After transferring content to the device, the client is responsible for letting the
        // driver know that the transfer is complete by calling the Commit() method
        // on the IPortableDeviceDataStream interface.
        if succeeded(hr) then begin
          hr:=finalObjectDataStream.Commit(STGC_DEFAULT);
          if succeeded(hr) then
            writeln(Format('The file "%s" was transferred to the device to object "%s"',[fp,sel]))
          else WriteErrMsg ('Failed to commit new object data to device',hr);
          end;
        end;
      end
    else writeln('The update operation was cancelled.');
    end;
  end;

//===================================================================
// from "DeviceEnumeration.cpp"

// Creates and populates an IPortableDeviceValues with information about
// this application.  The IPortableDeviceValues is used as a parameter
// when calling the IPortableDevice::Open() method.
procedure GetClientInformation (var clientInformation : IPortableDeviceValues);
var
  hr   : HResult;
begin
  clientInformation:=nil;
  hr:=CoCreateInstance(CLSID_PortableDeviceValues,nil,CLSCTX_INPROC_SERVER,IPortableDeviceValues,clientInformation);
  if succeeded(hr) then begin
  // Attempt to set all bits of client information
    hr:=clientInformation.SetStringValue(WPD_CLIENT_NAME,CLIENT_NAME);
    if failed(hr) then WriteErrMsg ('Failed to set WPD_CLIENT_NAME',hr);
    hr:=clientInformation.SetUnsignedIntegerValue(WPD_CLIENT_MAJOR_VERSION,CLIENT_MAJOR_VER);
    if failed(hr) then WriteErrMsg ('Failed to set WPD_CLIENT_MAJOR_VERSION',hr);
    hr:=clientInformation.SetUnsignedIntegerValue(WPD_CLIENT_MINOR_VERSION,CLIENT_MINOR_VER);
    if failed(hr) then WriteErrMsg ('Failed to set WPD_CLIENT_MINOR_VERSION',hr);
    hr:=clientInformation.SetUnsignedIntegerValue(WPD_CLIENT_REVISION,CLIENT_REVISION);
    if failed(hr) then WriteErrMsg ('Failed to set WPD_CLIENT_REVISION',hr);
    //  Some device drivers need to impersonate the caller in order to function correctly.  Since our application does not
    //  need to restrict its identity, specify SECURITY_IMPERSONATION so that we work with all devices.
    hr:=clientInformation.SetSignedIntegerValue(WPD_CLIENT_SECURITY_QUALITY_OF_SERVICE,SECURITY_IMPERSONATION);
    if failed(hr) then WriteErrMsg ('Failed to set WPD_CLIENT_SECURITY_QUALITY_OF_SERVICE',hr);
    end
  else WriteErrMsg ('Failed to CoCreateInstance CLSID_PortableDeviceValues',hr);
  end;

// Get the device friendly name for the specified PnPDeviceID string
function FriendlyNameAsString(pdm : IPortableDeviceManager; const devid : string) : string;
var
  fnl  : DWORD;
  hr   : HResult;
  sBuf : array of WChar;
  pnul : PWChar;
begin
  fnl:=0; Result:=''; pnul:=nil;
  hr:=pdm.GetDeviceFriendlyName(pchar(devid),pnul^,fnl);
  if Failed(hr) then Result:=ErrorMsg('Failed to get number of characters for device friendly name',hr)
  else if fnl>0 then begin
    SetLength(sBuf,fnl);
    hr:=pdm.GetDeviceFriendlyName(pchar(devid),sbuf[0],fnl);
    if Failed(hr) then Result:=ErrorMsg('Failed to get device friendly name',hr)
    else Result:=pchar(@sbuf[0]);
    sBuf:=nil;
    end
  else Result:='The device did not provide a device friendly name';
  end;

// Get the device manufacturer for the specified PnPDeviceID string
function ManufacturerAsString(pdm : IPortableDeviceManager; const devid : string) : string;
var
  fnl  : DWORD;
  hr   : HResult;
  sBuf : array of WChar;
  pnul : PWChar;
begin
  fnl:=0; Result:=''; pnul:=nil;
  hr:=pdm.GetDeviceManufacturer(pchar(devid),pnul^,fnl);
  if Failed(hr) then Result:=ErrorMsg('Failed to get number of characters for device manufacturer',hr)
  else if fnl>0 then begin
    SetLength(sBuf,fnl);
    hr:=pdm.GetDeviceManufacturer(pchar(devid),sbuf[0],fnl);
    if Failed(hr) then Result:=ErrorMsg('Failed to get device manufacturer',hr)
    else Result:=pchar(@sbuf[0]);
    sBuf:=nil;
    end
  else Result:='The device did not provide a manufacturer';
  end;

// Get the device discription for the specified PnPDeviceID string
function DescriptionAsString(pdm : IPortableDeviceManager; const devid : string) : string;
var
  fnl  : DWORD;
  hr   : HResult;
  sBuf : array of WChar;
  pnul : PWChar;
begin
  fnl:=0; Result:=''; pnul:=nil;
  hr:=pdm.GetDeviceDescription(pchar(devid),pnul^,fnl);
  if Failed(hr) then Result:=ErrorMsg('Failed to get number of characters for device description',hr)
  else if fnl>0 then begin
    SetLength(sBuf,fnl);
    hr:=pdm.GetDeviceDescription(pchar(devid),sbuf[0],fnl);
    if Failed(hr) then Result:=ErrorMsg('Failed to get device description',hr)
    else Result:=pchar(@sbuf[0]);
    sBuf:=nil;
    end
  else Result:='The device did not provide a description';
  end;

// Enumerates all Windows Portable Devices, displays the friendly name,
// manufacturer, and description of each device.  This function also
// returns the total number of devices found.
function EnumerateAllDevices : cardinal;
var
  hr   : HResult;
  nc,i : cardinal;
  deviceManager : IPortableDeviceManager;
  pnpDeviceIDs  : TCharArray;
  pnul : ppchar;
begin
  Result:=0;
  hr:=CoCreateInstance(CLSID_PortableDeviceManager,nil,CLSCTX_INPROC_SERVER,IID_IPortableDeviceManager,deviceManager);
  if Failed(hr) then WriteErrMsg ('Failed to CoCreateInstance CLSID_PortableDeviceManager',hr)
  else begin
  // 1) Pass nullptr as the PWSTR array pointer to get the total number
  // of devices found on the system.
    pnul:=nil; nc:=0;
    hr:=deviceManager.GetDevices(pnul^,nc);
    if Failed(hr) then WriteErrMsg ('Failed to get number of devices on the system',hr);
  // Report the number of devices found.  NOTE: we will report 0, if an error
  // occured.
    writeln(Format('%u Windows Portable Device(s) found on the system',[nc]));

    // 2) Allocate an array to hold the PnPDeviceID strings returned from
    // the IPortableDeviceManager::GetDevices method
    if succeeded(hr) and (nc>0) then begin
      Result:=nc;
      SetLength(pnpDeviceIDs,nc);
      hr:=deviceManager.GetDevices(pnpDeviceIDs[0],nc);
      if succeeded(hr) then begin
        // For each device found, display the devices friendly name,
        // manufacturer, and description strings.
        for i:=0 to nc-1 do begin
          writeln ('[',i,'] Friendly Name: ',FriendlyNameAsString(deviceManager,pnpDeviceIDs[i]));
          writeln ('    Manufacturer:  ',ManufacturerAsString(deviceManager,pnpDeviceIDs[i]));
          writeln ('    Description:   ',DescriptionAsString(deviceManager,pnpDeviceIDs[i]));
          end;
        pnpDeviceIDs:=nil;
        end
      else WriteErrMsg('Failed to get the device list from the system',hr);
      end;
    end;
  end;

// Calls EnumerateDevices() function to display devices on the system
// and to obtain the total number of devices found.  If 1 or more devices
// are found, this function prompts the user to choose a device using
// a zero-based index.
procedure ChooseDevice (var device : IPortableDevice);
var
  hr   : HResult;
  currentDeviceIndex,
  pnpDeviceIDCount,
  retrievedDeviceIDCount : cardinal;
  pnpDeviceIDs : TCharArray;
  deviceManager : IPortableDeviceManager;
  clientInformation : IPortableDeviceValues;
begin
  GetClientInformation(clientInformation);
// Enumerate and display all devices.
  pnpDeviceIDCount:=EnumerateAllDevices;
  if pnpDeviceIDCount>0 then begin
    writeln;
    write('Enter the index of the device you wish to use: '); readln(currentDeviceIndex);
    if (currentDeviceIndex>=pnpDeviceIDCount) then begin
      writeln('An invalid device index was specified, defaulting to the first device in the list.');
      currentDeviceIndex:=0;
      end;
    // CoCreate the IPortableDeviceManager interface to enumerate
    // portable devices and to get information about them.
    hr:=CoCreateInstance(CLSID_PortableDeviceManager,nil,CLSCTX_INPROC_SERVER,IID_IPortableDeviceManager,deviceManager);
    if failed(hr) then WriteErrMsg ('Failed to CoCreateInstance CLSID_PortableDeviceManager',hr)
    else begin
      SetLength(pnpDeviceIDs,pnpDeviceIDCount); retrievedDeviceIDCount:=pnpDeviceIDCount;
      hr:=deviceManager.GetDevices(pnpDeviceIDs[0],retrievedDeviceIDCount);
      if succeeded(hr) then begin
        hr:=CoCreateInstance(CLSID_PortableDeviceFTM,nil,CLSCTX_INPROC_SERVER,IID_IPortableDevice,device);
        if succeeded(hr) then begin
          hr:=device.Open(pnpDeviceIDs[currentDeviceIndex],clientInformation);
          if hr=E_ACCESSDENIED then begin
            WriteErrMsg ('Failed to Open the device for Read Write access, will open it for Read-only access instead',hr);
            clientInformation.SetUnsignedIntegerValue(WPD_CLIENT_DESIRED_ACCESS, GENERIC_READ);
            hr:=device.Open(pnpDeviceIDs[currentDeviceIndex],clientInformation);
            end;
          if failed(hr) then begin
            WriteErrMsg ('Failed to Open the device',hr);
            device._Release;
            end;
          end
        else WriteErrMsg ('Failed to CoCreateInstance CLSID_PortableDeviceFTM',hr);
        end
      else WriteErrMsg ('Failed to get the device list from the system',hr);
      end;
    end;
  end;

//===================================================================
// from "WpdApiSample.cpp"
var
  hr   : HResult;
  Device : IPortableDevice;
  selectionIndex : integer;
begin
  BulkPropertyOperationEvent:=0; eventCookie:='';
  // Initialize COM for COINIT_MULTITHREADED
  CoUninitialize;
  hr:=CoInitializeEx(nil,COINIT_MULTITHREADED);
  if SUCCEEDED(hr) then begin
    ChooseDevice(Device);
    if Device<>nil then begin
      selectionIndex:=0;
      repeat
        writeln;
        writeln('Delphi WPD Sample Application');
        writeln('=======================================');
        writeln('0.  Enumerate all Devices');
        writeln('1.  Choose a Device');
        writeln('2.  Enumerate all content on the device');
        writeln('3.  Transfer content from the device');
        writeln('4.  Delete content from the device');
        writeln('5.  Move content already on the device to another location on the device');
        writeln('6   Transfer Image content to the device');
        writeln('7.  Transfer Music content to the device');
        writeln('8.  Transfer Contact (VCARD file) content to the device');
        writeln('9.  Transfer Contact (Defined by Properties Only) to the device');
        writeln('10. Create a folder on the device');
        writeln('11. Add a Contact Photo resource to an object');
        writeln('12. Read properties on a content object');
        writeln('13. Write properties on a content object');
        writeln('14. Get an object identifier from a Persistent Unique Identifier (PUID)');
        writeln('15. List all functional categories supported by the device');
        writeln('16. List all functional objects on the device');
        writeln('17. List all content types supported by the device');
        writeln('18. List rendering capabilities supported by the device');
        writeln('19. Register to receive device event notifications');
        writeln('20. Unregister from receiving device event notifications');
        writeln('21. List all events supported by the device');
        writeln('22. List all hint locations supported by the device');
        writeln('==(Advanced BULK property operations)==');
        writeln('23. Read properties on multiple content objects');
        writeln('24. Write properties on multiple content objects');
        writeln('25. Read properties on multiple content objects using object format');
        writeln('==(Update content operations)==');
        writeln('26. Update Image content (properties and data) on the device');
        writeln('27. Update Music content (properties and data) on the device');
        writeln('28. Update Contact content (properties and data) on the device');
        writeln('29  List all resource types supported by the device');
        writeln('99. Exit');
        write('Enter number selection: '); readln(selectionIndex);

        if selectionIndex<>99 then case selectionIndex of
          0 : EnumerateAllDevices;
          1 : begin
              // Unregister any device event registrations before
              // creating a new IPortableDevice
              // todo ...
            Device:=nil;
            ChooseDevice(Device);
            end;
          2 : begin
            EnumerateAllContent(Device);
            end;
          3 : begin
            TransferContentFromDevice(Device);
            end;
          4 : begin
            DeleteContentFromDevice(Device);
            end;
          5 : begin
            MoveContentAlreadyOnDevice(Device);
            end;
          6 : begin
            TransferContentToDevice(Device,WPD_CONTENT_TYPE_IMAGE,ImgFilter,JpgExt);
            end;
          7 : begin
            TransferContentToDevice(Device,WPD_CONTENT_TYPE_AUDIO,MusicFilter,Mp3Ext);
            end;
          8 : begin
            TransferContentToDevice(Device,WPD_CONTENT_TYPE_CONTACT,ContactFilter,VcfExt);
            end;
          9 : begin
            TransferContactToDevice(Device);
            end;
          10 : begin
            CreateFolderOnDevice(Device);
            end;
          11 : begin
            CreateContactPhotoResourceOnDevice(Device);
            end;
          12 : begin
            ReadContentProperties(Device);
            end;
          13 : begin
            WriteContentProperties(Device);
            end;
          14 : begin
            GetObjectIdentifierFromPersistentUniqueIdentifier(Device);
            end;
          15 : begin
            ListFunctionalCategories(Device);
            end;
          16 : begin
            ListFunctionalObjects(Device);
            end;
          17 : begin
            ListSupportedContentTypes(Device);
            end;
          18 : begin
            ListRenderingCapabilityInformation(Device);
            end;
          19 : begin
            RegisterForEventNotifications(Device,eventCookie);
            end;
          20 : begin
            UnregisterForEventNotifications(Device,eventCookie);
            end;
          21 : begin
            ListSupportedEvents(Device);
            end;
          22 : begin
            ReadHintLocations(Device);
            end;
          23: begin
            ReadContentPropertiesBulk(Device);
            end;
          24 : begin
            WriteContentPropertiesBulk(Device);
            end;
          25 : begin
            ReadContentPropertiesBulkFilteringByFormat(Device);
            end;
          26 : begin
            UpdateContentOnDevice(Device,WPD_CONTENT_TYPE_IMAGE,ImgFilter,JpgExt);
            end;
          27 : begin
            UpdateContentOnDevice(Device,WPD_CONTENT_TYPE_AUDIO,MusicFilter,Mp3Ext);
            end;
          28 : begin
            UpdateContentOnDevice(Device,WPD_CONTENT_TYPE_CONTACT,ContactFilter,VcfExt);
            end;
          end;
        until selectionIndex=99;
      end;
  // Uninitialize COM
    CoUninitialize;
    end
  else WriteErrMsg ('Failed to CoInitializeEx COINIT_MULTITHREADED',hr);
//  readln;

end.

