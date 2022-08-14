FROM ubuntu:22.04 AS build-stage
WORKDIR /mandelbot
RUN apt-get update -y
RUN DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y ca-certificates git golang make

COPY go.mod go.sum .
RUN go mod download

COPY . .

RUN VERSION=$(echo $(git describe --tags) | sed 's/^v//') && \
    COMMIT=$(git log -1 --format='%H') && \
    ldflags='-X github.com/cosmos/cosmos-sdk/version.Name=mandelbot \
        -X github.com/cosmos/cosmos-sdk/version.ServerName=mandelbotd \
        -X github.com/cosmos/cosmos-sdk/version.Version=$(VERSION) \
        -X github.com/cosmos/cosmos-sdk/version.Commit=$(COMMIT) \
        -X "github.com/cosmos/cosmos-sdk/version.BuildTags=netgo,"' && \
    GOOS=linux GOARCH=amd64 CGO_ENABLED=1 go build -mod=readonly -tags netgo -ldflags "${ldflags}" -o /tmp ./cmd/mandelbotd

FROM scratch AS export-stage
COPY --from=build-stage /tmp/mandelbotd /mandelbotd
