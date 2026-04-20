#!/bin/sh
set -eu
exec docker exec -it \
	-u "${LICHTFELD_EXEC_USER}" \
	-w "${LICHTFELD_WORKDIR}" \
	"${LICHTFELD_CONTAINER}" \
	"$@"
