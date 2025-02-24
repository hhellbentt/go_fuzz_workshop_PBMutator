# Go Fuzzing Workshop

## Подготовка окружения

``` #bash
docker build --tag=gjson_workshop_img .
docker run -it -v "$(pwd)/artifacts:/home/fuzz/artifacts:ro" --name=gjson_fuzz gjson_workshop_img
```

## Запуск фаззинга

``` #bash
cd /go/src/gjson-1.18.0
git apply /home/fuzz/artifacts/gjson.patch
mkdir -p testdata/fuzz/FuzzParseJSON
cp /home/fuzz/artifacts/corpus/* testdata/fuzz/FuzzParseJSON/
go test -fuzz=Fuzz -run=FuzzParseJSON
```

## Сбор покрытия

``` #bash
cp $( go env GOCACHE )/fuzz/$( go list )/FuzzParseJSON/* testdata/fuzz/FuzzParseJSON
go test -coverprofile=coverage.out -run=FuzzParseJSON -v
go tool cover -html=coverage.out -o ./coverage.html
```

на хосте:
``` #bash
docker cp gjson_fuzz:/go/src/gjson-1.18.0/coverage.html .
```
