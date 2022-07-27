# Build order:

make + 
* l4t_assets
* web
* frigate-wheels
* l4t_wheels
* l4t_frigate

several of these will require more available memory than the 4GB jetson nano has. add swap-space. (google for instructions)

## l4t_assets
this convers the yolov4 models to something tensorrt can understand.

## web
this builds the website.

## frigate-wheels
this pulls the various dependencies for frigate

## l4t_wheels
this builds the python bindings for tensorrt.

## l4t_frigate
this builds the final image by combining all of the previous and the pre-built ffmpeg image (cptnalf/jetson-ffmpeg)

if you're using gstreamer, you can comment out the ffmpeg image pull and ffmpeg copy.
