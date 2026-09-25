HUGO_VERSION := $(shell cat .hugo-version)
WEASYPRINT_VERSION := $(shell cat .weasyprint-version)
CHECK_JSONSCHEMA_VERSION := $(shell cat .check-jsonschema-version)
export HUGO_VERSION WEASYPRINT_VERSION CHECK_JSONSCHEMA_VERSION

.PHONY: image build test serve shell clean

image:
	docker compose build

build: image
	docker compose run --rm shell sh scripts/build.sh

test: build
	docker compose run --rm shell sh scripts/test-page-weight.sh

serve: image
	docker compose up hugo

shell: image
	docker compose run --rm shell

clean:
	docker compose down --rmi local
