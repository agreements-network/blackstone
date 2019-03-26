# /$$       /$$                     /$$                   /$$
# | $$      | $$                    | $$                  | $$
# | $$$$$$$ | $$  /$$$$$$   /$$$$$$$| $$   /$$  /$$$$$$$ /$$$$$$    /$$$$$$  /$$$$$$$   /$$$$$$
# | $$__  $$| $$ |____  $$ /$$_____/| $$  /$$/ /$$_____/|_  $$_/   /$$__  $$| $$__  $$ /$$__  $$
# | $$  \ $$| $$  /$$$$$$$| $$      | $$$$$$/ |  $$$$$$   | $$    | $$  \ $$| $$  \ $$| $$$$$$$$
# | $$  | $$| $$ /$$__  $$| $$      | $$_  $$  \____  $$  | $$ /$$| $$  | $$| $$  | $$| $$_____/
# | $$$$$$$/| $$|  $$$$$$$|  $$$$$$$| $$ \  $$ /$$$$$$$/  |  $$$$/|  $$$$$$/| $$  | $$|  $$$$$$$
# |_______/ |__/ \_______/ \_______/|__/  \__/|_______/    \___/   \______/ |__/  |__/ \_______/
#

CI_IMAGE="quay.io/monax/blackstone:ci"

### Contracts

.PHONY: build_contracts
build_contracts:
	contracts/build_contracts $(tgt)

.PHONY: deploy_contracts
deploy_contracts:
	contracts/deploy_contracts $(tgt)

.PHONY: test_contracts
test_contracts:
	contracts/test_contracts $(tgt)

.PHONY: copy_abis
copy_abis:
	contracts/copy_abis

### Node API

.PHONY: install_api
install_api:
	cd api && npm install

.PHONY: test_api
test_api: copy_abis
	cd api && npm test

### Run and test

.PHONY: all
all: | build_contracts deploy_contracts copy_abis install_api

# Full test (run by CI)
.PHONY: test
# Ordered execution
test: | all test_contracts test_api docs

.PHONY: clean
clean:
	test/clean.sh

.PHONY: clean_all
clean_all:
	test/clean.sh all

### Documentation
.PHONY: docs
docs:
	docs/generate.sh

.PHONY: push_docs
push_docs: docs
	docs/push.sh

### Docker Compose

DCB_ARGS := --build-arg UID=$(shell id -u) --build-arg GID=$(shell id -g)

.PHONY: docker_build
docker_build:
	docker-compose build ${DCB_ARGS}

# To catch DCB args above so we build with CI user
.PHONY: docker_test
docker_test: docker_run_deps
	docker-compose logs -f > test/docker-compose.log &
	docker-compose run api make test

# Just run the dependency services in docker compose (you can build and deploy contracts and the run the API locally)
.PHONY: docker_run_deps
docker_run_deps: docker_build
	docker-compose up -d chain vent postgres hoard

# Build all the contracts and run the API its dependencies
.PHONY: docker_run_all
docker_run_all: docker_build
	docker-compose run api make all
	docker-compose up -d
	docker-compose logs --follow api &

# Just run the API and its dependencies
.PHONY: docker_run
docker_run: docker_build
	docker-compose up -d
	docker-compose logs --follow api &

# API image for CI use outside of compose

.PHONY: build_ci_image
build_ci_image:
	docker build -t ${CI_IMAGE} .

.PHONY: push_ci_image
push_ci_image: build_ci_image
	docker push ${CI_IMAGE}
