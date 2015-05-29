loadScript("dist/es6-promise.js")

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