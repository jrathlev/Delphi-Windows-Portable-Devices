### Delphi interface to Windows Portable Device

The use of the Portable Device interface is demonstrated by a sample program
provided by Microsoft at [GitHub](https://github.com/microsoft/Windows-classic-samples/tree/main/Samples/PortableDeviceCOM). 
The source code ist written in C++ and requires Visual Studio. To use the
Windows Portable Device functions under Delphi, it is first necessary to convert 
the required header files into Delphi units and then to translate the cpp files
into pas files. The sample demonstrates the following tasks using the WPD API:
  
- Enumerate portable devices
- Enumerate content on a portable device
- Query the capabilities of a portable device
- Read and write properties for content on a portable device
- Transfer content on or off for a portable device
- Register or unregister for portable device events

The sample ist provided as a Delphi console application:

- Unit **IStreamApi.pas** - Replaces some declarations in Winpai.ActiveX
- Unit **PortableDeviceDefs.pas** - Types and constants from PortableDevice.h
- Unit **PortableDeviceApi.pas** - Delphi interface to Windows Portable Device
- Program **WpdSample.dpr** - Sample program
 
