### Delphi interface to Windows Portable Device

The use of the Portable Device interface is demonstrated by a sample program
provided by Microsoft at [GitHub](https://github.com/microsoft/Windows-classic-samples/tree/main/Samples/PortableDeviceCOM). 
The source code is written in C++ and requires Visual Studio. To use the
Windows Portable Device functions under Delphi, it is first necessary to convert 
the required header files into Delphi units and then to translate the cpp files
into pas files. 

The sample demonstrates the following tasks using the WPD API:
  
- Enumerate portable devices
- Enumerate content on a portable device
- Query the capabilities of a portable device
- Read and write properties for content on a portable device
- Transfer content on or off for a portable device
- Register or unregister for portable device events

The sample is provided as a Delphi console application:

- Program **WpdSample.dpr** - Sample program

Delphi VCL sample to copy files from a portable device to a Windows directory:

- Program **PortableCopy.dpr** - Delphi project file
- Unit **PortCopyMain.pas** - Main unit of project

Required units:
- Unit **IStreamApi.pas** - Replaces some declarations in Winpai.ActiveX
- Unit **PortableDeviceDefs.pas** - Types and constants from PortableDevice.h
- Unit **PortableDeviceApi.pas** - Delphi interface to Windows Portable Device
- Unit **PortableDeviceUtils.pas** - Objects and functions to access Windows Portable Devices
- Unit **FileUtils.pas** - Type definitions and functions for PortableDeviceUtils.pas 
