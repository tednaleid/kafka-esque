MAIN_BIN := shell_scratch

.PHONY: build
build:
	nim compile -g --debugger:native -o:bin/$(MAIN_BIN) $(MAIN_BIN).nim

.PHONE: clean
clean:
	rm -rf releases
	rm -f bin/$(MAIN_BIN)


.PHONY: build-releases
build-releases: build-release-linux-amd64 build-release-macosx-arm64 build-release-macosx-amd64
	find releases -ls


.PHONY: build-release-linux-amd64
build-release-linux-amd64:
	docker run --rm -v `pwd`:/usr/src/app -w /usr/src/app nimlang/nim \
	    nim c -d:release \
	          --warnings:on \
		      --outdir:releases/amd64-linux \
		      --opt:speed \
			  $(MAIN_BIN).nim


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
		  --opt:speed \
		  --outdir:releases/linux_amd64 \
		  --out:$(MAIN_BIN) \
		  $(MAIN_BIN).nim

.PHONY: build-release-macosx-arm64
build-release-macosx-arm64:
	nim c -d:release \
	      --warnings:on \
		  --cpu:arm64 \
		  --os:macosx \
		  --out:$(MAIN_BIN) \
		  --outdir:releases/arm64-macosx \
		  $(MAIN_BIN).nim

.PHONY: build-release-macosx-amd64
build-release-macosx-amd64:
	nim c -d:release \
	      --warnings:on \
		  --cpu:amd64 \
		  --os:macosx \
		  --out:$(MAIN_BIN) \
		  --outdir:releases/amd64-macosx \
		  $(MAIN_BIN).nim	


.PHONY: pretty
pretty:
	nimpretty $(MAIN_BIN).nim