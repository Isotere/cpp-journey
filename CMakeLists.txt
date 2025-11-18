cmake_minimum_required(VERSION 4.1)

# 🔴 УБРАТЬ: этот блок НЕ ДОЛЖЕН быть до project()!
# ❌ НЕЛЬЗЯ вызывать execute_process до project() — CMAKE_CXX_COMPILER_ID ещё неизвестен!
# ✅ Переносим определение SDK ПОСЛЕ project() и задания компилятора.

project(cpp_journey LANGUAGES CXX)

# === Настройка компилятора ===
if(CMAKE_CXX_COMPILER STREQUAL "CMAKE_CXX_COMPILER-NOTFOUND" OR
        CMAKE_CXX_COMPILER MATCHES "apple.*clang")
    find_program(CLANGPP clang++ REQUIRED PATHS /opt/homebrew/bin /usr/bin)
    set(CMAKE_CXX_COMPILER ${CLANGPP})
endif()

# Единая директория для бинарников
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)

# === Определяем SDK ТОЛЬКО ПОСЛЕ project() и компилятора ===
if(APPLE)
    # CMake ≥ 3.15+ автоматически вызывает xcrun при установке CMAKE_OSX_SYSROOT=""
    # Но мы сделаем явно — для надёжности
    if(NOT CMAKE_OSX_SYSROOT)
        execute_process(
                COMMAND xcrun --show-sdk-path
                OUTPUT_VARIABLE SDK_PATH
                OUTPUT_STRIP_TRAILING_WHITESPACE
                ERROR_QUIET
        )
        if(NOT SDK_PATH)
            message(FATAL_ERROR "❌ Не найден macOS SDK. Выполни: xcode-select --install")
        endif()
        set(CMAKE_OSX_SYSROOT "${SDK_PATH}" CACHE STRING "" FORCE)
        message(STATUS "✅ Используется macOS SDK: ${SDK_PATH}")
    endif()

    set(CMAKE_OSX_ARCHITECTURES "arm64")
endif()

# === Стандарт и флаги ===
set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# === Флаги компиляции ===
if(CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
    # Базовые флаги — через add_compile_options (НЕ через CMAKE_CXX_FLAGS!)
    add_compile_options(
            -Wall -Wextra -Wpedantic -Werror
            -Wshadow -Wnon-virtual-dtor -Wold-style-cast
            -Wcast-align -Wunused -Woverloaded-virtual
            -Wnull-dereference -Wdouble-promotion -Wformat=2
            -march=armv8.4-a+fp16+simd+crc+crypto
    )

    if(APPLE)
        # -stdlib=libc++ — ОБЯЗАТЕЛЬНО для Homebrew Clang!
        add_compile_options(-stdlib=libc++)
        add_link_options(-stdlib=libc++)

        # Debug + sanitizers требуют -O1 на macOS
        add_compile_options($<$<CONFIG:Debug>:-O1>)
    endif()

    # Санитайзеры
    option(ENABLE_ASAN "Enable AddressSanitizer" OFF)
    option(ENABLE_UBSAN "Enable UndefinedBehaviorSanitizer" OFF)

    if(ENABLE_ASAN)
        add_compile_options(-fsanitize=address -fno-omit-frame-pointer)
        add_link_options(-fsanitize=address)
    endif()
    if(ENABLE_UBSAN)
        add_compile_options(-fsanitize=undefined -fno-omit-frame-pointer)
        add_link_options(-fsanitize=undefined)
    endif()
endif()

# === Остальное без изменений ===
set(BUILD_TARGET "" CACHE STRING "Target to build (e.g. day1_raii)")
include_directories(libs)
include(FetchContent)

if(BUILD_TARGET AND EXISTS "${CMAKE_SOURCE_DIR}/src/${BUILD_TARGET}/CMakeLists.txt")
    add_subdirectory("src/${BUILD_TARGET}")
else()
    file(GLOB TARGET_DIRS RELATIVE ${CMAKE_SOURCE_DIR}/src ${CMAKE_SOURCE_DIR}/src/*)
    foreach(dir ${TARGET_DIRS})
        if(IS_DIRECTORY "${CMAKE_SOURCE_DIR}/src/${dir}" AND EXISTS "${CMAKE_SOURCE_DIR}/src/${dir}/CMakeLists.txt")
            add_subdirectory("src/${dir}")
        endif()
    endforeach()
endif()