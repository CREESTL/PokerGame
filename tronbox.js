module.exports = {
  networks: {
    development: {
      privateKey: 'da146374a75310b9666e834ee4ad0866d6f4035967bfc76217c5a495fff9f0d0',
      fullHost: "http://127.0.0.1:9090",
      network_id: "*",
      consume_user_resource_percent: 30,
      feeLimit: 1e9,
      originEnergyLimit: 1e7
    },
    shasta: {
      privateKey: '',
      // userFeePercentage: 50,
      feeLimit: 1e9,
      fullHost: 'https://api.shasta.trongrid.io',
      network_id: '3'
    },
    compilers: {
      solc: {
        version: '0.5.4'
      }
    }
  }
}
