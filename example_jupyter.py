

from pyspark.sql import SparkSession
spark = SparkSession.builder.appName("DeltaLakeExample").getOrCreate()
spark.sql("CREATE TABLE IF NOT EXISTS events using delta location '/tmp/events'")
spark.sql("select * from events").show(100)
