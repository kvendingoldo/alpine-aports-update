FROM alpine:latest

RUN	apk add --no-cache \
  bash \
  ca-certificates \
  curl \
  jq

COPY src/util_free_space.sh /util_free_space.sh
RUN chmod +x /util_free_space.sh
ENTRYPOINT ["/util_free_space.sh"]
