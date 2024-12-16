{==============================================================================
  ___  ___ ___  __™
 |   \/ __|   \| |
 | |) \__ \ |) | |__
 |___/|___/___/|____|
    SDL for Delphi

 Copyright © 2024-present tinyBigGAMES™ LLC
 All Rights Reserved.

 https://github.com/tinyBigGAMES/DSDL
==============================================================================}

program Testbed;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  UTestbed in 'UTestbed.pas',
  DSDL in '..\..\src\DSDL.pas';

begin
  try
    RunTests();
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
