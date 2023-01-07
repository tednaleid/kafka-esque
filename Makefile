SRC_DIR := src
MAIN_BIN := esque
MAIN_NIM_PATH := $(SRC_DIR)/$(MAIN_BIN).nim

.PHONY: build
build:
	nim compile -g --debugger:native -o:bin/$(MAIN_BIN) $(MAIN_NIM_PATH)

.PHONY: test
test: build
	nim c -r --outdir:build tests/*.nim

.PHONY: clean
clean:
	rm -rf releases
	rm -rf build
	rm -f bin/$(MAIN_BIN)

.PHONY: build-releases
build-releases: build-release-linux-amd64 build-release-macosx-arm64 build-release-macosx-amd64
	find releases -ls

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
		    --passc:"-target x86_64-linux-gnu" \
		    --passl:"-target x86_64-linux-gnu" \
		    --os:linux \
		    --cpu:amd64 \
		    --forceBuild:on \
		    -d:release \
				--passc:-flto \
		    --opt:speed \
		    --outdir:releases/linux_amd64 \
		    --out:$(MAIN_BIN) \
		    $(MAIN_NIM_PATH)

.PHONY: build-release-macosx-arm64
build-release-macosx-arm64:
	nim c -d:release \
				--passc:-flto \
	      --warnings:on \
		    --cpu:arm64 \
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
	nimpretty $(SRC_DIR)/**/*.nim