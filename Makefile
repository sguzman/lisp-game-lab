SHELL := /bin/sh
SBCL ?= sbcl
EMACS ?= emacs
CC ?= cc
BUILD := build
UNAME := $(shell uname -s)
ifeq ($(UNAME),Darwin)
SHIM := $(BUILD)/liblab-raylib.dylib
SHARED := -dynamiclib
else
SHIM := $(BUILD)/liblab-raylib.so
SHARED := -shared
endif

.PHONY: check test style format native abi run smoke render render-smoke live live-smoke assets assets-smoke console console-smoke objects objects-smoke rooms rooms-smoke audio audio-smoke bench-build bench-headless bench-graphics clean

check: style test abi

test:
	$(SBCL) --noinform --non-interactive --load scripts/test.lisp

style:
	$(EMACS) --batch -Q --script scripts/style.el

format:
	LAB_FORMAT=1 $(EMACS) --batch -Q --script scripts/style.el

native: $(SHIM)

$(SHIM): native/raylib-bridge.c
	mkdir -p $(BUILD)
	$(CC) $(CPPFLAGS) $(CFLAGS) -std=c11 -Wall -Wextra -Werror -fPIC $(SHARED) -o $@ $< $$(pkg-config --cflags --libs raylib) $(LDFLAGS)

abi: native
	LAB_RAYLIB_BRIDGE="$(abspath $(SHIM))" $(SBCL) --noinform --non-interactive --load scripts/abi.lisp

run: native
	LAB_RAYLIB_BRIDGE="$(abspath $(SHIM))" $(SBCL) --noinform --non-interactive --load scripts/run.lisp

smoke: native
	LAB_RAYLIB_BRIDGE="$(abspath $(SHIM))" LAB_SMOKE=1 $(SBCL) --noinform --non-interactive --load scripts/run.lisp

render: native
	LAB_RAYLIB_BRIDGE="$(abspath $(SHIM))" $(SBCL) --noinform --non-interactive --load scripts/render.lisp

render-smoke: native
	LAB_RAYLIB_BRIDGE="$(abspath $(SHIM))" LAB_SMOKE=1 $(SBCL) --noinform --non-interactive --load scripts/render.lisp

live: native
	LAB_RAYLIB_BRIDGE="$(abspath $(SHIM))" $(SBCL) --noinform --non-interactive --load scripts/live.lisp

live-smoke: native
	LAB_RAYLIB_BRIDGE="$(abspath $(SHIM))" LAB_SMOKE=1 $(SBCL) --noinform --non-interactive --load scripts/live.lisp

assets: native
	LAB_RAYLIB_BRIDGE="$(abspath $(SHIM))" $(SBCL) --noinform --non-interactive --load scripts/assets.lisp

assets-smoke: native
	LAB_RAYLIB_BRIDGE="$(abspath $(SHIM))" LAB_SMOKE=1 $(SBCL) --noinform --non-interactive --load scripts/assets.lisp

console: native
	LAB_RAYLIB_BRIDGE="$(abspath $(SHIM))" $(SBCL) --noinform --non-interactive --load scripts/console.lisp

console-smoke: native
	LAB_RAYLIB_BRIDGE="$(abspath $(SHIM))" LAB_SMOKE=1 $(SBCL) --noinform --non-interactive --load scripts/console.lisp

objects: native
	LAB_RAYLIB_BRIDGE="$(abspath $(SHIM))" $(SBCL) --noinform --non-interactive --load scripts/objects.lisp

objects-smoke: native
	LAB_RAYLIB_BRIDGE="$(abspath $(SHIM))" LAB_SMOKE=1 $(SBCL) --noinform --non-interactive --load scripts/objects.lisp

rooms: native
	LAB_RAYLIB_BRIDGE="$(abspath $(SHIM))" $(SBCL) --noinform --non-interactive --load scripts/rooms.lisp

rooms-smoke: native
	LAB_RAYLIB_BRIDGE="$(abspath $(SHIM))" LAB_SMOKE=1 $(SBCL) --noinform --non-interactive --load scripts/rooms.lisp

audio: native
	LAB_RAYLIB_BRIDGE="$(abspath $(SHIM))" $(SBCL) --noinform --non-interactive --load scripts/audio.lisp

audio-smoke: native
	LAB_RAYLIB_BRIDGE="$(abspath $(SHIM))" LAB_SMOKE=1 $(SBCL) --noinform --non-interactive --load scripts/audio.lisp

bench-build:
	sh scripts/bench-build.sh

bench-headless:
	$(SBCL) --noinform --non-interactive --load scripts/benchmarks.lisp

bench-graphics: native
	LAB_RAYLIB_BRIDGE="$(abspath $(SHIM))" LAB_BENCH_GRAPHICS=1 $(SBCL) --noinform --non-interactive --load scripts/benchmarks.lisp

clean:
	rm -rf $(BUILD)
