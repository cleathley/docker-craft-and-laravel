#!/usr/bin/env bash
ip=`ipconfig | grep 'IPv4 Address' | grep '10.42' | cut -d ':' -f 2 | sed -e 's/^[[:space:]]*//'`
docker build --tag slave .
echo
echo "******************************************************************************************"
echo
echo " * Your website is available at (you will have to allow the self signed SSL certificate)"
echo
echo " https://localhost"
echo
echo " * If you wish to ssh into your docker instance (must be done in another terminal window)"
echo
echo " winpty docker exec -it slave bash"
echo
echo " * To view the website on a mobile device (must be within the office)"
echo
echo " https://$ip or https://`hostname`"
echo
echo "******************************************************************************************"
echo
docker run --rm -p 81:80 -p 443:443 -v /`PWD`:/web --name slave --cap-add SYS_ADMIN -h slave slave:latest
echo -n "Stopping "
docker container stop slave
