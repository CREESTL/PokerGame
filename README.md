yarn install


To run your node with 10 address in TRON
Install docker


docker pull trontools/quickstart


docker run -it \
  -p 9090:9090 \
  --rm \
  --name tron \
  trontools/quickstart




tronbox compile
tronbox migrate

To run tests 
tronbox test