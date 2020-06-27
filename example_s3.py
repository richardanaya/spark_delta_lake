import os
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
spark.sql("create table events using delta location 's3a://<your bucket>/events'")
# execute some sql against it
spark.sql("select * from events").show(100)