PROJECT :=booter
CW :=$(shell pwd)
CACHE := download-cache
WORK :=_work
POLICIES :=policies
# So we know where we are.
WD := $(shell pwd)
BIN := $(WD)/bin
UNAME:= $(shell sh -c 'uname -s 2>/dev/null || echo not')
UNAME:= $(shell echo $(UNAME) | tr '[:upper:]' '[:lower:]')
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
		python boot-service/organizations.py | tee root/terraform.tfvars

update_policies:
	docker run --rm -it \
		-e AWS_DEFAULT_REGION \
		-e AWS_SECRET_ACCESS_KEY \
		-e AWS_ACCESS_KEY_ID \
		-v $(CW)/:/usr/src/app \
		boot-service:latest \
		python boot-service/update_policies.py

root:
	docker run --rm -it \
		-e AWS_DEFAULT_REGION \
		-e AWS_SECRET_ACCESS_KEY \
		-e AWS_ACCESS_KEY_ID \
		-v $(CW)/:/usr/src/app \
		boot-service:latest \
		python boot-service/root.py

user:
	docker run --rm -it \
		-e AWS_DEFAULT_REGION \
		-e AWS_SECRET_ACCESS_KEY \
		-e AWS_ACCESS_KEY_ID \
		-v $(CW)/:/usr/src/app \
		boot-service:latest \
		python boot-service/user.py

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

root_state_init:
	(cd root_state && ../bin/terraform init)

root_state_plan:
	(cd root_state && ../bin/terraform plan -var-file=../root/terraform.tfvars)

root_state_apply:
	(cd root_state && ../bin/terraform apply -var-file=../root/terraform.tfvars)

root_init:
	(cd root && ../bin/terraform init -reconfigure -backend-config=backend.tfvars)

root_plan:
	(cd root && ../bin/terraform plan)

root_apply:
	(cd root && ../bin/terraform apply)

root_destroy:
	(cd root && ../bin/terraform destroy)

development_state:
	(cd development && ../bin/terraform apply -target aws_dynamodb_table.state_lock)

development_init:
	(cd development && ../bin/terraform init)

development_plan:
	(cd development && ../bin/terraform plan)

development_apply:
	(cd development && ../bin/terraform apply)

development_destroy:
	(cd development && ../bin/terraform destroy)
