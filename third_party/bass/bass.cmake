# BASS Audio Library Import
add_library(bass SHARED IMPORTED)

set_target_properties(bass PROPERTIES
    INTERFACE_INCLUDE_DIRECTORIES "${CMAKE_CURRENT_LIST_DIR}"
)

if(WIN32)
    set_target_properties(bass PROPERTIES
        IMPORTED_IMPLIB "${CMAKE_CURRENT_LIST_DIR}/bass.lib"
        IMPORTED_LOCATION "${CMAKE_CURRENT_LIST_DIR}/bass.dll"
    )
elseif(APPLE)
    set_target_properties(bass PROPERTIES
        IMPORTED_LOCATION "${CMAKE_CURRENT_LIST_DIR}/libbass.dylib"
    )
else()
    set_target_properties(bass PROPERTIES
        IMPORTED_LOCATION "${CMAKE_CURRENT_LIST_DIR}/libbass.so"
    )
endif()

add_library(BASS::BASS ALIAS bass)
