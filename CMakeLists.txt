cmake_minimum_required(VERSION 2.8.11)
set(CMAKE_OSX_DEPLOYMENT_TARGET "10.9" CACHE STRING "Minimum OS X deployment version")

project(radiance)

set(APP_NAME Radiance)
set(LIB_NAME radiance)
set(EXE_NAME radiance)

set(CMAKE_INCLUDE_CURRENT_DIR ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_SOURCE_DIR}/cmake/")
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -std=c99 -Wall -Werror")
set(CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG} -g -O2 -ffast-math -march=native")
set(CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS_RELEASE} -O2 -ffast-math -march=native")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -Werror")
set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} -ggdb3 -O2 -ffast-math -march=native")
set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} -O2 -ffast-math -march=native")
set(CMAKE_CXX_STANDARD 14)
set(OpenGL_GL_PREFERENCE GLVND)
set(RADIANCE_SYSTEM_RESOURCES "${CMAKE_SOURCE_DIR}/resources/" CACHE STRING "The path where Radiance looks for its resources")

include(Doxygen)
include_directories(BTrack/src)

find_package(Qt5Core REQUIRED)
find_package(Qt5Widgets REQUIRED)
find_package(Qt5Quick REQUIRED)
find_package(Qt5Qml REQUIRED)
find_package(Qt5Gui REQUIRED)
find_package(Qt5Multimedia REQUIRED)
find_package(FFTW REQUIRED)
find_package(SampleRate REQUIRED)
find_package(OpenGL REQUIRED)
find_package(RtMidi)
find_package(MPV)

set(libradiance_SOURCES)
list(APPEND libradiance_SOURCES
    src/Audio.cpp
    src/BaseVideoNodeTile.cpp
    src/Chain.cpp
    src/Context.cpp
    src/Controls.cpp
    src/ConsoleOutputNode.cpp
    src/EffectNode.cpp
    src/FFmpegOutputNode.cpp
    src/FramebufferVideoNodeRender.cpp
    src/GraphicalDisplay.cpp
    src/ImageNode.cpp
    src/Library.cpp
    src/LightOutputNode.cpp
    src/Model.cpp
    src/OpenGLUtils.cpp
    src/OpenGLWorker.cpp
    src/OpenGLWorkerContext.cpp
    src/OutputNode.cpp
    src/OutputWindow.cpp
    src/Paths.cpp
    src/PlaceholderNode.cpp
    src/Registry.cpp
    src/ScreenOutputNode.cpp
    src/SelfTimedReadBackOutputNode.cpp
    src/Timebase.cpp
    src/VideoNode.cpp
    src/View.cpp
    BTrack/src/BTrack.c
    BTrack/src/OnsetDetectionFunction.c
    )

set(radiance_LIBRARIES)
list(APPEND radiance_LIBRARIES
    Qt5::Widgets
    Qt5::Quick
    Qt5::Qml
    Qt5::Gui
    Qt5::Multimedia
    ${FFTW_LIBRARIES}
    ${SAMPLERATE_LIBRARIES}
    ${OPENGL_LIBRARIES}
    )

set_property(
  SOURCE src/Paths.cpp
  PROPERTY COMPILE_DEFINITIONS
    RADIANCE_SYSTEM_RESOURCES=\"${RADIANCE_SYSTEM_RESOURCES}\"
)

include_directories(${FFTW_INCLUDE_DIRS})
include_directories(${SAMPLERATE_INCLUDE_DIRS})

if(RtMidi_FOUND AND NOT WITHOUT_RTMIDI)
    add_definitions( -DUSE_RTMIDI )
    include_directories(${RTMIDI_INCLUDE_DIRS})
    list(APPEND libradiance_SOURCES src/MidiController.cpp)
    list(APPEND radiance_LIBRARIES ${RTMIDI_LIBRARIES})
endif()

if(MPV_FOUND AND NOT WITHOUT_MPV)
    add_definitions( -DUSE_MPV )
    include_directories(${MPV_INCLUDE_DIRS})
    list(APPEND libradiance_SOURCES src/MovieNode.cpp)
    list(APPEND radiance_LIBRARIES ${MPV_LIBRARY})
endif()

# lux uses epoll, which is not supported on MacOS
if(NOT APPLE AND NOT WITHOUT_LUX)
    add_definitions( -DUSE_LUX )
    list(APPEND libradiance_SOURCES src/liblux/lux.c
                                    src/liblux/crc.c
                                    src/Lux.cpp
    )
endif()

add_library(libradiance ${libradiance_SOURCES})

add_executable(radiance WIN32 src/main.cpp
    src/GlslDocument.cpp
    src/GlslHighlighter.cpp
    src/QQuickVideoNodePreview.cpp
    src/QQuickPreviewAdapter.cpp
    src/QQuickLightOutputPreview.cpp)

set_target_properties(radiance PROPERTIES OUTPUT_NAME ${EXE_NAME})
set_target_properties(libradiance PROPERTIES OUTPUT_NAME ${LIB_NAME})
set_target_properties(radiance PROPERTIES MACOSX_BUNDLE_INFO_PLIST "${CMAKE_SOURCE_DIR}/deploy/Info.plist.in")

target_link_libraries(libradiance ${radiance_LIBRARIES})
target_link_libraries(radiance libradiance ${radiance_LIBRARIES})

install(CODE "
    if(NOT \"${RADIANCE_SYSTEM_RESOURCES}\" STREQUAL \"${CMAKE_INSTALL_PREFIX}/share/${PROJECT_NAME}/\")
        MESSAGE(\"For an install to work, RADIANCE_SYSTEM_RESOURCES must be set to '\\\${CMAKE_INSTALL_PREFIX}share/${PROJECT_NAME}/'\")
        MESSAGE(\"If your install doesn't work, recompile with cmake -DRADIANCE_SYSTEM_RESOURCES=${CMAKE_INSTALL_PREFIX}/share/${PROJECT_NAME}/\")
    endif()
")

INSTALL(TARGETS radiance
        DESTINATION bin
)

INSTALL(DIRECTORY "${CMAKE_SOURCE_DIR}/resources/"
        DESTINATION
        "share/${PROJECT_NAME}"
)

IF(APPLE)
    ADD_CUSTOM_TARGET(bundle
        "${CMAKE_SOURCE_DIR}/deploy/mac.sh"
        "${CMAKE_SOURCE_DIR}"
        "${CMAKE_BINARY_DIR}/${EXE_NAME}"
        "${CMAKE_BINARY_DIR}/Radiance.app"
        "${CMAKE_BINARY_DIR}/Radiance.dmg"
        "${Qt5Core_DIR}/../../.."
        "${RADIANCE_SYSTEM_RESOURCES}"
        DEPENDS radiance
    )
ELSEIF(UNIX)
    ADD_CUSTOM_TARGET(bundle
        "${CMAKE_SOURCE_DIR}/deploy/linux.sh"
        "${CMAKE_SOURCE_DIR}"
        "${CMAKE_BINARY_DIR}/${EXE_NAME}"
        "${CMAKE_BINARY_DIR}/Radiance.AppDir"
        "${CMAKE_BINARY_DIR}/Radiance.AppDir.tar.gz"
        "${Qt5Core_DIR}/../../.."
        "${RADIANCE_SYSTEM_RESOURCES}"
        DEPENDS radiance
    )
ENDIF()

# make package
#set(CPACK_BINARY_DRAGNDROP ON)
#include(CPack)
