# cpp-journey

make init

```
# Должно быть:
# 🔧 Инициализация проекта...
#   → Генерация CMake...
#   → Сборка compile_commands.json...
# 🔗 Создан симлинк: compile_commands.json → build/compile_commands.json
# ✅ Проект инициализирован. Готов к разработке.
```

ls -la compile_commands.json

```
# lrwxr-xr-x  1 user  staff  30 Nov 18 21:00 compile_commands.json -> build/compile_commands.json
```

```
# Проверь содержимое (должны быть команды для day1_raii)
jq '.[0].file' compile_commands.json
# "src/day1_raii/main.cpp"
```

# Сценарий полной инициализации

```sh
# 1. Очисти, если что-то было
make clean

# 2. Инициализируй
make init

# 3. Собери всё (на всякий)
make build

# 4. Запусти первую цель
make day1_raii

# 5. Проверь утечки
make leaks
```

