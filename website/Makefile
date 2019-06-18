


plan-dev:
	terraform workspace select dev
	touch env/dev.tfvars
	touch env/secrets.tfvars
	terraform plan -var-file=env/secrets.tfvars -var-file=env/dev.tfvars

apply-dev:
	terraform workspace select dev
	touch env/dev.tfvars
	touch env/secrets.tfvars
	terraform apply  -var-file=env/secrets.tfvars -var-file=env/dev.tfvars -auto-approve -parallelism=25

plan-stage:
	terraform workspace select stage
	touch env/stage.tfvars
	touch env/secrets.tfvars
	terraform plan -var-file=env/secrets.tfvars -var-file=env/stage.tfvars

apply-stage:
	terraform workspace select stage
	touch env/stage.tfvars
	touch env/secrets.tfvars
	terraform apply  -var-file=env/secrets.tfvars -var-file=env/stage.tfvars -auto-approve -parallelism=25


plan-prod:
	terraform workspace select prod
	touch env/prod.tfvars
	touch env/secrets.tfvars
	terraform plan -var-file=env/secrets.tfvars -var-file=env/prod.tfvars

apply-prod:
	terraform workspace select prod
	touch env/prod.tfvars
	touch env/secrets.tfvars
	terraform apply -var-file=env/secrets.tfvars -var-file=env/prod.tfvars















