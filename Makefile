# TAG?=latest
IMAGE_PREFIX:=kayuii
IMAGE_TAG:=mass

TARGET_IMAGE_PRD=$(IMAGE_PREFIX)/$(IMAGE_TAG)

ifndef CIRCLE_TAG
TAG_PREFIX:="latest"
else
TAG_PREFIX:=$(shell echo $(CIRCLE_TAG) | sed 's/-v[0-9.]*/-v/')
endif

TAG := $(shell git describe --tags --abbrev=0 --match '${TAG_PREFIX}*')
VERSION := $(shell echo $(TAG) | sed 's/^${TAG_PREFIX}//')
COMMIT := $(shell git rev-parse HEAD)
SHORTCOMMIT := $(shell echo $(COMMIT) | cut -c1-7)
RELEASE := $(shell git describe --tags --match '${TAG_PREFIX}*' \
             | sed 's/^${TAG_PREFIX}//' \
             | sed 's/^[^-]*-//' \
             | sed 's/-/./')
BRANCH := $(shell git rev-parse --abbrev-ref HEAD)
ifeq ("$(BRANCH)", "master")
	TARGET_IMAGE = $(shell echo "${TARGET_IMAGE_PRD}:latest")
else
	TARGET_IMAGE = $(shell echo "${TARGET_IMAGE_PRD}:${TAG}")
endif

all: mass

echo:
	@echo ""
	@echo "Make echo"
	@echo TAG $(TAG)
	@echo COMMIT $(COMMIT)
	@echo TAG_PREFIX $(TAG_PREFIX)
	@echo VERSION $(VERSION)
	@echo SHORTCOMMIT $(SHORTCOMMIT)
	@echo RELEASE $(RELEASE)
	@echo TARGET_IMAGE $(TARGET_IMAGE)

tag:
	$(eval BRANCH := $(shell git rev-parse --abbrev-ref HEAD))
	$(eval LASTNUM := $(shell echo $(TAG) \
	                    | sed -E "s/.*[^0-9]([0-9]+)$$/\1/"))
	$(eval NEXTNUM=$(shell echo $$(($(LASTNUM)+1))))
	$(eval NEXTTAG=$(shell echo $(TAG) | sed "s/$(LASTNUM)$$/$(NEXTNUM)/"))
	if [ "$(TAG)" = "$(git describe --tags --match 'v*')" ]; then \
	    echo "$(SHORTCOMMIT) on $(BRANCH) is already tagged as $(TAG)"; \
	    exit 1; \
	fi
	if [ "$(BRANCH)" != "master" ] && \
	   ! [ "$(BRANCH)" =~ ^chiapos- ]; then \
		echo Cannot tag $(BRANCH); \
		exit 1; \
	fi
	@echo Tagging Git branch $(BRANCH)
	git tag $(NEXTTAG)
	@echo run \'git push origin $(NEXTTAG)\' to push to GitHub.

master: echo
	docker build --build-arg MINERVER=$(VERSION) --build-arg WALLETVER=$(VERSION) -f Dockerfile -t ${TARGET_IMAGE} . ;

mass: echo
	docker build --build-arg MINERVER=$(VERSION) --build-arg WALLETVER=$(VERSION) -f Dockerfile -t ${TARGET_IMAGE} . ;

push:
	docker push ${TARGET_IMAGE} ;


.PHONY: mass tag master
