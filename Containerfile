ARG ELIXIR_VERSION
ARG OTP_VERSION
FROM docker.io/library/elixir:${ELIXIR_VERSION}-otp-${OTP_VERSION}-slim
ARG PHOENIX_VERSION

# Install system dependencies needed for compilation and file-watching
RUN apt-get update && apt-get install -y inotify-tools build-essential git \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Pin MIX_HOME/HEX_HOME to a fixed, world-writable path rather than relying
# on $HOME. --userns=keep-id at `podman run` time switches the container
# process to your host UID (not root, even with no USER directive), so
# anything root creates here at build time needs to end up world-writable —
# the chmod must run AFTER local.hex/local.rebar/archive.install populate
# these directories, not before, since files/dirs they create get root's
# normal umask (not world-writable) regardless of the parent dir's mode.
ENV MIX_HOME=/usr/local/lib/mix
ENV HEX_HOME=/usr/local/lib/hex
RUN mkdir -p "$MIX_HOME" "$HEX_HOME" && \
    mix local.hex --force && \
    mix local.rebar --force && \
    mix archive.install hex phx_new ${PHOENIX_VERSION} --force && \
    chmod -R a+rwX "$MIX_HOME" "$HEX_HOME"

WORKDIR /app
