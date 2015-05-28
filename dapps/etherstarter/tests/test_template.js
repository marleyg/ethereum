/*var web3 = require ('ethereum.js');
web3.setProvider(new web3.providers.HttpProvider('http://localhost:3000'));*/

loadScript("../dist/es6-promise.js")

var source = SOLIDITY

var contracts = eth.compile.solidity (source)

var EtherStarter = web3.eth.contract (contracts.EtherStarter.info.abiDefinition)
var MetaStarter = web3.eth.contract (contracts.MetaStarter.info.abiDefinition)
var MetaStarterBackend = web3.eth.contract (contracts.MetaStarterBackend.info.abiDefinition)

function waitForConditionInBlock (testFunc, maxBlocks) {
	return new Promise (function(fulfill, reject) {

		if (typeof(maxBlocks) === 'undefined') maxBlocks = 5

		if (testFunc ()) {
			fulfill ()
			return
		}

		var lastBlock = eth.blockNumber + maxBlocks

		var filter = eth.filter ('latest')

		filter.watch (function () {			
			if (testFunc ()) {
				filter.stopWatching ()
				fulfill ()
				return
			}

			if (eth.blockNumber > lastBlock) {
				filter.stopWatching ()
				reject ("Condition not met after " + maxBlocks + " blocks")
				return
			}
		})
	})
}

function waitForTransaction (txHash) {
	return waitForConditionInBlock (function () {
		var tx = eth.getTransaction (txHash)		
		if (tx.blockNumber == 0) return false
		if (eth.getBlock (tx.blockNumber) == null) return false
		if (eth.pendingTransactions().length != 0) return false
		return tx.blockHash == eth.getBlock (tx.blockNumber).hash
	})
}

function waitForContractCreation (contract) {
	return waitForConditionInBlock (function () {
		return eth.getCode (contract.address) != "0x"
	})
}

function waitForContractTransaction (func) {
	var args = Array.prototype.slice.call(arguments, 1);
	return waitForTransaction (eth.sendTransaction (func.request.apply(this, args).payload))
}

function waitForBalance (address, minBalance, maxBlocks) {
	return waitForConditionInBlock (function () {
		return (eth.getBalance(address) >= minBalance)
	}, maxBlocks)
}

admin.unlock (eth.accounts[0], 'password')
admin.unlock (eth.accounts[1], 'password')


function test_1 () {

	return new Promise ( function (fulfill, reject) {
		admin.debug.setHead(0)
		admin.import ('chain.dat')
		admin.miner.start (1)
		
		var etherstarter = null
		var metastarter = null


		waitForBalance(eth.coinbase, 40000000000000000000, 40).then(function () {
			metastarter = MetaStarter.new ({from: eth.coinbase, gas: 2000000, data: contracts.MetaStarter.code})
			etherstarter = EtherStarter.new (metastarter.address, 0xdeadbeef, {from: eth.coinbase, gas: 2000000, data: contracts.EtherStarter.code})		
			return waitForContractCreation(metastarter)
		}).then(function () {
			return waitForContractCreation(etherstarter)
		}).then (function () {
			return waitForContractTransaction (etherstarter.create_campaign, 200, 1000, 1451606400, 0, 0, 0, {from: eth.coinbase, gas:0xfffff, value:10*eth.gasPrice})
		}).then(function(){
			var id = metastarter.iterator_prev (0)
			if (etherstarter.get_recipient (id) != 200) return Promise.reject ("Wrong recipient " + etherstarter.get_recipient(id))
			if (etherstarter.get_goal_fixed (id) != 1000) return Promise.reject ("Wrong goal " + etherstarter.get_recipient(id))
			if (etherstarter.get_deadline (id) != 1451606400) return Promise.reject ("Wrong deadline " + etherstarter.get_deadline(id))
			if (metastarter.get_campaign_status (id) != 1) return Promise.reject ("Wrong status " + metastarter.get_campaign_status(id))
			if (etherstarter.get_progress (id) != 0) return Promise.reject ("Wrong progress " + etherstarter.get_progress(id))
			return waitForContractTransaction (etherstarter.contribute, id, {from: eth.coinbase, gas: 300000, value: 100})	
		}).then (function () {
			var id = metastarter.iterator_prev (0)
			if (etherstarter.get_progress (id) != 100) return Promise.reject ("Wrong progress " + etherstarter.get_progress(id))		
			return waitForContractTransaction (etherstarter.contribute, id, {from: eth.coinbase, gas: 300000, value: 1000})	
		}).then (function () {
			var id = metastarter.iterator_prev (0)
			if (etherstarter.get_progress (id) != 1100) return Promise.reject ("Wrong progress " + etherstarter.get_progress(id))
			if (metastarter.get_campaign_status (id) != 3) return Promise.reject ("Wrong status " + metastarter.get_campaign_status(id))
			if (eth.getBalance (200) != 1100) return Promise.reject ("Invalid balance for account 200")	
			if (eth.getBalance (etherstarter.address) != 0) return Promise.reject ("EtherStarter balance == " + eth.getBalance(etherstarter.address) + " (should be 0)")
			if (eth.getBalance (metastarter.address) != 10*eth.gasPrice) return Promise.reject ("MetaStarter balance == " + eth.getBalance(metastarter.address) + " (should be "+10*eth.gasPrice+")")
			admin.miner.stop ()
		}).then (fulfill, reject)

	})
}

function test_2 () {
	return new Promise ( function (fulfill, reject) {
		admin.debug.setHead(0)
		admin.import ('chain.dat')
		admin.miner.start (1)

		var etherstarter = null
		var metastarter = null


		var deadline = 0
		var id = 0

		waitForBalance(eth.coinbase, 40000000000000000000, 40).then(function (){
			metastarter = MetaStarter.new ({from: eth.coinbase, gas: 2000000, data: contracts.MetaStarter.code})
			etherstarter = EtherStarter.new (metastarter.address, 0xdeadbeef, {from: eth.coinbase, gas: 2000000, data: contracts.EtherStarter.code})		
			return waitForContractCreation(metastarter)
		}).then(function () {
			return waitForContractCreation(etherstarter)
		}).then(function () {
			deadline = Math.floor(new Date().getTime()/1000) + 20
			return waitForContractTransaction (etherstarter.create_campaign, 200, 1000, deadline, 0, 0, 0, {from: eth.coinbase, gas:0xfffff, value:10*eth.gasPrice})
		}).then(function(){
			id = metastarter.iterator_prev (0)
			if (etherstarter.get_recipient (id) != 200) return Promise.reject ("Wrong recipient " + etherstarter.get_recipient(id))
			if (etherstarter.get_goal_fixed (id).comparedTo(1000) != 0) return Promise.reject ("Wrong goal " + etherstarter.get_recipient(id))
			if (etherstarter.get_deadline (id).comparedTo(deadline) != 0) return Promise.reject ("Wrong deadline " + etherstarter.get_deadline(id))
			if (metastarter.get_campaign_status (id) != 1) return Promise.reject ("Wrong status " + metastarter.get_campaign_status(id))
			if (etherstarter.get_progress(id).comparedTo(0) != 0) return Promise.reject ("Wrong progress " + etherstarter.get_progress(id) + " (should be 0)")
			return waitForContractTransaction (etherstarter.contribute, id, {from: eth.accounts[0], gas: 300000, value: 500})
		}).then(function(){		
			if (etherstarter.get_progress(id).comparedTo(500) != 0) return Promise.reject ("Wrong progress " + etherstarter.get_progress(id) + " (should be 500)")
			return waitForContractTransaction (etherstarter.contribute, id, {from: eth.accounts[1], gas: 300000, value: 200})
		}).then(function(){
			if (etherstarter.get_progress(id).comparedTo(700) != 0) return Promise.reject ("Wrong progress " + etherstarter.get_progress(id) + " (should be 700)")
			return waitForConditionInBlock (function () {
				return (eth.getBlock(eth.blockNumber).timestamp > deadline + 15)
			}, 100)
		}).then(function(){
			return waitForContractTransaction (etherstarter.contribute, id, {from: eth.accounts[0], gas: 600000, value: 300})
		}).then(function(){
			if (etherstarter.get_progress(id).comparedTo (700) != 0) return Promise.reject ("Wrong progress " + etherstarter.get_progress(id))
			if (metastarter.iterator_prev(0).comparedTo (0) != 0) return Promise.reject ("Campaign in wrong list ")
			if (metastarter.iterator_next(0).comparedTo(id) != 0) return Promise.reject ("Campaign not in right list ")		
			if (metastarter.get_campaign_status (id) != 5) return Promise.reject ("Wrong status " + metastarter.get_campaign_status(id))
			if (eth.getBalance (etherstarter.address) != 0) return Promise.reject ("EtherStarter balance == " + eth.getBalance(etherstarter.address) + " (should be 0)")
			if (eth.getBalance (metastarter.address) != 0) return Promise.reject ("MetaStarter balance == " + eth.getBalance(metastarter.address) + " (should be 0)")
		}).then (fulfill, reject)

	})
}

function test_3 () {

	return new Promise (function (fulfill, reject) {
		admin.debug.setHead(0)
		admin.import ('chain.dat')
		admin.miner.start (1)

		var etherstarter = null
		var metastarter = null

		var deadline = 0
		var id = 0

		waitForBalance(eth.coinbase, 40000000000000000000, 40).then(function () {
			metastarter = MetaStarter.new ({from: eth.coinbase, gas: 2000000, data: contracts.MetaStarter.code})
			etherstarter = EtherStarter.new (metastarter.address, 0xdeadbeef, {from: eth.coinbase, gas: 2000000, data: contracts.EtherStarter.code})		
			return waitForContractCreation(metastarter)
		}).then(function () {
			return waitForContractCreation(etherstarter)
		}).then (function () {
			return waitForContractTransaction (etherstarter.create_campaign, 200, 1000, 1451606400, 0, 0, 0, {from: eth.coinbase, gas:0xfffff, value:10*eth.gasPrice})
		}).then(function(){
			var id = metastarter.iterator_prev (0)
			if (etherstarter.get_recipient (id) != 200) return Promise.reject ("Wrong recipient " + etherstarter.get_recipient(id))
			if (etherstarter.get_goal_fixed (id) != 1000) return Promise.reject ("Wrong goal " + etherstarter.get_recipient(id))
			if (etherstarter.get_deadline (id) != 1451606400) return Promise.reject ("Wrong deadline " + etherstarter.get_deadline(id))
			if (metastarter.get_campaign_status (id) != 1) return Promise.reject ("Wrong status " + metastarter.get_campaign_status(id))
			if (etherstarter.get_progress (id) != 0) return Promise.reject ("Wrong progress " + etherstarter.get_progress(id))
			return waitForContractTransaction (etherstarter.create_campaign, 200, 1000, 1451606400, 1, 0, 0, {from: eth.coinbase, gas:0xfffff, value:10*eth.gasPrice})
		}).then (function () {
			var id = metastarter.iterator_prev (0)
			if (id == 0) return Promise.reject ("No campaign created")
			if (metastarter.iterator_prev (id) == 0) return Promise.reject ("Only one campaign created")		
		}).then (fulfill, reject)

	})
}

tests = [
{
	title: "Test 1",
	func: test_1
},{
	title: "Test 2",
	func: test_2
},{
	title: "Test 3",
	func: test_3
}]

var promise = new Promise (function (fulfill, reject) {
	fulfill ()
})

for (var i = 0, len = tests.length; i < len; i++) {
	var test = tests[i]

	var x = (function (j) { 
		promise = promise.then (j.func).then (function (){		
			console.log (j.title + " PASSED")
		}, function (err) {
			console.log (j.title + " FAILED " + err)
		})
	}) (test)

}
