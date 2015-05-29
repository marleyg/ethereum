loadScript("dist/es6-promise.js")

web3.shh.filter ({topics : ["metastarter", "request-data"]}).watch (function (err, msg) {
	if (err) {
		console.log (err)
		return
	}

	var request = msg.payload

	if (web3.db.getString('metastarter-ws', request.hash) != '') {
		mzz_announce_data (web3.db.getString('metastarter-ws', request.hash))
	}
})

var filter = web3.shh.filter ({topics : ["metastarter", "announce-data"]})

filter.watch (function (err, msg) {

	if (err) {
		console.log (err)
		return
	}

	if (web3.sha3 (msg.payload.data) == msg.payload.hash) {
		web3.db.putString ('metastarter-ws', msg.payload.hash, msg.payload.data)
	}

})

function mzz_request_data (hash) {

	return new Promise (function (fulfill, reject) {
		
		if (web3.db.getString('metastarter-ws', hash) != '') {
			fulfill (web3.db.getString('metastarter-ws', hash))
			return
		}

		var filter = web3.shh.filter ({topics : ["metastarter", "announce-data"]})

		filter.watch (function (err, msg) {

			if (err) {
				console.log (err)
				return
			}

			if (web3.sha3 (msg.payload.data) == hash) {
				web3.db.putString ('metastarter-ws', msg.payload.hash, msg.payload.data)
				fulfill (msg.payload.data)
				filter.stopWatching ()
			}

		})

		web3.shh.post ({topics : ["metastarter", "request-data"], payload: {hash: hash} })

	})
}

function mzz_announce_data (data) {
	var payload = {
		hash: web3.sha3 (data),
		data: data
	}

	web3.db.putString ('metastarter-ws', payload.hash, data)

	web3.shh.post ({topics : ["metastarter", "announce-data"], payload: payload})
}