contract Store {
    
    enum Status { OFFERED, TAKEN, CONFIRMED}
    
    struct Offer {
        string product;
        uint price;
        Status status;
        address creator;
        address taker;
    }

    Offer[] public offers;
    
    function addOffer(string product_, uint price_) returns (uint) {
        var id = offers.length;
        offers.push(Offer({
            product: product_,
            price: price_,
            status: Status.OFFERED,
            creator: msg.sender,
            taker: 0
        }));
        return id;
    }
    
    function takeOffer(uint id) {
        var offer = offers[id];
        if(msg.value != offer.price) throw;
        if(offer.status != Status.OFFERED) throw;
        
        offer.status = Status.TAKEN;
        offer.taker = msg.sender;
    }
    
    function confirm(uint id) {
        var offer = offers[id];
        if(offer.status != Status.TAKEN) throw;
        if(msg.sender != offer.taker) throw;
        
        offer.status = Status.CONFIRMED;
        offer.creator.send(offer.price);
    }
    
}
