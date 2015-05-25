var web3 = require ('ethereum.js');
web3.setProvider(new web3.providers.HttpProvider('http://localhost:3000'));

metastarter_bin = "METASTARTER.BINARY"

etherstarter_bin= "ETHERSTARTER.BINARY"

metastarter_abi = METASTARTER.ABI

metastarter_backend_abi = METASTARTERBACKEND.ABI

etherstarter_abi = ETHERSTARTER.ABI

var eth = web3.eth

web3.eth.filter('latest').watch (function () {
	console.log ('block')
})

console.log (eth.coinbase + ": "+ eth.getBalance(eth.coinbase))
console.log ("can afford " + eth.getBalance(eth.coinbase) / eth.gasPrice + " gas @" + eth.gasPrice)
console.log ("blocklimit " + eth.getBlock(eth.blockNumber).gasLimit)

/* metastarter deploy */

var meta_addr = 0;
var ether_addr = 0;

web3.eth.sendTransaction({from: eth.coinbase, code: metastarter_bin, gas: 1000000}, function (err, metastarter_address) {
	if (err) console.log (err)
	meta_addr = metastarter_address
	console.log ('ms deployed? ' + metastarter_address)
});

web3.eth.sendTransaction({from: eth.coinbase, code: etherstarter_bin, gas: 1000000}, function (err, etherstarter_address) {
	if (err) console.log (err)
	ether_addr = etherstarter_address
	console.log ('es deployed? ' + etherstarter_address)
});

var MetaStarter = web3.eth.contract (metastarter_abi)
var EtherStarter = web3.eth.contract (etherstarter_abi)

var metastarter = MetaStarter.at (meta_addr)
var etherstarter = EtherStarter.at (ether_addr)


// ./geth --unlock primary --rpc --rpccorsdomain "*" --rpcport 3000 --vmdebug --loglevel 4 console
