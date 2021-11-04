FROM python:3.7-slim-stretch

ENV SPARK_HOME='/opt'

# RUN \
#     apt-get update && \
#     apt-get install -y software-properties-common

RUN \
    apt-get update && \
    mkdir -p /usr/share/man/man1 && \
    apt-get install -y openjdk-8-jdk wget procps openssh-server&& \
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

ENV SPARK_HOME="${SPARK_HOME}/spark"

# Start Master and Worker
RUN \
    echo ${SPARK_HOME} && \
    ${SPARK_HOME}/sbin/start-master.sh --host localhost
RUN \
    ${SPARK_HOME}/sbin/start-worker.sh  spark://localhost:7077

# Setup application
WORKDIR /opt/application
COPY requirements.txt .
RUN pip3 install -r requirements.txt

COPY main.py .

CMD [   "${SPARK_HOME}/sbin/start-master.sh --host localhost && \
        ${SPARK_HOME}/sbin/start-worker.sh  spark://localhost:7077 && \
        ${SPARK_HOME}/bin/spark-submit --master spark://localhost:7077 ./main.py" \
    ]
