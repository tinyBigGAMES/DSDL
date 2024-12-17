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
  System.Math,
  DSDL;

const
  CZipFilename = 'Data.zip';

procedure Pause();
begin
  WriteLn;
  Write('Press ENTER to continue...');
  ReadLn;
  WriteLn;
end;

/// <summary>
/// Creates a ZIP archive from the specified input folder.
/// </summary>
/// <remarks>
/// This procedure uses the SDL_BuildZipFile function to compress the contents of a folder
/// and save it as a ZIP file.
/// </remarks>
procedure Test01();
begin
  // Call SDL_BuildZipFile to create a ZIP archive.
  // 'CZipFilename' specifies the name of the output ZIP file.
  // 'res' specifies the input folder to compress into the ZIP file.
  SDL_BuildZipFile(CZipFilename, 'res');
end;

/// <summary>
/// Demonstrates rendering a Spine animation using SDL and the Spine runtime integration.
/// </summary>
/// <remarks>
/// This procedure initializes an SDL window and renderer, loads Spine animation assets,
/// and plays the 'portal' and 'run' animations in a loop until the user closes the window.
/// It handles SDL event polling, frame timing, and resource cleanup.
/// </remarks>
procedure Test02();
var
  LWindow: PSDL_Window;                  // Pointer to the SDL window.
  LRenderer: PSDL_Renderer;              // Pointer to the SDL renderer.
  LAtlas: PspAtlas;                      // Atlas for Spine animation textures.
  LSkeletonJson: PspSkeletonJson;        // JSON parser for Spine skeleton data.
  LSkeletonData: PspSkeletonData;        // Spine skeleton data.
  LAnimationStateData: PspAnimationStateData; // State data for animation transitions.
  LDrawable: PspSkeletonDrawable;        // Drawable object for the Spine skeleton.
  LEvent: SDL_Event;                     // Event structure for SDL event handling.
  LQuit: Boolean;                        // Flag to control the main loop.
  LLastFrameTime, LNow: UInt64;          // Variables for frame timing.
  LDeltaTime: Double;                    // Time elapsed between frames.
begin
  // Initialize SDL video subsystem.
  if not SDL_Init(SDL_INIT_VIDEO) then
  begin
    Writeln('Error: ', SDL_GetError); // Print SDL initialization error.
    Exit; // Exit if initialization fails.
  end;

  // Create an SDL window with the specified title and size.
  LWindow := SDL_CreateWindow('DSDL: Load spine animation from file', 800, 600, 0);
  if LWindow = nil then
  begin
    Writeln('Error: ', SDL_GetError); // Print window creation error.
    SDL_Quit; // Clean up SDL resources.
    Exit;
  end;

  // Create an SDL renderer for the window with OpenGL backend.
  LRenderer := SDL_CreateRenderer(LWindow, 'opengl');
  if LRenderer = nil then
  begin
    Writeln('Error: ', SDL_GetError); // Print renderer creation error.
    SDL_DestroyWindow(LWindow);       // Destroy the created window.
    SDL_Quit;                         // Clean up SDL resources.
    Exit;
  end;

  // Load the Spine animation atlas.
  LAtlas := spAtlas_createFromFile('res/spine/spineboy/spineboy-pma.atlas', LRenderer);

  // Create a skeleton JSON parser and scale the skeleton.
  LSkeletonJson := spSkeletonJson_create(LAtlas);
  LSkeletonJson.scale := 0.5;

  // Read skeleton data from the JSON file.
  LSkeletonData := spSkeletonJson_readSkeletonDataFile(LSkeletonJson, 'res/spine/spineboy/spineboy-pro.json');

  // Create animation state data and set default transition mix.
  LAnimationStateData := spAnimationStateData_create(LSkeletonData);
  LAnimationStateData.defaultMix := 0.2;

  // Create a drawable skeleton object and set its initial position.
  LDrawable := spSkeletonDrawable_create(LSkeletonData, LAnimationStateData);
  LDrawable.usePremultipliedAlpha := -1; // Enable premultiplied alpha.
  LDrawable.skeleton^.x := 400;         // Set X position.
  LDrawable.skeleton^.y := 500;         // Set Y position.

  // Set the skeleton to its setup pose.
  spSkeleton_setToSetupPose(LDrawable.skeleton);

  // Perform an initial skeleton update.
  spSkeletonDrawable_update(LDrawable, 0, SP_PHYSICS_UPDATE);

  // Set initial animation state: 'portal' followed by 'run' (looped).
  spAnimationState_setAnimationByName(LDrawable.animationState, 0, 'portal', 0);
  spAnimationState_addAnimationByName(LDrawable.animationState, 0, 'run', -1, 0);

  // Initialize the quit flag and timing variables.
  LQuit := False;
  LLastFrameTime := SDL_GetPerformanceCounter;

  // Main event loop.
  while not LQuit do
  begin
    // Poll SDL events.
    while SDL_PollEvent(@LEvent) do
    begin
      // Exit the loop if a quit event is detected.
      if LEvent.&type = SDL_EVENT_QUIT then
      begin
        LQuit := True;
        Break;
      end;
    end;

    // Clear the screen with a specified color.
    SDL_SetRenderDrawColor(LRenderer, 94, 93, 96, 255);
    SDL_RenderClear(LRenderer);

    // Calculate delta time (time between frames) for smooth animation.
    LNow := SDL_GetPerformanceCounter;
    LDeltaTime := (LNow - LLastFrameTime) / SDL_GetPerformanceFrequency;
    LLastFrameTime := LNow;

    // Update the skeleton animation based on delta time.
    spSkeletonDrawable_update(LDrawable, LDeltaTime, SP_PHYSICS_UPDATE);

    // Draw the updated skeleton on the renderer.
    spSkeletonDrawable_draw(LDrawable, LRenderer);

    // Present the rendered frame to the window.
    SDL_RenderPresent(LRenderer);
  end;

  // Cleanup: Dispose of Spine and SDL resources.
  spSkeletonDrawable_dispose(LDrawable);
  spAnimationStateData_dispose(LAnimationStateData);
  spSkeletonJson_dispose(LSkeletonJson);
  spAtlas_dispose(LAtlas);

  SDL_DestroyRenderer(LRenderer); // Destroy the renderer.
  SDL_DestroyWindow(LWindow);     // Destroy the window.
  SDL_Quit;                       // Quit SDL subsystem.
end;

/// <summary>
/// Demonstrates SDL window creation, text rendering, image loading, video playback,
/// and dynamic scaling using assets stored in a password-protected ZIP archive.
/// </summary>
/// <remarks>
/// This procedure initializes SDL, creates a resizable window with OpenGL rendering,
/// and loads fonts, images, and videos from a ZIP file. It handles scaling changes,
/// FPS rendering, and window events like fullscreen toggling and display scale adjustments.
/// </remarks>
procedure Test03();
const
  RES_WIDTH = 1920 div 2; // Logical resolution width (960 pixels).
  RES_HEIGHT = 1080 div 2; // Logical resolution height (540 pixels).

var
  LWindow, LWindow2: PSDL_Window;            // SDL window handles for primary and secondary windows.
  LRenderer: PSDL_Renderer;                  // SDL renderer used for all rendering operations.
  LEvent: SDL_Event;                         // Structure for handling input and system events.
  LRun: Boolean;                             // Flag to control the main event loop.
  LRect: SDL_FRect;                          // Rectangle structure for rendering shapes and textures.
  w, h, x, y: Integer;                       // Variables for window width, height, and position.
  LScale: single;                            // Scaling factor for display DPI.
  LDisplayMode: PSDL_DisplayMode;            // Current display mode for centering the window.
  LTextEngine: PTTF_TextEngine;              // Text engine for rendering TTF fonts.
  LFont: PTTF_Font;                          // Font resource loaded from a ZIP file.
  LText: PTTF_Text;                          // Text object used for rendering on the screen.
  LDpi: integer;                             // DPI (dots per inch) value for proper font scaling.
  LTexture: PSDL_Texture;                    // Texture object for rendering an image.
  LFontX, LFontY: Single;                    // Coordinates for positioning text on the screen.
  LVersion: string;                          // String to store SDL version information.
  tw,th: Single;
begin
  // Initialize SDL and check for success.
  if not SDL_InitEx() then Exit;
  try
    // Retrieve the SDL version and print it to the console.
    SDL_GetVersionEx(nil, nil, nil, @LVersion);
    writeln('SDL version: ', LVersion);

    // Create a resizable SDL window with the specified logical resolution.
    LWindow := SDL_CreateWindow('DSDL: Render fonts, video and image', RES_WIDTH, RES_HEIGHT, SDL_WINDOW_RESIZABLE);

    // Create an OpenGL-based SDL renderer for the window.
    LRenderer := SDL_CreateRenderer(LWindow, 'opengl');

    // Set up logical resolution scaling with letterbox presentation.
    SDL_SetRenderLogicalPresentation(LRenderer, RES_WIDTH, RES_HEIGHT, SDL_LOGICAL_PRESENTATION_LETTERBOX);

    // Calculate the display scale and DPI for the window.
    LScale := SDL_GetWindowDisplayScale(LWindow);
    LDpi := Round(LScale * 96.0);

    // Load the font from a ZIP archive and configure it for DPI-aware rendering.
    LFont := TTF_OpenFontIO(SDL_IOFromZipFile(CZipFilename, 'res/font/default.ttf'), True, 16);
    TTF_SetFontHinting(LFont, TTF_HINTING_LIGHT_SUBPIXEL);
    TTF_SetFontSizeDPI(LFont, 16, LDpi, LDpi);

    // Initialize a text engine for rendering TTF text.
    LTextEngine := TTF_CreateRendererTextEngine(LRenderer);

    // Create a text object for rendering text strings.
    LText := TTF_CreateText(LTextEngine, LFont, 'test', 0);
    TTF_SetTextColor(LText, 255, 255, 255, 255); // Set text color to white.

    // Load an image texture from the ZIP archive.
    LTexture := IMG_LoadTexture_IO(LRenderer, SDL_IOFromZipFile(CZipFilename, 'res/images/cute_kitten.jpg'), True);

    // Load and play a video file from the ZIP archive.
    SDL_LoadPlayVideoFromZipFile(LRenderer, CZipFilename, 'res/videos/sample01.mpg', 0.1, -1);

    // Reset SDL's timing system to synchronize updates.
    SDL_ResetTiming();
    LRun := True;

    // Main event loop.
    while LRun do
    begin
      Sleep(0); // Prevent the loop from consuming excessive CPU cycles.

      // Poll and handle all pending SDL events.
      while SDL_PollEvent(@LEvent) do
      begin
        case LEvent.&type of
          SDL_EVENT_QUIT:
          begin
            LRun := False; // Exit the loop on quit event.
          end;

          SDL_EVENT_KEY_UP:
          begin
            if LEvent.key.scancode = SDL_SCANCODE_F11 then
            begin
              SDL_ToggleWindowFullscreen(LWindow); // Toggle fullscreen mode when F11 is pressed.
            end;
          end;

          SDL_EVENT_WINDOW_DISPLAY_SCALE_CHANGED:
          begin
            // Adjust window scaling and reposition the window on scale changes.
            LWindow2 := SDL_GetWindowFromEvent(@LEvent);
            if Assigned(LWindow2) then
            begin
              LScale := SDL_GetWindowDisplayScale(LWindow2);
              SDL_GetRenderLogicalPresentation(LRenderer, @w, @h, nil);
              w := ceil(w * LScale);
              h := ceil(h * LScale);

              dec(w);
              dec(h);

              SDL_SetWindowSize(LWindow2, w, h);

              LDisplayMode := SDL_GetCurrentDisplayMode(SDL_GetDisplayForWindow(LWindow2));
              x := (LDisplayMode.w - w) div 2;
              y := (LDisplayMode.h - h) div 2;
              SDL_SetWindowPosition(LWindow2, x, y);
            end;
          end;
        end;
      end;

      // Update video playback timing.
      SDL_UpdateVideo(SDL_GetFramerateDuration());

      // Clear the screen with a dark background color.
      SDL_SetRenderDrawColor(LRenderer, 30, 30, 30, 255);
      SDL_RenderClear(LRenderer);

      // Render the video content.
      SDL_RenderVideo(LRenderer, 0, 0, 0.5);

      // Render a red rectangle on the screen.
      SDL_SetRenderDrawColor(LRenderer, 255, 0, 0, 255);
      LRect.x := 800-50;
      LRect.y := 0;
      LRect.w := 50;
      LRect.h := 50;
      SDL_RenderFillRect(LRenderer, @LRect);

      // Render the loaded image texture.
      LRect.x := 100;
      LRect.y := 100;
      LRect.w := 720;
      LRect.h := 156;
      LRect.w := 100;
      LRect.h := 100;
      SDL_RenderTexture(LRenderer, LTexture, nil, @LRect);

      // Render the FPS counter text.
      TTF_SetTextString(LText, SDL_FormatAsUTF8('%d fps', [SDL_GetFrameRate()]), 0);
      TTF_SetTextColor(LText, 255, 255, 255, 255);
      LFontX := 0;
      LFontY := 0;
      SDL_ScaleToPresentationCoordinates(LRenderer, LFontX, LFontY);
      SDL_SetRenderLogicalPresentation(LRenderer, RES_WIDTH, RES_HEIGHT, SDL_LOGICAL_PRESENTATION_DISABLED);
      TTF_DrawRendererText(LText, LFontX, LFontY);
      SDL_SetRenderLogicalPresentation(LRenderer, RES_WIDTH, RES_HEIGHT, SDL_LOGICAL_PRESENTATION_LETTERBOX);

      // Render static text.
      TTF_SetTextString(LText, SDL_FormatAsUTF8('SDL for Delphi ©™', []), 0);
      TTF_SetTextColor(LText, 255, 255, 255, 255);

      LFontX := 100;
      LFontY := 100;
      SDL_ScaleToPresentationCoordinates(LRenderer, LFontX, LFontY);

      SDL_SetRenderLogicalPresentation(LRenderer, RES_WIDTH, RES_HEIGHT, SDL_LOGICAL_PRESENTATION_DISABLED);
      TTF_DrawRendererText(LText, LFontX, LFontY);
      SDL_SetRenderLogicalPresentation(LRenderer, RES_WIDTH, RES_HEIGHT, SDL_LOGICAL_PRESENTATION_LETTERBOX);

      // Present the rendered content.
      SDL_RenderPresent(LRenderer);

      // Update SDL's timing system.
      SDL_UpdateTiming();
    end;

    // Unload the video and free all resources.
    SDL_UnloadVideo();
    SDL_DestroyTexture(LTexture);
    TTF_DestroyText(LText);
    TTF_DestroyRendererTextEngine(LTextEngine);
    TTF_CloseFont(LFont);
    SDL_DestroyRenderer(LRenderer);
    SDL_DestroyWindow(LWindow);
  finally
    SDL_QuitEx(); // Properly shut down SDL.
  end;
end;


/// <summary>
/// Callback function to create an SDL texture from a file within a ZIP archive.
/// </summary>
/// <param name="APath">The relative path of the file inside the ZIP archive.</param>
/// <param name="AUserData">Pointer to the SDL renderer used for creating the texture.</param>
/// <returns>Returns a pointer to the created SDL texture, or nil if creation fails.</returns>
/// <remarks>
/// This function utilizes `IMG_LoadTexture_IO` to load a texture from a ZIP file.
/// The ZIP file path is defined by `CZipFilename`.
/// </remarks>
function MyCreateTextureCallback(const APath: PAnsiChar; AUserData: Pointer): PSDL_Texture; cdecl;
var
  LRenderer: PSDL_Renderer; // Renderer passed as user data.
  LFilename: string;        // Path to the file inside the ZIP archive.
begin
  Result := nil;

  // Exit if AUserData (renderer) is not provided.
  if not Assigned(AUserData) then Exit;

  // Exit if APath (file path) is not provided.
  if not Assigned(APath) then Exit;

  // Cast AUserData to the renderer.
  LRenderer := PSDL_Renderer(AUserData);

  // Convert the provided path to a Delphi string.
  LFilename := string(APath);

  // Attempt to load the texture from the ZIP file using the renderer.
  Result := IMG_LoadTexture_IO(LRenderer, SDL_IOFromZipFile(CZipFilename, LFilename), True);
end;

/// <summary>
/// Callback function to dispose of an SDL texture.
/// </summary>
/// <param name="ATexture">Pointer to the SDL texture to be destroyed.</param>
/// <param name="AUserData">Optional user data (unused in this function).</param>
/// <remarks>
/// This function calls `SDL_DestroyTexture` to release the texture memory.
/// </remarks>
procedure MyDisposeTextureCallback(ATexture: PSDL_Texture; AUserData: Pointer); cdecl;
begin
  // Exit if the texture pointer is not valid.
  if not Assigned(ATexture) then Exit;

  // Destroy the texture to free its resources.
  SDL_DestroyTexture(ATexture);
end;


/// <summary>
/// Demonstrates rendering a Spine animation using SDL and the Spine runtime integration.
/// The spine animation is loaded from a zipfile.
/// </summary>
/// <remarks>
/// This procedure initializes an SDL window and renderer, loads Spine animation assets,
/// and plays the 'portal' and 'run' animations in a loop until the user closes the window.
/// It handles SDL event polling, frame timing, and resource cleanup.
/// </remarks>
procedure Test04();
var
  LWindow: PSDL_Window;                  // Pointer to the SDL window.
  LRenderer: PSDL_Renderer;              // Pointer to the SDL renderer.
  LAtlas: PspAtlas;                      // Atlas for Spine animation textures.
  LSkeletonJson: PspSkeletonJson;        // JSON parser for Spine skeleton data.
  LSkeletonData: PspSkeletonData;        // Spine skeleton data.
  LAnimationStateData: PspAnimationStateData; // State data for animation transitions.
  LDrawable: PspSkeletonDrawable;        // Drawable object for the Spine skeleton.
  LEvent: SDL_Event;                     // Event structure for SDL event handling.
  LQuit: Boolean;                        // Flag to control the main loop.
  LLastFrameTime, LNow: UInt64;          // Variables for frame timing.
  LDeltaTime: Double;                    // Time elapsed between frames.
  LData: Pointer;
  LDataSize: NativeUInt;
begin
  // Initialize SDL video subsystem.
  if not SDL_Init(SDL_INIT_VIDEO) then
  begin
    Writeln('Error: ', SDL_GetError); // Print SDL initialization error.
    Exit; // Exit if initialization fails.
  end;

  // Create an SDL window with the specified title and size.
  LWindow := SDL_CreateWindow('DSDL: Load spine animation from zipfile', 800, 600, 0);
  if LWindow = nil then
  begin
    Writeln('Error: ', SDL_GetError); // Print window creation error.
    SDL_Quit; // Clean up SDL resources.
    Exit;
  end;

  // Create an SDL renderer for the window with OpenGL backend.
  LRenderer := SDL_CreateRenderer(LWindow, 'opengl');
  if LRenderer = nil then
  begin
    Writeln('Error: ', SDL_GetError); // Print renderer creation error.
    SDL_DestroyWindow(LWindow);       // Destroy the created window.
    SDL_Quit;                         // Clean up SDL resources.
    Exit;
  end;

  // Load the Spine animation atlas from inside zipfile.
  spAtlasPage_setCallbacks(MyCreateTextureCallback, MyDisposeTextureCallback, LRenderer);
  LData := SDL_LoadFile_IO(SDL_IOFromZipFile(CZipFilename, 'res/spine/spineboy/spineboy-pma.atlas'), @LDataSize, True);
  LAtlas := spAtlas_Create(LData, LDataSize, 'res/spine/spineboy/', LRenderer);
  SDL_Free(LData);

  // Create a skeleton JSON parser and scale the skeleton.
  LSkeletonJson := spSkeletonJson_create(LAtlas);
  LSkeletonJson.scale := 0.5;

  // Read skeleton data from the JSON file from insize zipfile.
  LData := SDL_LoadFile_IO(SDL_IOFromZipFile(CZipFilename, 'res/spine/spineboy/spineboy-pro.json'), @LDataSize, True);
  LSkeletonData := spSkeletonJson_readSkeletonData(LSkeletonJson, LData);
  SDL_Free(LData);

  // Create animation state data and set default transition mix.
  LAnimationStateData := spAnimationStateData_create(LSkeletonData);
  LAnimationStateData.defaultMix := 0.2;

  // Create a drawable skeleton object and set its initial position.
  LDrawable := spSkeletonDrawable_create(LSkeletonData, LAnimationStateData);
  LDrawable.usePremultipliedAlpha := -1; // Enable premultiplied alpha.
  LDrawable.skeleton^.x := 400;         // Set X position.
  LDrawable.skeleton^.y := 500;         // Set Y position.

  // Set the skeleton to its setup pose.
  spSkeleton_setToSetupPose(LDrawable.skeleton);

  // Perform an initial skeleton update.
  spSkeletonDrawable_update(LDrawable, 0, SP_PHYSICS_UPDATE);

  // Set initial animation state: 'portal' followed by 'run' (looped).
  spAnimationState_setAnimationByName(LDrawable.animationState, 0, 'portal', 0);
  spAnimationState_addAnimationByName(LDrawable.animationState, 0, 'run', -1, 0);

  // Initialize the quit flag and timing variables.
  LQuit := False;
  LLastFrameTime := SDL_GetPerformanceCounter;

  // Main event loop.
  while not LQuit do
  begin
    // Poll SDL events.
    while SDL_PollEvent(@LEvent) do
    begin
      // Exit the loop if a quit event is detected.
      if LEvent.&type = SDL_EVENT_QUIT then
      begin
        LQuit := True;
        Break;
      end;
    end;

    // Clear the screen with a specified color.
    SDL_SetRenderDrawColor(LRenderer, 94, 93, 96, 255);
    SDL_RenderClear(LRenderer);

    // Calculate delta time (time between frames) for smooth animation.
    LNow := SDL_GetPerformanceCounter;
    LDeltaTime := (LNow - LLastFrameTime) / SDL_GetPerformanceFrequency;
    LLastFrameTime := LNow;

    // Update the skeleton animation based on delta time.
    spSkeletonDrawable_update(LDrawable, LDeltaTime, SP_PHYSICS_UPDATE);

    // Draw the updated skeleton on the renderer.
    spSkeletonDrawable_draw(LDrawable, LRenderer);

    // Present the rendered frame to the window.
    SDL_RenderPresent(LRenderer);
  end;

  // Cleanup: Dispose of Spine and SDL resources.
  spSkeletonDrawable_dispose(LDrawable);
  spAnimationStateData_dispose(LAnimationStateData);
  spSkeletonJson_dispose(LSkeletonJson);
  spAtlas_dispose(LAtlas);

  SDL_DestroyRenderer(LRenderer); // Destroy the renderer.
  SDL_DestroyWindow(LWindow);     // Destroy the window.
  SDL_Quit;                       // Quit SDL subsystem.
end;

/// <summary>
/// Executes one of the predefined test procedures (Test01, Test02, or Test03) based on a selected value.
/// </summary>
/// <remarks>
/// This routine demonstrates the ability to choose between different tests using a `case` statement.
/// It currently defaults to executing Test03.
/// </remarks>
procedure RunTests();
var
  LNum: Integer; // Variable to hold the selected test number.
begin
  LNum := 01; // Set the test number, make sure to run #01 first to create zipfile needed by other examples

  case LNum of
    01: Test01(); // Build zipfile used by the examples
    02: Test02(); // Load spine animation from file
    03: Test03(); // Render font, video and image
    04: Test04(); // Load spine animation from zipfile
  end;

  Pause(); // Pause execution to allow viewing of results before the program exits.
end;


end.
