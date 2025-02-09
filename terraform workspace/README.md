<h3>Terraform workspace:</h3>
<b>Terraform workspace allow you to manage multiple envirnments (like dev,staging and prod)</b><br>
<b>using a single terraform configuration.This help managing multiple .tfstate files manually.</b>
<br>
<h3>* How to try this configurations. *</h3>
1. make workspaces named default ,dev and prod.<br>
2. apply this configurations from default workspace ,so your instance launch with t2.micro ins_type,<br>
as you mention ins_types in variables.tf.<br>
3. and then switch workspace to dev and apply configurations, so your instance launch with your mentioned<br>
   ins_type as you add in variables.tf for dev workspace.
4. the instace type is changes according to your workspaces.
