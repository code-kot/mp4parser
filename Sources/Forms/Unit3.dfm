object Form3: TForm3
  Left = 0
  Top = 0
  Caption = 'Form3'
  ClientHeight = 511
  ClientWidth = 890
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Menu = mm1
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object spl1: TSplitter
    Left = 350
    Top = 0
    Height = 511
    ExplicitLeft = 136
    ExplicitTop = 208
    ExplicitHeight = 100
  end
  object mmo1: TMemo
    Left = 353
    Top = 0
    Width = 537
    Height = 511
    Align = alClient
    Font.Charset = RUSSIAN_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Lucida Console'
    Font.Style = []
    Lines.Strings = (
      'mmo1')
    ParentFont = False
    ScrollBars = ssBoth
    TabOrder = 0
  end
  object tv1: TTreeView
    Left = 0
    Top = 0
    Width = 350
    Height = 511
    Align = alLeft
    Indent = 19
    PopupMenu = pm1
    TabOrder = 1
  end
  object mm1: TMainMenu
    Left = 368
    Top = 48
    object mniFile: TMenuItem
      Caption = 'File'
      object mniFileOpen: TMenuItem
        Action = flpnFileOpen
      end
      object mniExit: TMenuItem
        Caption = 'Exit'
        OnClick = mniExitClick
      end
    end
  end
  object actlst1: TActionList
    Left = 416
    Top = 48
    object flpnFileOpen: TFileOpen
      Category = 'File'
      Caption = '&Open...'
      Dialog.DefaultExt = 'mp4'
      Dialog.Filter = 'MP4 file|*.mp4'
      Hint = 'Open|Opens an existing file'
      ImageIndex = 7
      ShortCut = 16463
      OnAccept = flpnFileOpenAccept
    end
    object ALoadAtomData: TAction
      Category = 'Container'
      Caption = 'Load Atom Data'
      OnExecute = ALoadAtomDataExecute
    end
    object ALoadChildAtoms: TAction
      Category = 'Container'
      Caption = 'Load Child Atoms'
      OnExecute = ALoadChildAtomsExecute
    end
  end
  object pm1: TPopupMenu
    OnPopup = pm1Popup
    Left = 264
    Top = 40
    object mniLoadAtomData: TMenuItem
      Action = ALoadAtomData
    end
    object mniLoadChildAtoms: TMenuItem
      Action = ALoadChildAtoms
    end
  end
end