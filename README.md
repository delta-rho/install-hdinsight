## Tessera on Microsoft Azure HDInsight

This repository houses a script that will install all necessary components to run Tessera on [Microsoft Azure HDInsight](https://azure.microsoft.com/en-us/services/hdinsight/).

To start a Tessera cluster on HDInsight.

1. Visit [this page](https://azure.microsoft.com/en-us/services/hdinsight/) and either sign in or create an account.
2. Go to the [Azure Portal](https://portal.azure.com/).
3. Create a Resource Group
  - "+ New" -> "Management" -> "Resource Group"
  - Choose a resource group name (e.g. "tessera-group")
  - Choose a subscription (e.g. "Pay-As-You-Go")
  - Choose a resource group location (e.g. "West US")
  - Click "Create"
4. Create a Storage Account
  - "+ New" -> "Data + Storage" -> "Storage Account"
  - Click "Create"
  - Choose a name (e.g. "tesserastorage")
  - Choose a type (e.g. default of "Standard-RAGRS")
  - Choose a subscription (e.g. "Pay-As-You-Go")
  - For "Resource Group", choose "Select existing" and choose the resource group just created in the previous step (e.g. "tessera-group")
  - Choose the same location as that of the resource group (e.g. "West US")
  - Click "Create"
5. Create an HDInsight Cluster
  - "+ New" -> "Data + Analytics" -> "HDInsight"
  - Choose a cluster name (e.g. "tessera-cluster")
  - For "Cluster Type", choose "hadoop"
  - For "Cluster Operating System", choose "Linux"
  - For "Version", choose the default of "Hadoop 2.6.0 (HDI 3.2)"
  - Choose a subscription (e.g. "Pay-As-You-Go")
  - For "Resource Group", choose the resource group created above (e.g. "tessera-group")
  - For "Credentials", *currently the ssh username must be "tessera" for install scripts to work*
  - For "Data Source", choose the data source created above (e.g. "tesserastorage")
  - For "Node Pricing Tiers", select select how many nodes you want and what type of nodes for the head and workers
  - In "Optional Configuration", choose "Script Actions"
    - For "name", use "tessera"
    - For "bash script uri", use "https://raw.githubusercontent.com/tesseradata/install-hdinsight/master/tessera.sh"
    - Check the "head" box
    - Click "Select"

You can now ssh into the head node and go to work.

A one-time step when you log in is to ship your current configuration of R and packages to all the nodes:

```r
library(Rhipe)
rhinit()
hdfs.setwd("/user/tessera/bin")
bashRhipeArchive("R.Pkg")
```

*Make sure you monitor your cluster and shut it down when you are not using it!**

Note that currently although we have installed RStudio Server on the head node, we have not figured out how to access the server over the web (it appears opening ports in Azure is not so easy), but we are working on it.  In the mean time, a utility like [rmote](https://github.com/hafen/rmote) can be useful for getting graphics back from the remote head node.

Also note that this script and these instructions are evolving.  Suggestions to both are welcome.
