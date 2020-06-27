start:
	sh ${SPARK_HOME}/sbin/start-master.sh -h localhost
stop:
	sh ${SPARK_HOME}/sbin/stop-master.sh 
start_worker:
	sh ${SPARK_HOME}/sbin/start-slave.sh spark://localhost:7077
stop_worker:
	sh ${SPARK_HOME}/sbin/stop-slave.sh
example:
	python3 example.py
pyspark:
	PYSPARK_DRIVER_PYTHON=jupyter PYSPARK_DRIVER_PYTHON_OPTS='notebook' pyspark --master spark://localhost:7077 --packages io.delta:delta-core_2.12:0.7.0 --conf "spark.sql.extensions=io.delta.sql.DeltaSparkSessionExtension" --conf "spark.sql.catalog.spark_catalog=org.apache.spark.sql.delta.catalog.DeltaCatalog"
pyspark_aws:
	PYSPARK_DRIVER_PYTHON=jupyter PYSPARK_DRIVER_PYTHON_OPTS='notebook' pyspark --master spark://localhost:7077 --packages io.delta:delta-core_2.12:0.7.0,com.amazonaws:aws-java-sdk:1.7.4,org.apache.hadoop:hadoop-aws:2.7.4 --conf "spark.sql.extensions=io.delta.sql.DeltaSparkSessionExtension" --conf "spark.sql.catalog.spark_catalog=org.apache.spark.sql.delta.catalog.DeltaCatalog" --conf "spark.delta.logStore.class=org.apache.spark.sql.delta.storage.S3SingleDriverLogStore" --conf "spark.hadoop.fs.s3a.access.key=${AWS_ACCESS_KEY}" --conf "spark.hadoop.fs.s3a.secret.key=${AWS_SECRET_KEY}"