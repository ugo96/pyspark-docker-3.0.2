FROM python:3.7-slim-stretch

ARG SPARK_HOME="${SPARK_HOME}/spark" \
    SPARK_WORKLOAD="master"\
    SPARK_LOG_DIR=/opt/spark/logs \
    \
    SPARK_MASTER_PORT=7077 \
    SPARK_MASTER="spark://spark-master:$SPARK_MASTER_PORT" \
    SPARK_MASTER_WEBUI_PORT=8080 \
    SPARK_MASTER_LOG=/opt/spark/logs/spark-master.out \
    \
    SPARK_WORKER_PORT=7000 \
    SPARK_WORKER_WEBUI_PORT=8080 \
    SPARK_WORKER_LOG=/opt/spark/logs/spark-worker.out 

ENV SPARK_HOME='/opt'\
    PYTHONHASHSEED=1

RUN \
    apt-get update && \
    apt-get install -y software-properties-common && \
    rm -rf /var/lib/apt/lists/*

RUN \
    apt-get update && \
    mkdir -p /usr/share/man/man1 && \
    apt-get install -y openjdk-8-jdk wget procps openssh-server && \
    rm -rf /var/lib/apt/lists/*

RUN \
    apt-get update && \
    apt-get install -y scala && \
    rm -rf /var/lib/apt/lists/*

WORKDIR ${SPARK_HOME}

RUN \
    wget https://dlcdn.apache.org/spark/spark-3.2.0/spark-3.2.0-bin-hadoop3.2.tgz && \
    tar xvf spark-3.2.0-bin-hadoop3.2.tgz  && \
    mv spark-3.2.0-bin-hadoop3.2 spark

EXPOSE 8080 7077 7000

# Setup application
WORKDIR /opt/application
COPY requirements.txt .
RUN pip3 install -r requirements.txt

# Entrypoint
CMD [   "if [ "$SPARK_WORKLOAD" == "master" ]; \
        then \ 
            export SPARK_MASTER_HOST=`hostname` \
            cd /opt/spark/bin && \
            ./spark-class org.apache.spark.deploy.master.Master \
                --ip $SPARK_MASTER_HOST \
                --port $SPARK_MASTER_PORT \
                --webui-port $SPARK_MASTER_WEBUI_PORT \
            >> $SPARK_MASTER_LOG \
            \
        elif [ "$SPARK_WORKLOAD" == "worker" ]; \
        then \
            cd /opt/spark/bin && \
            ./spark-class org.apache.spark.deploy.worker.Worker \
                --webui-port $SPARK_WORKER_WEBUI_PORT $SPARK_MASTER \
            >> $SPARK_WORKER_LOG \
        elif [ "$SPARK_WORKLOAD" == "submit" ];\
        then\
            echo "SPARK SUBMIT"\
            ######################################
            # Add spark-submit command over here #
            ######################################
        else\
            echo "Undefined Workload Type $SPARK_WORKLOAD, must specify: master, worker, submit"\
        fi"\
    ]
