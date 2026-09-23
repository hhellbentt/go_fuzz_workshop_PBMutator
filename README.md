# Тренировочный стенд: фаззинг `gjson` со встроенным фаззером Go

Стенд знакомит с coverage-guided фаззингом Go-кода на примере функции `gjson.Parse` с использованием кастомного protobuf-мутатора.



## 1. Сборка образа

```bash
docker build --tag=gjson_workshop_img .
```

- `--tag` задаёт имя
- `.` передаёт текущий каталог как точку сборки

## 2. Запуск контейнера

```bash
docker run -it  --name=gjson_fuzz gjson_workshop_img
```

- `-it` запускает контейнер с терминалом
- `--name` задаёт имя контейнера

Генерация protobuf-кода:

```bash
protoc --go_out=. --go_opt=paths=source_relative artifacts/json.proto
```


## 3. Описание fuzz-функции
```go
f.Fuzz(func(t *testing.T, data []byte) {
		var message JSON

		if err := proto.Unmarshal(data, &message); err != nil {
			return
		}

		m := mutator.New(1, 4096)

		if err := m.MutateProto(&message); err != nil {
			return
		}

		json := serializeJSON(&message)

		gjson.Parse(json)
	})
```

1) Получили случайные байты
2) Попробовали превратить их в JSON-структуру (если не получилось > остановились)
3) Случайно изменили получившуюся структуру
4) превратили её обратно в JSON
5) попробовали распарсить JSON

## 4. Запуск фаззинга

Основные показатели строки статистики:

| Показатель | Значение |
|---|---|
| `elapsed` | время работы фаззера |
| `execs` | число выполнений fuzz-target |
| `new interesting` | новые входы, которые дали покрытие |

```bash
go test -fuzz=FuzzParseJSON -fuzztime=5m ./artifacts
```

- `-fuzz=Fuzz` запускает фаззинг тестов, имя которых начинается с `Fuzz`
- `-run=FuzzParseJSON` выбирает конкретный fuzz-тест
- `./artifacts` показывает где искать тесты

Остановка: `Ctrl+C`. Найденные интересные входы сохраняются в кэше Go

## 5. Сбор покрытия

Копируем найденные входы из кэша обратно в корпус и генерим HTML-отчёт:

```bash
cp /root/.cache/go-build/fuzz/github.com/tidwall/gjson/artifacts/FuzzParseJSON/* artifacts/testdata/fuzz/FuzzParseJSON/
go test -coverprofile=coverage.out -run=FuzzParseJSON -v ./artifacts
go tool cover -html=coverage.out -o ./coverage.html
```

- `go env GOCACHE` — каталог кэша Go
- `go list` — путь пакета
- `-coverprofile` пишет профиль покрытия в файл
- `-run=FuzzParseJSON` прогоняет корпус без мутаци
- `go tool cover -html` генерит HTML-отчёт

На хосте:

```bash
docker cp gjson_fuzz:/go/src/gjson/coverage.html .
```

Отчет появится в текущкй папке

