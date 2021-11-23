SHELL=/bin/bash
MAKEFLAGS += --silent
image_name = pyspark_base

all: clean build run

run:
	docker exec -it pyspark-container_spark-master_1 bash -c "\
	/opt/spark/bin/spark-submit \
		--master spark://spark-master:7077  \
		/opt/spark-apps/main.py  100"

build:
	# Add application files to path
	sudo cp main.py apps/

	# Builds cluster for running spark application
	docker-compose up -d --build --scale spark-worker=2

clean:
	sudo rm -rf apps/* data/*
	# Delete image from docker and clear running containers for the image
	docker-compose down --remove-orphans || true
	docker rm -f $(docker ps -a -q) || true
	docker volume rm $(docker volume ls -q) || true

build-image:
	docker build -t $(image_name) .
	docker run -it pyspark_base bash -c "\
		/bin/bash /start-spark.sh; \
		./bin/spark-submit \
		--master spark://spark-master:7077 \
		examples/src/main/python/pi.py 1000
	"
	