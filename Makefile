default_target: frigate

COMMIT_HASH := $(shell git log -1 --pretty=format:"%h"|tail -1)
FRIGATE_VERSION := '0.11'

version:
	echo "VERSION='0.11.0-$(COMMIT_HASH)'" > frigate/version.py

nginx_frigate:
	docker buildx build --push --platform linux/arm/v7,linux/arm64/v8,linux/amd64 --tag blakeblackshear/frigate-nginx:1.0.2 --file docker/Dockerfile.nginx .

l4t_assets: .l4t_assets/yolov4-tiny-416.trt .l4t_assets/yolov4-tiny-288.trt .l4t_assets/libyolo_layer.so
	mkdir -p $$(pwd)/.l4t_assets
	cp ./converters/yolo4/plugin/* .l4t_assets/
	cp ./converters/yolo4/model/yolov4-tiny-416.trt .l4t_assets/yolov4-tiny-416.trt
	cp ./converters/yolo4/model/yolov4-tiny-288.trt .l4t_assets/yolov4-tiny-288.trt
	# cp ./converters/yolo4/model/yolov4-416.trt .l4t_assets/yolov4-416.trt
	# cp ./converters/yolo4/model/yolov4-288.trt .l4t_assets/yolov4-288.trt

l4t_wheels: docker/Dockerfile.wheels.l4t
	@docker build --tag frigate-wheels-l4t --file docker/Dockerfile.wheels.l4t .
	# Run l4t wheels using nvidia runtime
	@docker rm frigate.wheels.l4t || true
	@docker run --name frigate.wheels.l4t -it --runtime=nvidia -e NVIDIA_VISIBLE_DEVICES=all -e NVIDIA_DRIVER_CAPABILITIES=compute,utility,video --privileged frigate-wheels-l4t
	# Commit changes to the container
	@CONTAINER_ID=`docker ps -n 1 --format "{{.ID}}"`
	@docker commit $$CONTAINER_ID frigate.wheels.l4t frigate-wheels-l4t:$(FRIGATE_VERSION)
	@docker rm frigate.wheels.l4t || true

web: docker/Dockerfile.web
	@DOCKER_BUILDKIT=1 docker build --progress=plain --tag frigate-web:$(FRIGATE_VERSION) --file docker/Dockerfile.web .

frigate-wheels: docker/Dockerfile.frigate
	@DOCKER_BUILTKIT=1 docker build --tag frigate-wheels:$(FRIGATE_VERSION) --file docker/Dockerfile.frigate .

docker/Dockerfile.l4t:
	@cat docker/Dockerfile | sed "s|#use_l4t: ||g" > docker/Dockerfile.l4t

web.built:
	@docker image inspect -f "h" frigate-web:$(FRIGATE_VERSION) > /dev/null

frigate.built:
	@docker image inspect -f "h" frigate-wheels:$(FRIGATE_VERSION) >/dev/null

l4t_wheels.built:
	@docker image inspect -f "h" frigate-wheels-l4t:$(FRIGATE_VERSION) >/dev/null

l4t_frigate: l4t_wheels.built l4t_assets docker/Dockerfile.l4t web.built frigate.built
	DOCKER_BUILDKIT=1 docker build --progress=plain -t frigate.l4t:$(FRIGATE_VERSION) --build-arg FRIGATE_BASE_IMAGE=cptnalf/jetson-ubuntu-opencv:4.5.0-r32.7.1 --build-arg FRIGATE_VERSION=$(FRIGATE_VERSION) -f docker/Dockerfile.l4t .

frigate: version
	DOCKER_BUILDKIT=1 docker build --progress=plain -t frigate -f docker/Dockerfile .

frigate_push: version
	docker buildx build --push --platform linux/arm64/v8,linux/amd64 --tag blakeblackshear/frigate:0.11.0-$(COMMIT_HASH) --file docker/Dockerfile .

.PHONY: run_tests l4t_frigate l4t_wheels web.built frigate.built l4t_wheels.built
