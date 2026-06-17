HUGO_VERSION := $(shell cat .hugo-version)
GO_VERSION := $(shell cat .go-version)
WEASYPRINT_VERSION := $(shell cat .weasyprint-version)
export HUGO_VERSION GO_VERSION WEASYPRINT_VERSION

.PHONY: image build serve shell clean env

env:
	@echo "HUGO_VERSION=$(HUGO_VERSION)" > .env
	@echo "GO_VERSION=$(GO_VERSION)" >> .env
	@echo "WEASYPRINT_VERSION=$(WEASYPRINT_VERSION)" >> .env

image: env
	docker compose build

build: image
	docker compose run --rm shell sh scripts/build.sh

serve: image
	docker compose up hugo

shell: image
	docker compose run --rm shell

clean:
	docker compose down --rmi local
