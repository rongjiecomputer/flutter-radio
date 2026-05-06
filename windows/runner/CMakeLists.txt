cmake_minimum_required(VERSION 3.14)
project(runner LANGUAGES CXX)

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# ---------------------------------------------------------------------------
# Backend selection
# Build with -DUSE_BASS_BACKEND=ON to use the BASS audio library instead of
# the default Windows Media Foundation backend.
#
# BASS library layout expected under windows/third_party/bass/:
#   bass.h      - public API header
#   bass.lib    - import library (x64)
#   bass.dll    - runtime DLL (will be copied next to the executable)
# ---------------------------------------------------------------------------
option(USE_BASS_BACKEND "Use BASS audio library instead of Windows Media Foundation" OFF)

# Define the application target. To change its name, change BINARY_NAME in the
# top-level CMakeLists.txt, not the value here, or `flutter run` will no longer
# work.
#
# Any new source files that you add to the application should be added here.
if(USE_BASS_BACKEND)
  set(RADIO_PLAYER_SRC "radio_player_bass.cpp")
else()
  set(RADIO_PLAYER_SRC "radio_player.cpp")
endif()

add_executable(${BINARY_NAME} WIN32
  "flutter_window.cpp"
  "main.cpp"
  "utils.cpp"
  "win32_window.cpp"
  ${RADIO_PLAYER_SRC}
  "${FLUTTER_MANAGED_DIR}/generated_plugin_registrant.cc"
  "Runner.rc"
  "runner.exe.manifest"
)

# Apply the standard set of build settings. This can be removed for applications
# that need different build settings.
apply_standard_settings(${BINARY_NAME})

# Add preprocessor definitions for the build version.
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION=\"${FLUTTER_VERSION}\"")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_MAJOR=${FLUTTER_VERSION_MAJOR}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_MINOR=${FLUTTER_VERSION_MINOR}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_PATCH=${FLUTTER_VERSION_PATCH}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_BUILD=${FLUTTER_VERSION_BUILD}")

# Disable Windows macros that collide with C++ standard library functions.
target_compile_definitions(${BINARY_NAME} PRIVATE "NOMINMAX")

# Add dependency libraries and include directories. Add any application-specific
# dependencies here.
target_link_libraries(${BINARY_NAME} PRIVATE flutter flutter_wrapper_app)
target_link_libraries(${BINARY_NAME} PRIVATE "dwmapi.lib")
target_include_directories(${BINARY_NAME} PRIVATE "${CMAKE_SOURCE_DIR}")

# ---------------------------------------------------------------------------
# Backend-specific configuration
# ---------------------------------------------------------------------------
if(USE_BASS_BACKEND)
  # Propagate the macro so radio_player.h selects the right private members.
  target_compile_definitions(${BINARY_NAME} PRIVATE "USE_BASS_BACKEND")

  set(BASS_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../third_party/bass")

  # Validate that the BASS directory and required files exist.
  if(NOT EXISTS "${BASS_DIR}/bass.h")
    message(FATAL_ERROR
      "BASS header not found at ${BASS_DIR}/bass.h\n"
      "Download BASS from https://www.un4seen.com/bass.html and place the "
      "extracted files under windows/third_party/bass/")
  endif()

  target_include_directories(${BINARY_NAME} PRIVATE "${BASS_DIR}")
  target_link_libraries(${BINARY_NAME} PRIVATE "${BASS_DIR}/bass.lib")

  # Copy bass.dll next to the built executable so it can be found at runtime.
  add_custom_command(TARGET ${BINARY_NAME} POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
      "${BASS_DIR}/bass.dll"
      "$<TARGET_FILE_DIR:${BINARY_NAME}>/bass.dll"
    COMMENT "Copying bass.dll to output directory"
  )
else()
  # Windows Media Foundation libs are already linked via #pragma comment in
  # radio_player.cpp, but we add them explicitly here for clarity.
  target_link_libraries(${BINARY_NAME} PRIVATE
    "mf.lib"
    "mfplat.lib"
    "mfuuid.lib"
    "shlwapi.lib"
  )
endif()

# Run the Flutter tool portions of the build. This must not be removed.
add_dependencies(${BINARY_NAME} flutter_assemble)
