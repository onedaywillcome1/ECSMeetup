#!/bin/bash

gradle build

find build/libs/ -type f \( -name "*.jar" -not -name "*sources.jar" \) -exec cp {} deploy/app.jar \;

login=$(aws ecr get-login --region us-east-1)
login=`echo $login | cut -d " " -f1,2,3,4,5,6,9`
eval $login

cd deploy

docker build -t meetuphelloworld -f meetup.dockerfile .

docker tag meetuphelloworld:latest 603826100439.dkr.ecr.us-east-1.amazonaws.com/meetuphelloworld:latest

docker push 603826100439.dkr.ecr.us-east-1.amazonaws.com/meetuphelloworld:latest


