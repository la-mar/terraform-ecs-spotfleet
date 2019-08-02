


plan-dev:
	terraform workspace select dev
	touch env/dev.tfvars
	touch env/secrets.tfvars
	${eval AWS_ACCESS_KEY_ID=$${AWS_ACCESS_KEY_ID_DEV}}
	${eval AWS_SECRET_ACCESS_KEY=$${AWS_SECRET_ACCESS_KEY_DEV}}
	${eval AWS_ACCOUNT_ID=$${AWS_ACCOUNT_ID_DEV}}
	terraform plan -var-file=env/secrets.tfvars -var-file=env/dev.tfvars

apply-dev:
	terraform workspace select dev
	touch env/dev.tfvars
	touch env/secrets.tfvars
	${eval AWS_ACCESS_KEY_ID=$${AWS_ACCESS_KEY_ID_DEV}}
	${eval AWS_SECRET_ACCESS_KEY=$${AWS_SECRET_ACCESS_KEY_DEV}}
	${eval AWS_ACCOUNT_ID=$${AWS_ACCOUNT_ID_DEV}}
	terraform apply  -var-file=env/secrets.tfvars -var-file=env/dev.tfvars -auto-approve -parallelism=25

plan-stage:
	terraform workspace select stage
	touch env/stage.tfvars
	touch env/secrets.tfvars
	${eval AWS_ACCESS_KEY_ID=$${AWS_ACCESS_KEY_ID_DEV}}
	${eval AWS_SECRET_ACCESS_KEY=$${AWS_SECRET_ACCESS_KEY_DEV}}
	${eval AWS_ACCOUNT_ID=$${AWS_ACCOUNT_ID_DEV}}
	terraform plan -var-file=env/secrets.tfvars -var-file=env/stage.tfvars

apply-stage:
	terraform workspace select stage
	touch env/stage.tfvars
	touch env/secrets.tfvars
	${eval AWS_ACCESS_KEY_ID=$${AWS_ACCESS_KEY_ID_DEV}}
	${eval AWS_SECRET_ACCESS_KEY=$${AWS_SECRET_ACCESS_KEY_DEV}}
	${eval AWS_ACCOUNT_ID=$${AWS_ACCOUNT_ID_DEV}}
	terraform apply  -var-file=env/secrets.tfvars -var-file=env/stage.tfvars -auto-approve -parallelism=25


plan-prod:
	terraform workspace select prod
	touch env/prod.tfvars
	touch env/secrets.tfvars
	${eval AWS_ACCESS_KEY_ID=$${AWS_ACCESS_KEY_ID_PROD}}
	${eval AWS_SECRET_ACCESS_KEY=$${AWS_SECRET_ACCESS_KEY_PROD}}
	${eval AWS_ACCOUNT_ID=$${AWS_ACCOUNT_ID_PROD}}
	terraform plan -var-file=env/secrets.tfvars -var-file=env/prod.tfvars

apply-prod:
	terraform workspace select prod
	touch env/prod.tfvars
	touch env/secrets.tfvars
	${eval AWS_ACCESS_KEY_ID=$${AWS_ACCESS_KEY_ID_PROD}}
	${eval AWS_SECRET_ACCESS_KEY=$${AWS_SECRET_ACCESS_KEY_PROD}}
	${eval AWS_ACCOUNT_ID=$${AWS_ACCOUNT_ID_PROD}}
	terraform apply -var-file=env/secrets.tfvars -var-file=env/prod.tfvars















