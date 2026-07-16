# justfile
project      := `basename "$(pwd)"`
elixir_ver   := "1.20"
otp_ver      := "29"
phoenix_ver  := "1.8.9"
image_name   := "phoenix-sandbox"
image_tag    := elixir_ver + "-otp-" + otp_ver
build_vol    := project + "_build_cache"
deps_vol     := project + "_deps_cache"

# Build the pinned Elixir/OTP/Phoenix image
build:
	podman build \
	--build-arg ELIXIR_VERSION={{elixir_ver}} \
	--build-arg OTP_VERSION={{otp_ver}} \
	--build-arg PHOENIX_VERSION={{phoenix_ver}} \
	-t {{image_name}}:{{image_tag}} \
	-f Containerfile .

# Shared podman run invocation, called by the recipes below
_run *cmd:
    podman run -it --rm \
      --userns=keep-id \
      --network=host \
      -v .:/app:Z \
      -v {{build_vol}}:/app/_build \
      -v {{deps_vol}}:/app/deps \
      -w /app \
      {{image_name}}:{{image_tag}} {{cmd}}

# Run a mix command (e.g. just mix test)
mix +args:
    @just _run mix {{args}}

# Start the Phoenix dev server
server:
    @just _run mix phx.server

# Open a shell in the container
shell:
    @just _run /bin/bash

# Wipe this project's build/deps caches
clean-volumes:
    podman volume rm -f {{build_vol}} {{deps_vol}}
