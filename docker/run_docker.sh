#!/bin/bash

usage() {
    echo "Usage: $0 [-bnua]"
    echo "  -b       Build with cache"
    echo "  -n       Build without cache"
    echo "  -u       Start docker-compose stack in background"
    echo "  -a       Run pi agent interactively"
    echo "  -c       Stop and clean up"
    echo "  -h       Show this help message"
    echo
    echo "For plain docker compose: use  docker compose -f docker/docker-compose.yml up --build -d  to rebuild when the Dockerfile or repo context changed (Compose cannot enable --build from YAML alone)."
}

# --- Flags
COMPOSE_FILE="docker/docker-compose.yml"
BUILD=false
BUILD_ARGS=""
COMPOSEUP=false
AGENT=false

# --- Parse short options
while getopts "bnucha" opt; do
    case ${opt} in
        b ) BUILD=true ;;
        n ) BUILD=true; BUILD_ARGS="--no-cache" ;;
        u ) COMPOSEUP=true ;;
        a ) AGENT=true ;;
        c ) docker compose -f $COMPOSE_FILE down --remove-orphans; exit 0 ;;
        h ) usage; exit 0 ;;
        * ) usage; exit 1 ;;
    esac
done

shift $((OPTIND - 1))

# --- Export env vars for docker-compose
export HOME=$HOME

# --- Build step
if [ "$BUILD" = true ]; then
    echo "Building docker image..."
    export DOCKER_BUILDKIT=1
    docker compose -f $COMPOSE_FILE build $BUILD_ARGS
    if [ "$?" -ne 0 ]; then
        echo "Docker build failed!"
        exit 1
    fi
fi

# --- Run stack
# --build: (re)build pi-agent when Dockerfile/context changed; BuildKit skips unchanged layers.
if [ "$COMPOSEUP" = true ]; then
    echo "Starting docker stack (pi-agent)..."
    export DOCKER_BUILDKIT=1
    docker compose -f $COMPOSE_FILE up --build -d
    if [ "$?" -ne 0 ]; then
        echo "Docker compose up failed!"
        exit 1
    fi
fi

if [ "$AGENT" = true ]; then
    echo "Starting pi agent container..."
    docker compose -f $COMPOSE_FILE run --rm -it --build pi-agent
fi

if [ "$COMPOSEUP" = true ]; then
    echo "Stack is up. Use 'docker compose -f $COMPOSE_FILE exec pi-agent sh' to open a shell."
fi
