DATE    ?= $(shell date +%FT%T%z)
VERSION ?= $(shell git describe --tags --always --dirty --match=v* 2> /dev/null || \
            cat $(CURDIR)/.version 2> /dev/null || echo v0)
IMAGE ?= docker-watch:$(VERSION)
ARCHIVE ?= docker-watch-$(VERSION).zip
# The Swift build configuration debug|release
CONFIG ?= release

CONTAINER_RUN = docker container run -it --rm -v /var/run/docker.sock:/var/run/docker.sock -v `pwd`:/src -w /src $(IMAGE)

.PHONY: all
all: test image docker-watch

.PHONY: test
test: whitespace-check

.PHONY: whitespace-check
whitespace-check:
	git diff-tree --check $(git hash-object -t tree /dev/null) HEAD

docker-watch:
	swift build -c $(CONFIG) --static-swift-stdlib

.PHONY: image
image:
	docker image build --build-arg CONFIG=$(CONFIG) -t $(IMAGE) .

.PHONY: run
run:
	$(CONTAINER_RUN)

.PHONY: install
install: docker-watch
	cp .build/$(CONFIG)/docker-watch /usr/local/bin/

archive:
	git archive --format zip --output $(ARCHIVE) HEAD

.PHONY: clean
clean:
	swift package clean
	-docker image rm $(IMAGE)
	-rm -f $(ARCHIVE)
