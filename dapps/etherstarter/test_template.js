var web3 = require ('ethereum.js');
web3.setProvider(new web3.providers.HttpProvider('http://localhost:3000/client'));

metastarter_bin = "METASTARTER.BINARY"

etherstarter_bin= "ETHERSTARTER.BINARY"

metastarter_abi = METASTARTER.ABI

metastarter_backend_abi = METASTARTERBACKEND.ABI

etherstarter_abi = ETHERSTARTER.ABI

var eth = web3.eth

web3.eth.filter('latest').watch (function () {
	console.log ('block')
})

/* metastarter deploy */

web3.eth.sendTransaction({from: eth.coinbase, code: metastarter_bin, gas: 1000000}, function (err, metastarter_address) {
	if (err) console.log (err)
	console.log ('deployed? ' + metastarter_address)
});

console.log (eth.getBalance(eth.coinbase) / eth.gasPrice)
