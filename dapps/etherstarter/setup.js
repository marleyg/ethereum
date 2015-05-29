admin.addPeer('enode://17a6997e009b8eef778e87ce69a38e0992fd679e257bef2815197c4cc7b76f008367d0e3aae57ee7243e094022a82dee353f5861c2741a6c419c112d463b99be@162.213.197.174:30303')

loadScript('utils.js')
loadScript('whisper-swarm.js')

admin.unlock (eth.coinbase, "password")

var etherstarter = null
var metastarter = null

metastarter = MetaStarter.new ({from: eth.coinbase, gas: 2000000, data: contracts.MetaStarter.code})
etherstarter = EtherStarter.new (metastarter.address, 0xdeadbeef, {from: eth.coinbase, gas: 2000000, data: contracts.EtherStarter.code})

admin.miner.start (1)

function split_identity (shh_identity) {
	var shh_identity_n = new BigNumber(shh_identity.substring(4), 16)
    var lsb = shh_identity_n.modulo(new BigNumber(2).toPower(256))
    var msb = shh_identity_n.minus(lsb).dividedBy(new BigNumber(2).toPower(256))

    return [ lsb, msb ]
}

function reconstruct_identity (lsb, msb) {
	return "0x04" + msb.times(new BigNumber(2).toPower(256)).plus(lsb).toString(16)
}

waitForContractCreation(metastarter).then (waitForContractCreation(etherstarter)).then (function () {

	var campaign_info = {
		title: "My first campaign!",
		description: "I need more ether to affort the gas cost for further campaigns!"
	}

	var desc_hash = web3.sha3 (JSON.stringify (campaign_info))

	mzz_announce_data (JSON.stringify (campaign_info))

	var shh_identity = shh.newIdentity()

	var lsb = split_identity (shh_identity) [0]
	var msb = split_identity (shh_identity) [1]

	return waitForContractTransaction (etherstarter.create_campaign, eth.coinbase, web3.toWei(1.77, "ether"), 1451606400, lsb, msb, desc_hash, {from: eth.coinbase, gas:0xfffff, value:10*eth.gasPrice})
}).then (function () {

	var campaign_info = {
		title: "Museum of Science Fiction: \"Future of Travel\" Exhibition",
		description: "This summer, the Museum of Science Fiction in Washington, DC will open the 'Future of Travel' exhibition at Reagan National Airport beginning on July 7, 2015.\n\nAs planned, the four-month exhibition will feature a large-scale Orion III spaceplane from 2001: A Space Odyssey, retro-futuristic travel posters by artist Steve Thomas, and a companion mobile app that will provide visitors with exhibit information, an interstellar passport, and their own 'boarding pass to the future.'\n\nThe mobile app will have an “Expedia-style” Plan-Your-Visit section to generate a simulated boarding pass that can be emailed to the traveler. The traveler could select a destination: the Moon, Alpha Centauri, or Mars – Climb Olympus Mons! Hike the Mars Rover trails! Stay in floating hotels! Remember your sunscreen! Travel to the Moon – Best view of the Earth! Visit the first moon landing monument!\n"
	}

	var desc_hash = web3.sha3 (JSON.stringify (campaign_info))

	mzz_announce_data (JSON.stringify (campaign_info))

	var shh_identity = shh.newIdentity()

	var lsb = split_identity (shh_identity) [0]
	var msb = split_identity (shh_identity) [1]

	return waitForContractTransaction (etherstarter.create_campaign, eth.accounts[1], web3.toWei(0.5, "ether"), 1551606400, lsb, msb, desc_hash, {from: eth.coinbase, gas:0xfffff, value:10*eth.gasPrice})
}).then (function () {
	admin.miner.stop ()
	console.log ("Test contracts deployed (meta: " + metastarter.address + ", ether: " + etherstarter.address + ")")
}, function (err) {
	console.log ("Error: " + err)
})