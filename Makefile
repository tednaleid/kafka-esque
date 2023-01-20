SRC_DIR := src
TESTS_DIR := tests
MAIN_BIN := esque
MAIN_NIM_PATH := $(SRC_DIR)/$(MAIN_BIN).nim

.PHONY: build
build:
	nim compile -g --debugger:native -o:bin/$(MAIN_BIN) $(MAIN_NIM_PATH)

.PHONY: tests
tests: 
	nim compile -r -g --debugger:native -o:bin/tester tests/tester

.PHONY: clean
clean:
	rm -rf releases
	rm -rf build
	rm -f bin/$(MAIN_BIN)

.PHONY: build-releases
build-releases: build-release-linux-amd64-clang build-release-macosx-arm64 build-release-macosx-amd64
	find releases -ls
#build-releases: build-release-linux-amd64 build-release-macosx-arm64 build-release-macosx-amd64
#	find releases -ls


# broken for now while we're on nim 2.0 pre-release but the nimlang/nim container is 1.6.10 and doesn't have std/widestrs
.PHONY: build-release-linux-amd64
build-release-linux-amd64:
	docker run --rm -v `pwd`:/usr/src/app -w /usr/src/app nimlang/nim \
	    nim c -d:release \
						--passc:-flto \
	          --warnings:on \
		        --outdir:releases/amd64-linux \
		        --opt:speed \
			      $(MAIN_NIM_PATH)


# or, with `zigcc` installed (the zig cross compiler with clang can be used): https://github.com/enthus1ast/zigcc
#    nimble install zigcc
# makes a bigger version of the file
.PHONY: build-release-linux-amd64-clang
build-release-linux-amd64-clang:
	nim c --cc:clang \
	      --clang.exe="zigcc" \
	      --clang.linkerexe="zigcc" \
		    --passc:"-flto -target x86_64-linux-gnu" \
		    --passl:"-flto -target x86_64-linux-gnu" \
		    --os:linux \
		    --cpu:amd64 \
		    --forceBuild:on \
		    -d:release \
		    --opt:speed \
				--outdir:releases/amd64-linux \
		    $(MAIN_NIM_PATH)

.PHONY: build-release-macosx-arm64
build-release-macosx-arm64:
	nim c -d:release \
				--forceBuild:on \
				--cc:clang \
				--deepcopy:on \
				--cpu:arm64 \
				--passC:"-flto -target arm64-apple-macos11" \
				--passL:"-flto -target arm64-apple-macos11" \
				--hints:off \
	      --warnings:on \
		    --os:macosx \
		    --out:$(MAIN_BIN) \
		    --outdir:releases/arm64-macosx \
		    $(MAIN_NIM_PATH)

.PHONY: build-release-macosx-amd64
build-release-macosx-amd64:
	nim c -d:release \
				--passc:-flto \
	      --warnings:on \
		    --cpu:amd64 \
		    --os:macosx \
		    --out:$(MAIN_BIN) \
		    --outdir:releases/amd64-macosx \
		    $(MAIN_NIM_PATH)

.PHONY: pretty
pretty:
	nimpretty $(SRC_DIR)/**/*.nim $(TESTS_DIR)/*.nim