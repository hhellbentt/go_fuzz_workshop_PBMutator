# Тренировочный стенд: фаззинг `gjson` со встроенным фаззером Go

Стенд знакомит с coverage-guided фаззингом Go-кода на примере функции `gjson.Parse`.

- команды сборки и запуска выполняются из корня
- команды фаззинга выполняются внутри контейнера из /go/src/gjson-1.18.0

## 1. Сборка образа

```bash
docker build --tag=gjson_workshop_img .
```

- `--tag` задаёт имя
- `.` передаёт текущий каталог как точку сборки

## 2. Запуск контейнера

```bash
docker run -it -v "$(pwd)/artifacts:/home/fuzz/artifacts:ro" --name=gjson_fuzz gjson_workshop_img
```

- `-it` запускает контейнер с терминалом
- `--name` задаёт имя контейнера
- `-v` подключает локальный каталог `artifacts` к `/home/fuzz/artifacts` внутри контейнера
- `:ro` монтирует каталог только для чтения

## 3. Подготовка fuzz-target

```bash
cd /go/src/gjson-1.18.0
git apply /home/fuzz/artifacts/gjson.patch
mkdir -p testdata/fuzz/FuzzParseJSON
cp /home/fuzz/artifacts/corpus/* testdata/fuzz/FuzzParseJSON/
```

`git apply` добавляет fuzz-функцию в исходники `gjson`

`testdata/fuzz/FuzzParseJSON` — каталог seed корпуса. Фаззер берёт из него стартовые тесткейсы для `FuzzParseJSON`

## 4. Описание fuzz-функции

Патч добавляет:

```go
func FuzzParseJSON(f *testing.F) {
	f.Fuzz(func(t *testing.T, orig string) {
		Parse(orig)
	})
}
```

- `f *testing.F` — объект фаззера
- `f.Fuzz(...)` задаёт тестирующую функцию
- `orig string` — вход, который генерирует фаззер
- `Parse(orig)` — целевая функция

## 5. Запуск фаззинга

Основные показатели строки статистики:

| Показатель | Значение |
|---|---|
| `elapsed` | время работы фаззера |
| `execs` | число выполнений fuzz-target |
| `new interesting` | новые входы, которые дали покрытие |

```bash
go test -fuzz=Fuzz -run=FuzzParseJSON
```

- `-fuzz=Fuzz` запускает фаззинг тестов, имя которых начинается с `Fuzz`
- `-run=FuzzParseJSON` выбирает конкретный fuzz-тест

Остановка: `Ctrl+C`. Найденные интересные входы сохраняются в кэше Go

## 6. Сбор покрытия

Копируем найденные входы из кэша обратно в корпус и генерим HTML-отчёт:

```bash
cp $(go env GOCACHE)/fuzz/$(go list)/FuzzParseJSON/* testdata/fuzz/FuzzParseJSON
go test -coverprofile=coverage.out -run=FuzzParseJSON -v
go tool cover -html=coverage.out -o ./coverage.html
```

- `go env GOCACHE` — каталог кэша Go
- `go list` — путь пакета
- `-coverprofile` пишет профиль покрытия в файл
- `-run=FuzzParseJSON` прогоняет корпус без мутаци
- `go tool cover -html` генерит HTML-отчёт

На хосте:

```bash
docker cp gjson_fuzz:/go/src/gjson-1.18.0/coverage.html .
```

Отчет появится в текущкй папке
