# The Flutter tooling requires that developers have a version of Visual Studio
# installed that includes CMake 3.14 or later. You should not increase this
# version, as doing so will cause the plugin to fail to compile for some
# customers of the plugin.
cmake_minimum_required(VERSION 3.14)

# Project-level configuration.
project(beacons)

# Invoke the build for native code.
add_custom_target(beacons
  ALL
  WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/../native/
  # COMMAND rustup target add x86_64-pc-windows-msvc i686-pc-windows-msvc aarch64-pc-windows-msvc
  # COMMAND cargo build --target-dir ${CMAKE_CURRENT_BINARY_DIR}/native/ --target x86_64-pc-windows-msvc --release
  # COMMAND cargo build --target-dir ${CMAKE_CURRENT_BINARY_DIR}/native/ --target i686-pc-windows-msvc --release
  # COMMAND cargo build --target-dir ${CMAKE_CURRENT_BINARY_DIR}/native/ --target aarch64-pc-windows-msvc --release
  COMMAND cargo build --target-dir ${CMAKE_CURRENT_BINARY_DIR}/native/ --release
)

# List of absolute paths to libraries that should be bundled with the plugin.
set(beacons_bundled_libraries
  ${CMAKE_CURRENT_BINARY_DIR}/native/release/beacons.dll
  PARENT_SCOPE
)
