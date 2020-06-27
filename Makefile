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