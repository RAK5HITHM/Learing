#!/bin/bash
echo -e "\nThis Script is used to install MangoDB\xF0\x9F\x8D\x83\xF0\x9F\x8D\x83 5.0/6.0/7.0\n"

#Making sure the user enters vaild values
while true; do
    read -p "Enter which version of MangoDB to install out of 5.0, 6.0 or 7.0 versions: " version

    if [[ $version == 5 || $version == 6 || $version == 7 || $version == 5.0 || $version == 6.0 || $version == 7.0 ]]; then
        break  # Exit the loop if the input is valid
    else
        echo "Invalid input. Please enter 5.0, 6.0, or 7.0"
    fi
done


# Check if the number does not contain a decimal point and append .0 to the version
if ! [[ $version =~ \. ]]; then
    version="$version.0" 
fi
# Checking if the MangoDB is previously installed or not 
if yum list installed | grep -q mongodb-org-${version}; then
    echo -e "MongoDB\xF0\x9F\x8D\x83${version} is already installed."
    exit
fi


echo -e "\nMangoDB ${version}\xF0\x9F\x8D\x83 is installing...."

sudo bash -c "cat <<EOF > /etc/yum.repos.d/mongodb-org-${version}.repo
[mongodb-org-${version}]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/9/mongodb-org/${version}/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/${version}.asc
EOF"

sudo yum install -y mongodb-org
error=$?
# Checking if the MangoDB is installed or not

if [ $error != 0 ]; then
	echo -e "Installation of MangoDB\xF0\x9F\x8D\x83 $version failed with below error\n$error"
 	exit
fi   

sudo mkdir -p /data/db1 /data/db2 /data/db3_arbiter

echo -e "\nStarting 3 instances Mangodb\xF0\x9F\x8D\x83 in the localhost"

mongod --replSet rs0 \
       --port 27017 \
       --dbpath /data/db1 \
       --wiredTigerCacheSizeGB 1 \
       --authenticationDatabase "admin" \
       --username "admin" \
       --password "passW0rd" \
       --fork

mongod --replSet rs0 \
       --port 27018 \
       --dbpath /data/db2 \
       --wiredTigerCacheSizeGB 1 \
       --authenticationDatabase "admin" \
       --username "admin" \
       --password "passW0rd" \
       --fork

mongod --replSet rs0 \
       --port 27019 \
       --dbpath /data/db3_arbiter \
       --wiredTigerCacheSizeGB 1\
       --authenticationDatabase "admin" \
       --username "admin" \
       --password "passW0rd" \
       --arbiterOnly \
       --fork

echo "Initialize replica set configuration"
mongo --port 27017 -u admin -p passW0rd --authenticationDatabase admin <<EOF
rs.initiate({
    _id: "rs0",
    members: [
        { _id: 0, host: "localhost:27017" },
        { _id: 1, host: "localhost:27018" },
        { _id: 2, host: "localhost:27019", arbiterOnly: true }
    ]
})
EOF
