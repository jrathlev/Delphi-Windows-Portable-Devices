object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = 'MainForm'
  ClientHeight = 336
  ClientWidth = 889
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnResize = FormResize
  OnShow = FormShow
  DesignSize = (
    889
    336)
  PixelsPerInch = 96
  TextHeight = 13
  object Label5: TLabel
    Left = 10
    Top = 10
    Width = 80
    Height = 13
    Caption = 'Portable Devices'
  end
  object Label6: TLabel
    Left = 260
    Top = 10
    Width = 55
    Height = 13
    Caption = 'Directories:'
  end
  object lbDevices: TListBox
    Left = 10
    Top = 25
    Width = 241
    Height = 106
    ItemHeight = 13
    TabOrder = 0
    OnClick = lbDevicesClick
  end
  object gbDevice: TGroupBox
    Left = 10
    Top = 135
    Width = 241
    Height = 151
    TabOrder = 1
    object Label1: TLabel
      Left = 15
      Top = 25
      Width = 69
      Height = 13
      Caption = 'Manufacturer:'
    end
    object Label2: TLabel
      Left = 15
      Top = 45
      Width = 57
      Height = 13
      Caption = 'Description:'
    end
    object laManu: TLabel
      Left = 95
      Top = 25
      Width = 3
      Height = 13
    end
    object laDesc: TLabel
      Left = 95
      Top = 45
      Width = 3
      Height = 13
    end
    object Label4: TLabel
      Left = 15
      Top = 85
      Width = 69
      Height = 13
      Caption = 'Power source:'
    end
    object laPower: TLabel
      Left = 95
      Top = 85
      Width = 3
      Height = 13
    end
    object Label7: TLabel
      Left = 15
      Top = 65
      Width = 28
      Height = 13
      Caption = 'Type:'
    end
    object laType: TLabel
      Left = 95
      Top = 65
      Width = 3
      Height = 13
    end
    object Label8: TLabel
      Left = 15
      Top = 105
      Width = 48
      Height = 13
      Caption = 'Firmware:'
    end
    object laFirmware: TLabel
      Left = 95
      Top = 105
      Width = 3
      Height = 13
    end
    object laStatus: TLabel
      Left = 15
      Top = 125
      Width = 3
      Height = 13
    end
  end
  object btnUpdate: TButton
    Left = 10
    Top = 293
    Width = 96
    Height = 36
    Anchors = [akLeft, akBottom]
    Caption = 'Reload devices'
    TabOrder = 2
    OnClick = btnUpdateClick
    ExplicitTop = 275
  end
  object tvObjects: TTreeView
    Left = 260
    Top = 25
    Width = 221
    Height = 259
    Anchors = [akLeft, akTop, akBottom]
    Indent = 19
    ShowRoot = False
    TabOrder = 3
    OnClick = tvObjectsClick
    OnExpanding = tvObjectsExpanding
    ExplicitHeight = 241
  end
  object lvFiles: TListView
    Left = 490
    Top = 25
    Width = 391
    Height = 259
    Anchors = [akLeft, akTop, akRight, akBottom]
    Columns = <
      item
        Caption = 'Filename'
        Width = 145
      end
      item
        Caption = 'Date'
        Width = 120
      end
      item
        Caption = 'Size'
        Width = 70
      end>
    HideSelection = False
    MultiSelect = True
    TabOrder = 4
    ViewStyle = vsReport
    OnClick = lvFilesClick
    ExplicitHeight = 241
  end
  object btnCopy: TButton
    Left = 770
    Top = 293
    Width = 111
    Height = 36
    Anchors = [akRight, akBottom]
    Caption = 'Copy files'
    TabOrder = 5
    OnClick = btnCopyClick
    ExplicitTop = 275
  end
  object paCopy: TPanel
    Left = 265
    Top = 293
    Width = 496
    Height = 36
    Anchors = [akLeft, akRight, akBottom]
    BevelOuter = bvNone
    TabOrder = 6
    ExplicitTop = 275
    object laPath: TLabel
      Left = 10
      Top = 20
      Width = 18
      Height = 13
      Caption = 'xxx'
    end
    object Label3: TLabel
      Left = 10
      Top = 3
      Width = 43
      Height = 13
      Caption = 'Copying:'
    end
  end
  object btnShowDirs: TButton
    Left = 125
    Top = 293
    Width = 126
    Height = 36
    Anchors = [akLeft, akBottom]
    Caption = 'Show directories'
    TabOrder = 7
    OnClick = lbDevicesClick
    ExplicitTop = 275
  end
  object FolderDialog: TFileOpenDialog
    DefaultFolder = 'E:\Test'
    FavoriteLinks = <>
    FileTypes = <>
    OkButtonLabel = 'Select folder'
    Options = [fdoPickFolders, fdoForceShowHidden]
    Left = 225
    Top = 185
  end
end
