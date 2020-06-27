# Let's Create a Spark Cluster with Delta Lake!

This is a simple tutorial for setting up a cluster on your local machine to run spark apps with.

# Setup

You'll need to first:

1. [Download spark 3.0](https://spark.apache.org/downloads.html) and unzip it somewhere (I put it at '~/spark/`)
2. `export SPARK_HOME=<put folder path path of where you unziped spark here>`
3. Install pyspark for running our spark apps:
```
pip install --upgrade pyspark
```
4. Install Delta Lake packages for pyspark
```
pyspark --packages io.delta:delta-core_2.12:0.7.0 --conf "spark.sql.extensions=io.delta.sql.DeltaSparkSessionExtension" --conf "spark.sql.catalog.spark_catalog=org.apache.spark.sql.delta.catalog.DeltaCatalog"
```

Easy! You are ready to go.

# Starting a Cluster

Spark clusters have a primary server and several workers worker servers. Let's first create a primary server.

```
sh ${SPARK_HOME}/sbin/start-master.sh -h localhost
```

You can see it running now at `http://http://localhost:8080/`

Now let's create a worker also running on your local machine.

```
sh ${SPARK_HOME}/sbin/start-slave.sh spark://localhost:7077
```

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
#spark.range(10).write.format("delta").save("/tmp/events")
# use the disk location as a table
spark.sql("create table events using delta location '/tmp/events'")
# execute some sql against it
spark.sql("select * from events").show(100)
```

Delta Lake stores our table as a parquet file in our local system.

# Running An App

All we have to do is run.

```
python3 example.py
```