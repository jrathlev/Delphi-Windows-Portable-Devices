# Delphi interface to Windows Portable Devices

The use of the Portable Devices interface is demonstrated by a sample program
provided by Microsoft at [GitHub](https://github.com/microsoft/Windows-classic-samples/tree/main/Samples/PortableDeviceCOM). 
The source code is written in C++ and requires Visual Studio. To use the
Windows Portable Devices functions under Delphi, it is first necessary to convert 
the required header files into Delphi units and then to translate the cpp files
into pas files. 

## Console application sample
The sample demonstrates the following tasks using the WPD API:  
- Enumerate portable devices
- Enumerate content on a portable device
- Query the capabilities of a portable device
- Read and write properties for content on a portable device
- Transfer content on or off for a portable device
- Register or unregister for portable device events

#### Files:
- **WpdSample.dpr** - Sample program

## VCL applcation sample:
The Delphi VCL sample demonstrates the following tasks:
- Building a list of available portable devices
- Building a directory tree of the selected portable device
- Selecting a directory and displaying the associated files
- Copying the selected files to a Windows directory

#### Files:
- **PortableCopy.dpr** - VCL sample project file
- Unit **PortCopyMain.pas** - Main unit of sample project
- Form **PortCopyMain.dfm** - Main form of sample project

## Required units:
- Unit **IStreamApi.pas** - Replaces some declarations in Winapi.ActiveX
- Unit **PortableDeviceDefs.pas** - Types and constants from PortableDevice.h
- Unit **PortableDeviceApi.pas** - Delphi interface to Windows Portable Devices
- Unit **PortableDeviceUtils.pas** - Objects and functions to access Windows Portable Devices
- Unit **ExtFileUtils.pas** - Type definitions and functions for PortableDeviceUtils.pas 
- Unit **FileUtils.pas** - Type definitions and functions for file processing 

[Executable demos](https://github.com/jrathlev/Delphi-Windows-Portable-Device/tree/master/demo)

