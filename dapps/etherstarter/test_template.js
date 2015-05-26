/*var web3 = require ('ethereum.js');
web3.setProvider(new web3.providers.HttpProvider('http://localhost:3000'));*/

var source = SOLIDITY

var contracts = eth.compile.solidity (source)

var EtherStarter = web3.eth.contract (contracts.EtherStarter.info.abiDefinition)
var MetaStarter = web3.eth.contract (contracts.MetaStarter.info.abiDefinition)
var MetaStarterBackend = web3.eth.contract (contracts.MetaStarterBackend.info.abiDefinition)

/* TEST1 (init - create campaign - contribute - contribute_finish)

var b200 = eth.getBalance (200)

var metastarter = MetaStarter.new ({from: eth.coinbase, gas: 2000000, data: contracts.MetaStarter.code})
var etherstarter = EtherStarter.new (metastarter.address, 0xdeadbeef, {from: eth.coinbase, gas: 2000000, data: contracts.EtherStarter.code})

etherstarter.create_campaign(200, 1000, 1451606400, 0, 0, 0, {from: eth.coinbase, gas:0xfffff, value:10*eth.gasPrice})

admin.miner.start()

sleep (3)

id = metastarter.iterator_prev (0)

console.log('id = ' + id)

etherstarter.contribute (id, {from: eth.coinbase, gas: 300000, value: 100})

etherstarter.contribute (id, {from: eth.coinbase, gas: 300000, value: 1000})

sleep (3)

admin.miner.stop()

sleep (1)

var diff = eth.getBalance (200) - b200

console.log (diff + '== 1100')

/*

loadScript('~/Checkout/ethereum-vienna/dapps/etherstarter/test.js')

*/

// ./geth --unlock primary --rpc --rpccorsdomain "*" --rpcport 3000 --vmdebug --loglevel 4 console
