# stage 1: build a static binary
FROM golang:1.26 AS build
WORKDIR /src
COPY go.mod ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 go build -o /motd .

# stage 2: ship only the binary
FROM scratch
COPY --from=build /motd /motd
EXPOSE 8080
ENTRYPOINT ["/motd"]
