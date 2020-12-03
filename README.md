Poker Contract
=================

**Installation**

`yarn install`


**To run your node with 10 address in TRON
Install docker**

- `docker pull trontools/quickstart`

- `docker run -it -p 9090:9090 --rm --name tron trontools/quickstart`


**To compile contracts**

`tronbox compile`

**To deploy contracts**

`tronbox migrate`

**To compile and deploy contracts**
`yarn rebuild`

**To run tests**

`tronbox test <filename>`

or

`yarn test <filename>`