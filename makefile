SHELL=/bin/bash
image_name = pyspark_base

run: build
	# Run application from entry point using main.py
	@echo "Done Building"


test: build
	# Run tests for application

clean:
	# Delete image from docker and clear running containers for the image
	docker-compose down --remove-orphans

build: 
	# Builds package and image for use
	docker-compose up -d --build --scale worker=4
