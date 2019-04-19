FROM golang:latest as builder

ENV GO111MODULE=on

WORKDIR /go/src/github.com/appsbyram/seafoodtruck-slack 

COPY . .

RUN go mod tidy

RUN test -z "$(gofmt -l $(find . -type f -name '*.go' -not -path "./vendor/*"))" || { echo "Run \"gofmt -s -w\" on your Golang code"; exit 1; }

RUN go test $(go list ./...) -cover \
    && VERSION=$(git describe --all --exact-match `git rev-parse HEAD` | grep tags | sed 's/tags\///') \
    && GIT_COMMIT_ID=$(git rev-list -1 HEAD) \
    && CGO_ENABLED=0 GOOS=${OS} GOARCH=${ARCH} go build --ldflags "-s -w \
    -X github.com/appsbyram/seafoodtruck-slack/version.Version=${VERSION} \
    -X github.com/appsbyram/seafoodtruck-slack/version.GitCommitID=${GIT_COMMIT_ID} \
    -a -installsuffix cgo -o bot

FROM alpine:latest

COPY entrypoint.sh /root/

RUN apk --no-cache add ca-certificates \
 && chmod +x /root/entrypoint.sh
 
COPY --from=builder /go/src/github.com/appsbyram/seafoodtruck-slack/bot ./bot 

EXPOSE 8080

ENTRYPOINT [ "/root/entrypoint.sh" ]

CMD [ "start" ]