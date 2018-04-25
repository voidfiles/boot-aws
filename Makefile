PROJECT :=booter
CW :=$(shell pwd)
CACHE := download-cache
WORK :=_work
POLICIES :=policies
# So we know where we are.
WD := $(shell pwd)
BIN := $(WD)/bin
# Pin some terraform details. For now amd64 only on darwin and linux (though
# freebsd, openbsd, solaris, windows may also work). In a few years we'll
# prolly target ARM. No ARM support at AWS yet but Azure is an early adopter.
TFM_VERSION := 0.11.7
TFM_FILENAME := terraform_$(TFM_VERSION)_$(UNAME)_amd64.zip
TFM_DOWNLOAD_URL := https://releases.hashicorp.com/terraform/$(TFM_VERSION)/$(TFM_FILENAME)
TFM_CHECKSUM_FILENAME := terraform_$(TFM_VERSION)_SHA256SUMS
TFM_CHECKSUMS_URL := https://releases.hashicorp.com/terraform/$(TFM_VERSION)/$(TFM_CHECKSUM_FILENAME)
TFM_CMD := $(BIN)/terraform

shell_in_docker:
	docker run --rm -it \
		-e AWS_DEFAULT_REGION \
		-e AWS_SECRET_ACCESS_KEY \
		-e AWS_ACCESS_KEY_ID \
		-v $(CW)/:/usr/src/app \
		boot-service:latest \
		/bin/sh

setup_organizations:
	docker run --rm -it \
		-e AWS_DEFAULT_REGION \
		-e AWS_SECRET_ACCESS_KEY \
		-e AWS_ACCESS_KEY_ID \
		-v $(CW)/:/usr/src/app \
		boot-service:latest \
		python boot-service/app.py

update_policies:
	docker run --rm -it \
		-e AWS_DEFAULT_REGION \
		-e AWS_SECRET_ACCESS_KEY \
		-e AWS_ACCESS_KEY_ID \
		-v $(CW)/:/usr/src/app \
		boot-service:latest \
		python boot-service/update_policies.py

# install installs the terraform binary
install:
	echo "Installing terraform in $(WD)/bin/"
	## Create download cache if it doesn't exist...
	mkdir -p $(WD)/$(CACHE)
	## Fetch terraform and sha sums...
	(cd $(CACHE) && curl -O $(TFM_DOWNLOAD_URL) && curl -O $(TFM_CHECKSUMS_URL))
	## Verify checksum...
	(cd $(CACHE) && grep -q `shasum -a 256 $(TFM_FILENAME)` $(TFM_CHECKSUM_FILENAME))
	## Make bin directory if it doesn't exist.
	mkdir -p $(BIN)
	## Unpack into the bin dir.
	(cd $(WD)/bin && unzip -o $(WD)/$(CACHE)/$(TFM_FILENAME))
	echo -n "Installed terraform: " &&  $(BIN)/terraform --version
	echo "Done..."


build_container:
	docker build . -t boot-service:latest
