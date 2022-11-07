# AzureSQLServerBicep

Deploys Azure SQL Server (not databases) with Private Endpoint, Auditing Settings, and Storage Account (for vulnerabilities assessments).Private endpoints tie in with existing DNS zones.

Couple of assumptions: 
1.	Hard coded the subID as those never change except between environments in my particular case (and I have a param that selects the environment).
2.	SQLAdmin password needs to be precreated in a KeyVault prior to deployment (you could do a keyvault for each environment and use the same logic in there for subnets)
3.	Hard coded DNS, LAW, and EventHub resource IDs as those never change
4.	Did not include databases as that would be a separate job / process IMO and requires more flexibility
5.	Tested everything in US GovVirginia
6. Used modules when feasible, however, for simplicity of child deployments in the Azure SQL Server bicep file, I included the Private Endpoint in that template.
7. Need to add GRS and turn on auto vul assessments; easy fixed, but not done yet. 
