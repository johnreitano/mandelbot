# Simple usage with a mounted data directory:
# > docker build -t numi .
# > docker run -it -p 46657:46657 -p 46656:46656 -v ~/.numi:/numi/.numi numi numid init
# > docker run -it -p 46657:46657 -p 46656:46656 -v ~/.numi:/numi/.numi numi numid start
FROM golang:1.18-alpine

# Set working directory for the build
WORKDIR /mandelbot

# Install minimum necessary dependencies for building a Cosmos app
RUN apk add --no-cache curl make git libc-dev bash gcc linux-headers eudev-dev python3

COPY .. .

RUN make -f deploy/Makefile install
