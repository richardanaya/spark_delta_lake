# Let's Create a Spark Cluster with Delta Lake!

This is a simple tutorial for setting up a spark cluster on your local machine to run spark apps that utilize Delta Lake. Delta Lake is a technology that helps:

* Make data transformations storage more resiliant
* Enable time travel
* Make storage more efficient using parquet files

Being able to run on a cluster on your own machine is a stepping stone to running on a cluster in the cloud to ask big questions. Let's have fun!

Please remember Spark security is off by default if you start using any of this tutorial for production.

# Setup

You'll need to first:

1. [Download spark 3.0](https://spark.apache.org/downloads.html) and unzip it somewhere (e.g. `/home/richard/spark/`)
2. `export SPARK_HOME=<put folder path path of where you unziped spark here (e.g. /home/richard/spark)>`
3. Install pyspark for running our spark apps:
```bash
pip install --upgrade pyspark
```

Easy! You are ready to go.

# Starting a Cluster

Spark clusters have a primary server and several workers worker servers. Let's first create a primary server.

```bash
sh ${SPARK_HOME}/sbin/start-master.sh -h localhost
```

You can see it running now at `http://http://localhost:8080/`

Now let's create a worker also running on your local machine.

```bash
sh ${SPARK_HOME}/sbin/start-slave.sh spark://localhost:7077
```

You can see it running at http://localhost:8081/

Now we can run python spark apps! A spark app is basically a small bit of code that knows how to delegate work out to our workers of our cluster.  `pyspark` is a tool that makes writing these spark apps easy. Let's look at a basic example that creates a table, then queries it with sql.

```python
# This is an example pyspark app that does some simple
# things with Delta lake
from pyspark.sql import SparkSession

# load up all the delta lake dependencies in our app
# let's target our cluster on our local machine
spark = SparkSession.builder.appName("DeltaLakeExample")\
    .master("spark://localhost:7077") \
    .config("spark.jars.packages", "io.delta:delta-core_2.12:0.7.0") \
    .config("spark.sql.extensions", "io.delta.sql.DeltaSparkSessionExtension") \
    .config("spark.sql.catalog.spark_catalog", "org.apache.spark.sql.delta.catalog.DeltaCatalog") \
    .getOrCreate()

# write some numbers 
spark.range(10).write.format("delta").save("/tmp/events")
# use the disk location as a table
spark.sql("CREATE TABLE IF NOT EXISTS events using delta location '/tmp/events'")
# execute some sql against it
spark.sql("select * from events").show(100)
```

Delta Lake stores our table as a parquet file in our local system.

Parquet files are a very efficient form of storage for column oriented data operations.

# Running An App

All we have to do is run.

```bash
python3 example.py
```

# Working On S3 

Let's try to run Delta Lake using S3 as the backing store for our parquet files and tables:

1. Make sure you have some AWS credentials by going to the IAM section of AWS Console, find your user name, create new keys.
2. Our example needs to be updated, they key differences are:
* we now add AWS jar packages to our list of packages from maven
* we now configure those jars with our AWS creds
* we're telling our metastore to pay attention to S3 instead of our local file system

```python
# This is an example pyspark app that does some simple
# things with Delta lake
from pyspark.sql import SparkSession

# load up all the delta lake dependencies in our app
# let's target our cluster on our local machine
spark = SparkSession.builder.appName("DeltaLakeExample")\
    .master("spark://localhost:7077") \
    .config("spark.jars.packages", "io.delta:delta-core_2.12:0.7.0,com.amazonaws:aws-java-sdk:1.7.4,org.apache.hadoop:hadoop-aws:2.7.4") \
    .config("spark.sql.extensions", "io.delta.sql.DeltaSparkSessionExtension") \
    .config("spark.sql.catalog.spark_catalog", "org.apache.spark.sql.delta.catalog.DeltaCatalog") \
    .config("spark.delta.logStore.class", "org.apache.spark.sql.delta.storage.S3SingleDriverLogStore") \
    .config("spark.hadoop.fs.s3a.access.key","<your key>") \
    .config("spark.hadoop.fs.s3a.secret.key","<your secret>") \
    .getOrCreate()

# write some numbers 
spark.range(10).write.format("delta").save("s3a://<your bucket>/events")
# use the disk location as a table
spark.sql("CREATE TABLE IF NOT EXISTS events using delta location 's3a://<your bucket>/events'")
# execute some sql against it
spark.sql("select * from events").show(100)
```

Now all we need to do us run

```
python3 example_s3.py
```

# Jupyter Notebook

Now let's get pyspark operational in a Jupyter notebook

1. Make sure jupyter is installed with `pip install jupyter`
2. Now we will tell pyspark to use jupyter as a front end
```bash
export PYSPARK_DRIVER_PYTHON=jupyter
export PYSPARK_DRIVER_PYTHON_OPTS='notebook'
```
3. Finally, let's run pyspark with Delta Lake with all the packages and configuration we will use
```bash
pyspark --master spark://localhost:7077 --packages io.delta:delta-core_2.12:0.7.0 \
    --conf "spark.sql.extensions=io.delta.sql.DeltaSparkSessionExtension" \
    --conf "spark.sql.catalog.spark_catalog=org.apache.spark.sql.delta.catalog.DeltaCatalog"
```

Notice all those params that used to be in are python are now given to pyspark directly. Now create a notebook, and our code is much simpler:

```python
spark.sql("CREATE TABLE IF NOT EXISTS events using delta location '/tmp/events'")
spark.sql("select * from events").show(100)
```

Now let's close our notebook and try running pyspark with the packages to talk to s3 as our file storage

```bash
pyspark --master spark://localhost:7077 \
    --packages io.delta:delta-core_2.12:0.7.0,com.amazonaws:aws-java-sdk:1.7.4,org.apache.hadoop:hadoop-aws:2.7.4 \
    --conf "spark.sql.extensions=io.delta.sql.DeltaSparkSessionExtension" \
    --conf "spark.sql.catalog.spark_catalog=org.apache.spark.sql.delta.catalog.DeltaCatalog" \
    --conf "spark.delta.logStore.class=org.apache.spark.sql.delta.storage.S3SingleDriverLogStore" \
    --conf "spark.hadoop.fs.s3a.access.key=<your key>" \
    --conf "spark.hadoop.fs.s3a.secret.key=<your secret>"
```

Note, all we do is add some new packages and our s3 configuration from earlier.

Now create a notebook:

```python
spark.sql("CREATE TABLE IF NOT EXISTS events using delta location 's3a://<your bucket>/events'")
spark.sql("select * from events").show(100)
```

# Working with the hive metastore

The hive metastore is used to describe the data within our parquet files using SQL concepts. By default, Spark uses a hive metastore on your local machine (you might notice this files `derby` created locally).

Notice in our first line of our notebook

```sql
CREATE TABLE IF NOT EXISTS events using delta location 's3a://<your bucket>/events'
```

We are helping the hive metastore map the concept of a table `event` to our parquet file on S3

You can delete this metadata with a 

```sql
DROP TABLE events
```

If you don't believe me, try it on some simple test data and then try remapping it with another `CREATE TABLE` ;) 

```python
spark.sql("CREATE TABLE IF NOT EXISTS events using delta location '/tmp/events'")
spark.sql("select * from events").show(100)
spark.sql("DROP TABLE events")
spark.sql("CREATE TABLE IF NOT EXISTS events using delta location '/tmp/events'")
spark.sql("select * from events").show(100)
```

It's up to you how you keep your schemas up to date to accurately reflect what's in the parquet files when using SQL.

# Moving this to a real cluster

On a real cluster, there's a number of changes you may do:

* Put your hive metastore on mysql or some other relational database so the cluster can share the same concept of tables
* Use more powerful clusters that allow you to completely delegate the handling of running an app to worker rather than your machine delegating to cluster's workers.  Research `--deploy-mode cluster`.
* [Setup security](https://spark.apache.org/docs/latest/security.html) for multiples machines and multiple user access to the cluster.
