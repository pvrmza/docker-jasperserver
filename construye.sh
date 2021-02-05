#!/bin/bash

# el nombre de la imagen va a ser el nombre del directorio actual si no se especifica
if test -z $1; then
	IMAGE=`basename $(pwd)`
else
	IMAGE=$1
fi

TAG=devel

#docker image rm $IMAGE:$TAG

echo "construyendo $IMAGE con tag $TAG"
docker build --rm -t $IMAGE:$TAG .

docker image ls | egrep $IMAGE
