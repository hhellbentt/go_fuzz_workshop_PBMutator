FROM golang:1.24-bookworm

RUN apt-get update && apt-get install -y \
    protobuf-compiler \
    git \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /go/src

RUN git clone --depth 1 --branch v1.18.0 \
    https://github.com/tidwall/gjson.git

WORKDIR /go/src/gjson

COPY artifacts artifacts

RUN sed -i '/github.com\/yandex-cloud\/go-protobuf-mutator/d' go.mod

RUN go get \
    github.com/yandex-cloud/go-protobuf-mutator@latest \
    google.golang.org/protobuf@latest

RUN go mod tidy

RUN go install google.golang.org/protobuf/cmd/protoc-gen-go@latest


RUN mkdir -p artifacts/testdata/fuzz/FuzzParseJSON


CMD ["/usr/bin/bash"]