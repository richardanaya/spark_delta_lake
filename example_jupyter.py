

spark.sql("CREATE TABLE IF NOT EXISTS events using delta location '/tmp/events'")
spark.sql("select * from events").show(100)
