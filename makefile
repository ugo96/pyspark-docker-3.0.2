SHELL=/bin/bash
MAKEFLAGS += --silent
image_name = pyspark_base

all: clean raw-data-prep test build run

run:
	docker exec -it pyspark-container_spark-master_1 bash -c "\
	bin/spark-submit \
		--master spark://spark-master:7077  \
		--py-files app/jobs.zip,app/shared.zip,app/libs.zip \
		--files app/config.json \
		app/main.py --job movies \
		"
	docker exec -it pyspark-container_spark-master_1 bash -c "\
	bin/spark-submit \
		--master spark://spark-master:7077  \
		--py-files app/jobs.zip,app/shared.zip,app/libs.zip \
		--files app/config.json \
		app/main.py --job movie_genres \
		"

test:
	cd pipeline && python -m pytest tests

build:
	# Copy data 
	sudo cp -R dataset/* data/ | true

	# Compile Job
	mkdir ./dist | true
	cp pipeline/main.py ./dist
	cp pipeline/config.json ./dist
	cd pipeline && \
		sudo zip -r ../dist/jobs.zip jobs \
		sudo zip -r ../dist/shared.zip shared && \
		cd ..
	docker run --rm -v $(PWD):/foo -w /foo lambci/lambda:build-python3.7 \
		pip install -r pipeline/requirements.txt -t ./dist/libs
	cd ./dist/libs && sudo zip -r -D ../libs.zip .

	# Build cluster for running spark application
	docker-compose up -d --build --scale spark-worker=2

clean:
	sudo rm -rf dataset/* dist/* apps/* data/* 

	# Delete image from docker and clear running containers for the image
	docker-compose down --remove-orphans || true
	# docker rm -f $(docker ps -a -q) || true
	# docker volume rm $(docker volume ls -q) || true

raw-data-prep:
	python get_data.py

build-image:
	docker build -t $(image_name) .
	docker run -it pyspark_base bash -c "\
		/bin/bash /start-spark.sh; \
		./bin/spark-submit \
		--master spark://spark-master:7077 \
		examples/src/main/python/pi.py 1000
	"
