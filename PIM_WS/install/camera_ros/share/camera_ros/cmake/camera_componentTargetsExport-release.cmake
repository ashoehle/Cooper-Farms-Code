#----------------------------------------------------------------
# Generated CMake target import file for configuration "Release".
#----------------------------------------------------------------

# Commands may need to know the format version.
set(CMAKE_IMPORT_FILE_VERSION 1)

# Import target "camera_ros::camera_component" for configuration "Release"
set_property(TARGET camera_ros::camera_component APPEND PROPERTY IMPORTED_CONFIGURATIONS RELEASE)
set_target_properties(camera_ros::camera_component PROPERTIES
  IMPORTED_LOCATION_RELEASE "${_IMPORT_PREFIX}/lib/libcamera_component.so"
  IMPORTED_SONAME_RELEASE "libcamera_component.so"
  )

list(APPEND _cmake_import_check_targets camera_ros::camera_component )
list(APPEND _cmake_import_check_files_for_camera_ros::camera_component "${_IMPORT_PREFIX}/lib/libcamera_component.so" )

# Commands beyond this point should not need to know the version.
set(CMAKE_IMPORT_FILE_VERSION)
