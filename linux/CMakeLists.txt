# The Flutter tooling requires that developers have CMake 3.10 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.10)

# Project-level configuration.
project(qinhuai)

# Invoke the build for native code.
add_custom_target(qinhuai
  ALL
  WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/../native/
  # COMMAND rustup target add x86_64-unknown-linux-gnu i686-unknown-linux-gnu aarch64-unknown-linux-gnu
  # COMMAND cargo build --target-dir ${CMAKE_CURRENT_BINARY_DIR}/native/ --target x86_64-unknown-linux-gnu --release
  # COMMAND cargo build --target-dir ${CMAKE_CURRENT_BINARY_DIR}/native/ --target i686-unknown-linux-gnu --release
  # COMMAND cargo build --target-dir ${CMAKE_CURRENT_BINARY_DIR}/native/ --target aarch64-unknown-linux-gnu --release
  COMMAND cargo build --target-dir ${CMAKE_CURRENT_BINARY_DIR}/native/ --release
)

# List of absolute paths to libraries that should be bundled with the plugin.
set(qinhuai_bundled_libraries
  ${CMAKE_CURRENT_BINARY_DIR}/native/release/libqinhuai.so
  PARENT_SCOPE
)
