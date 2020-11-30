const TronWeb = require('tronweb');
const tronweb = new TronWeb( {
    privateKey: 'da146374a75310b9666e834ee4ad0866d6f4035967bfc76217c5a495fff9f0d0',
    fullHost: "http://127.0.0.1:9090",
  }
)

const getHexAddress = (address) => {
  return tronweb.address.toHex(address);
}

const trxSender = async(to, amount, from) => {
  const tradeobj = await tronWeb.transactionBuilder.sendTrx(to, amount, from);
  const signedtxn = await tronWeb.trx.sign(tradeobj, 'a9cc85c5361970ff612d1b11883e81150819b1f1e6e85914e9217053de12e211');
  const receipt = await tronWeb.trx.sendRawTransaction(signedtxn);
  return console.log('- Output:', receipt, '\n');
}

const simpleExpectRevert = async(promise, descr) => {
  try {
    await promise();
    throw null;
  } catch (e) {
    return console.log(`REVERT: ${descr}`);
  }
}

// const simpleExpectEventTransaction = (contr, to, amount, from) => {
//   console.log(contr, to, amount, from, 'EVENT CHECKER DATA')
//   contr.deployed()
//     .then(meta => {
//       return tronWeb.contract().at(meta.address)
//         .then(meta2 => {
//             meta2.Transfer().watch((err, res) => {
//               if(res) {
//                 assert.equal(res.result._from, tronWeb.address.getHexAddress(from))
//                 assert.equal(res.result._to, tronWeb.address.getHexAddress(to))
//                 assert.equal(res.result._value, amount)
//                 done()
//               }
//             })

//         meta.trxSender(to, amount, from);
//       })
//     })
// }
module.exports = {
    getHexAddress,
    trxSender,
    simpleExpectRevert,
    tronweb,
    // simpleExpectEventTransaction
}