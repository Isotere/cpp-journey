# ============================================================================
# 🛠  cpp-journey/Makefile — расширенная версия
# Поддержка: init, compile_commands.json, сборка всего проекта
# ============================================================================
SHELL := /bin/bash
BUILD_DIR := build
SRC_DIR := src
COMPILE_COMMANDS := compile_commands.json

# Настройки по умолчанию
TARGET ?= day1_raii
BUILD_TYPE ?= Debug
ASAN ?= ON
UBSAN ?= ON
CXX := /opt/homebrew/opt/llvm/bin/clang++

# Команда CMake для полной сборки (все цели)
CMAKE_ALL = \
	cmake -S . -B $(BUILD_DIR) \
		-G Ninja \
		-DCMAKE_BUILD_TYPE=$(BUILD_TYPE) \
		-DCMAKE_CXX_COMPILER=$(CXX) \
		-DENABLE_ASAN=$(ASAN) \
		-DENABLE_UBSAN=$(UBSAN)

# Команда CMake для одной цели
CMAKE_TARGET = $(CMAKE_ALL) -DBUILD_TARGET=$(TARGET)

# Проверка существования цели
TARGET_EXISTS = $(shell [ -d "$(SRC_DIR)/$(TARGET)" -a -f "$(SRC_DIR)/$(TARGET)/CMakeLists.txt" ] && echo 1 || echo 0)

.PHONY: all help setup init build rebuild clean clean-target leaks new link-cc

# ------------------------------------------------------------------------
# 🎯 Основные цели
# ------------------------------------------------------------------------

all: help

# ------------------------------------------------------------------------
# 🚀 Инициализация проекта: make init
# ------------------------------------------------------------------------
init:
	@echo "🔧 Инициализация проекта..."
	@mkdir -p $(BUILD_DIR)
	@echo "  → Генерация CMake..."
	@$(CMAKE_ALL) >/dev/null
	@echo "  → Сборка compile_commands.json..."
	@cmake --build $(BUILD_DIR) --target help >/dev/null 2>&1 || true
	@$(MAKE) link-cc
	@echo "✅ Проект инициализирован. Готов к разработке."
	@echo "💡 Совет: используй 'make day1_raii' или 'make build'"

# Симлинк compile_commands.json в корень (если ещё не создан)
link-cc:
	@if [ ! -L $(COMPILE_COMMANDS) ] && [ -f $(BUILD_DIR)/$(COMPILE_COMMANDS) ]; then \
		ln -sfv $(BUILD_DIR)/$(COMPILE_COMMANDS) ./ ; \
		echo "🔗 Создан симлинк: $(COMPILE_COMMANDS) → $(BUILD_DIR)/$(COMPILE_COMMANDS)"; \
	elif [ -f $(BUILD_DIR)/$(COMPILE_COMMANDS) ]; then \
		echo "✅ $(COMPILE_COMMANDS) уже доступен в корне"; \
	else \
		echo "⚠️  $(COMPILE_COMMANDS) ещё не сгенерирован (выполни 'make init' или 'make build')"; \
	fi

# ------------------------------------------------------------------------
# 🏗 Сборка ВСЕГО проекта
# ------------------------------------------------------------------------
build:
	@echo "📦 Сборка ВСЕХ целей..."
	@$(CMAKE_ALL) >/dev/null
	@cmake --build $(BUILD_DIR) -- -j$(shell sysctl -n hw.logicalcpu 2>/dev/null || nproc)
	@$(MAKE) link-cc

rebuild: clean build

# ------------------------------------------------------------------------
# 🎯 Сборка ОДНОЙ цели
# ------------------------------------------------------------------------
$(TARGET):
ifeq ($(TARGET_EXISTS),0)
	$(error ❌ Цель '$(TARGET)' не найдена. Проверь: $(SRC_DIR)/$(TARGET)/)
endif
	@echo "🔧 Собираю $(TARGET)..."
	@$(CMAKE_TARGET) >/dev/null
	@cmake --build $(BUILD_DIR) --target $(TARGET) -- -j$(shell sysctl -n hw.logicalcpu 2>/dev/null || nproc)
	@$(MAKE) link-cc
	@echo "✅ $(TARGET) собран. Запуск:"
	@./$(BUILD_DIR)/bin/$(TARGET)

rebuild-target: clean-target $(TARGET)

# ------------------------------------------------------------------------
# 🧹 Очистка
# ------------------------------------------------------------------------
clean:
	@echo "🧹 Полная очистка build/"
	@rm -rf $(BUILD_DIR)
	@rm -f $(COMPILE_COMMANDS)

clean-target:
	@mkdir -p $(BUILD_DIR)
	@$(CMAKE_TARGET) >/dev/null
	@cmake --build $(BUILD_DIR) --target clean -- $(TARGET) 2>/dev/null || true
	@rm -f $(BUILD_DIR)/$(TARGET)

# ------------------------------------------------------------------------
# 🔍 Анализ (macOS)
# ------------------------------------------------------------------------
leaks: $(TARGET)
	@echo "🔍 Проверка утечек через leaks (macOS)..."
	@leaks --atExit -- $(BUILD_DIR)/$(TARGET) || true

# ------------------------------------------------------------------------
# 🛠 Вспомогательные
# ------------------------------------------------------------------------
setup:
	@echo "⚙️ Проверка зависимостей..."
	@which cmake &>/dev/null || { echo "❌ cmake не установлен. Выполни: brew install cmake"; exit 1; }
	@which ninja &>/dev/null || { echo "❌ ninja не установлен. Выполни: brew install ninja"; exit 1; }
	@which $(CXX) &>/dev/null || { echo "❌ clang++ не найден по $(CXX). Установи: brew install llvm"; exit 1; }
	@echo "✅ Все зависимости на месте."

new:
ifeq ($(TARGET),)
	$(error ❌ Укажи TARGET=name)
endif
	@mkdir -p $(SRC_DIR)/$(TARGET)
	@echo '#include <iostream>\n\nint main() {\n    std::cout << "Hello from $(TARGET)\\n";\n    return 0;\n}' > $(SRC_DIR)/$(TARGET)/main.cpp
	@echo 'add_executable($(TARGET) main.cpp)' > $(SRC_DIR)/$(TARGET)/CMakeLists.txt
	@echo "✅ Шаблон создан: $(SRC_DIR)/$(TARGET)/"

help:
	@echo "/cpp-journey Makefile (Clang 21.1.5 + CMake 4.1.2)"
	@echo
	@echo "🚀 Быстрый старт:"
	@echo "  make init             → инициализация + compile_commands.json"
	@echo "  make                  → собрать/запустить day1_raii"
	@echo "  make build            → собрать ВСЁ"
	@echo
	@echo "🎯 Целевые команды:"
	@echo "  make [TARGET]         → собрать и запустить цель"
	@echo "  make rebuild          → пересобрать всё"
	@echo "  make rebuild-target   → пересобрать одну цель"
	@echo "  make leaks            → проверить утечки (macOS)"
	@echo "  make clean            → удалить build/ и compile_commands.json"
	@echo
	@echo "🔧 Разработка:"
	@echo "  make new TARGET=name  → создать шаблон новой цели"
	@echo "  make setup            → проверить зависимости"
	@echo
	@echo "⚙️  Переменные (примеры):"
	@echo "  TARGET=day2_stl       → выбрать цель"
	@echo "  ASAN=OFF              → отключить AddressSanitizer"
	@echo "  BUILD_TYPE=Release    → сборка под продакшен"
	@echo
	@echo "💡 compile_commands.json автоматически создаётся в корне при сборке."