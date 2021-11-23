SHELL=/bin/bash
MAKEFLAGS += --silent
image_name = pyspark_base

all: clean raw-data-prep build test run

run:
	docker exec -it pyspark-container_spark-master_1 bash -c "\
	/opt/spark/bin/spark-submit \
		--master spark://spark-master:7077  \
		--py-files /opt/spark-apps/jobs.zip, /opt/spark-apps/shared.zip, /opt/spark-apps/libs.zip \
		--files /opt/spark-apps/config.json \
		/opt/spark-apps/main.py --job movies \
		"

test:
	cd pipeline && python -m pytest tests

build:
	# Copy data 
	sudo cp -R dataset/* data/

	# Compile Job
	mkdir ./dist
	cp ./main.py ./dist
	cp ./config.json ./dist
	zip -r dist/jobs.zip jobs
	zip -r dist/shared.zip shared
	docker run --rm -v $(PWD):/foo -w /foo lambci/lambda:build-python3.7 \
		pip install -r requirements-libs.txt -t ./dist/libs
	cd ./dist/libs && zip -r -D ../libs.zip .

	# Build cluster for running spark application
	docker-compose up -d --build --scale spark-worker=2

clean:
	sudo rm -rf dataset/* dist/* apps/* data/* 
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

raw-data-prep:
	python get_data.py