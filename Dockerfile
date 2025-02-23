FROM golang:1.24

WORKDIR /go/src

# get gjson source code
RUN wget https://github.com/tidwall/gjson/archive/refs/tags/v1.18.0.tar.gz
RUN tar xf v1.18.0.tar.gz && rm v1.18.0.tar.gz