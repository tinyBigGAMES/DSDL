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

unit UTestbed;

interface

procedure RunTests();

implementation

uses
  System.SysUtils,
  DSDL;

procedure Pause();
begin
  WriteLn;
  Write('Press ENTER to continue...');
  ReadLn;
  WriteLn;
end;

procedure Test01();
var
  LWindow: PSDL_Window;
  LRenderer: PSDL_Renderer;
  LAtlas: PspAtlas;
  LSkeletonJson: PspSkeletonJson;
  LSkeletonData: PspSkeletonData;
  LAnimationStateData: PspAnimationStateData;
  LDrawable: PspSkeletonDrawable;
  LEvent: SDL_Event;
  LQuit: Boolean;
  LLastFrameTime, LNow: UInt64;
  LDeltaTime: Double;
begin
  if not SDL_Init(SDL_INIT_VIDEO) then
  begin
    Writeln('Error: ', SDL_GetError);
    Exit;
  end;

  LWindow := SDL_CreateWindow('DSDL: Spine #01', 800, 600, 0);
  if LWindow = nil then
  begin
    Writeln('Error: ', SDL_GetError);
    SDL_Quit;
    Exit;
  end;

  LRenderer := SDL_CreateRenderer(LWindow, 'opengl');
  if LRenderer = nil then
  begin
    Writeln('Error: ', SDL_GetError);
    SDL_DestroyWindow(LWindow);
    SDL_Quit;
    Exit;
  end;

  LAtlas := spAtlas_createFromFile('res/spine/spineboy/spineboy-pma.atlas', LRenderer);
  LSkeletonJson := spSkeletonJson_create(LAtlas);
  LSkeletonJson.scale := 0.5;
  LSkeletonData := spSkeletonJson_readSkeletonDataFile(LSkeletonJson, 'res/spine/spineboy/spineboy-pro.json');
  LAnimationStateData := spAnimationStateData_create(LSkeletonData);
  LAnimationStateData.defaultMix := 0.2;
  LDrawable := spSkeletonDrawable_create(LSkeletonData, LAnimationStateData);
  LDrawable.usePremultipliedAlpha := -1;
  LDrawable.skeleton^.x := 400;
  LDrawable.skeleton^.y := 500;
  spSkeleton_setToSetupPose(LDrawable.skeleton);
  spSkeletonDrawable_update(LDrawable, 0, SP_PHYSICS_UPDATE);
  spAnimationState_setAnimationByName(LDrawable.animationState, 0, 'portal', 0);
  spAnimationState_addAnimationByName(LDrawable.animationState, 0, 'run', -1, 0);

  LQuit := False;
  LLastFrameTime := SDL_GetPerformanceCounter;

  while not LQuit do
  begin
    while SDL_PollEvent(@LEvent) do
    begin
      if LEvent.&type = SDL_EVENT_QUIT then
      begin
        LQuit := True;
        Break;
      end;
    end;

    SDL_SetRenderDrawColor(LRenderer, 94, 93, 96, 255);
    SDL_RenderClear(LRenderer);

    LNow := SDL_GetPerformanceCounter;
    LDeltaTime := (LNow - LLastFrameTime) / SDL_GetPerformanceFrequency;
    LLastFrameTime := LNow;

    spSkeletonDrawable_update(LDrawable, LDeltaTime, SP_PHYSICS_UPDATE);
    spSkeletonDrawable_draw(LDrawable, LRenderer);

    SDL_RenderPresent(LRenderer);
  end;

  spSkeletonDrawable_dispose(LDrawable);
  spAnimationStateData_dispose(LAnimationStateData);
  spSkeletonJson_dispose(LSkeletonJson);
  spAtlas_dispose(LAtlas);

  SDL_DestroyRenderer(LRenderer);
  SDL_DestroyWindow(LWindow);
  SDL_Quit;
end;

procedure RunTests();
var
  LNum: Integer;
begin
  LNum := 01;
  case LNum of
    01: Test01();
  end;
  Pause();
end;

end.
