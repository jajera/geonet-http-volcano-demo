# Include commands that you would like to execute after the container is created
apt-get update -y

apt-get install -y curl git unzip

curl https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o awscliv2.zip

unzip awscliv2.zip
./aws/install
rm awscliv2.zip
rm -r aws/
