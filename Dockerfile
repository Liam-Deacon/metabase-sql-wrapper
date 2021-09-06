ARG METABASE_VERSION=latest
FROM metabase/metabase:$METABASE_VERSION
RUN apk add python3
ADD run.sh /
RUN chmod +x run.sh
ENTRYPOINT ["/usr/bin/python3", "/run.sh"]

