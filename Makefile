# /$$       /$$                     /$$                   /$$
# | $$      | $$                    | $$                  | $$
# | $$$$$$$ | $$  /$$$$$$   /$$$$$$$| $$   /$$  /$$$$$$$ /$$$$$$    /$$$$$$  /$$$$$$$   /$$$$$$
# | $$__  $$| $$ |____  $$ /$$_____/| $$  /$$/ /$$_____/|_  $$_/   /$$__  $$| $$__  $$ /$$__  $$
# | $$  \ $$| $$  /$$$$$$$| $$      | $$$$$$/ |  $$$$$$   | $$    | $$  \ $$| $$  \ $$| $$$$$$$$
# | $$  | $$| $$ /$$__  $$| $$      | $$_  $$  \____  $$  | $$ /$$| $$  | $$| $$  | $$| $$_____/
# | $$$$$$$/| $$|  $$$$$$$|  $$$$$$$| $$ \  $$ /$$$$$$$/  |  $$$$/|  $$$$$$/| $$  | $$|  $$$$$$$
# |_______/ |__/ \_______/ \_______/|__/  \__/|_______/    \___/   \______/ |__/  |__/ \_______/
#

# POINTLESS CHANGE

CI_IMAGE="quay.io/monax/blackstone:ci"

# Convert each assigment to if-not-set '?=' assignment to match behaviour of dotenv module within files
dotenv := $(shell grep -v '^\#' .env | sed 's/=/?=/')
# This is work-around my makefile syntax checker...
exp:=export
$(foreach pair,$(dotenv),$(eval $(exp) $(pair)))

.PHONY: clean
clean:
	rm -rf dist
	rm -rf src/bin

.PHONY: build_contracts_burrow
build_contracts_burrow:
	cd src && burrow deploy build.yaml

# Just run the dependency services in docker compose
.PHONY: docker_run_deps
docker_run_deps:
	docker-compose up -d chain vent postgres

.PHONY: docker_run_chain
docker_run_chain:
	docker-compose up -d chain

.PHONY: docker_test_chain
docker_test_chain: docker_run_chain
	rm -rf src/bin
	docker-compose run contracts

# API image for CI use outside of compose

.PHONY: build_ci_image
build_ci_image:
	docker build -t ${CI_IMAGE} .

.PHONY: push_ci_image
push_ci_image: build_ci_image
	docker push ${CI_IMAGE}

dist: src/build.ts $(shell find src -name '*.sol')
	yarn build
	rsync -avzC --include='*/' --include='*.sol' --include='*.yaml' --exclude='*' src dist
	cp -r src/bin dist

.PHONY: publish
publish: clean dist
	yarn publish --access public
