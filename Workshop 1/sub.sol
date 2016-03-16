contract Subscription {
    
    bool active;
    uint nextPayment;
    uint price;
    uint time;
    address recipient;
    address creator;
    
    event FailedToPay();
    event Paid();
    event Cancelled();
    
    function Subscription(address recipient_, uint price_, uint time_) {
        nextPayment = block.timestamp;
        price = price_;
        time = time_;
        recipient = recipient_;
        active = true;
        creator = msg.sender;
    }
    
    modifier require_active () { if(active) { _ } }
    
    function withdraw() require_active {
        if(block.timestamp >= nextPayment) {
            if(this.balance < price) {
                FailedToPay();
            } else {
                nextPayment += time;
                recipient.send(price);
                Paid();
            }
        } else {
            log0("too soon");
        }
    }
    
    function cancel() require_active {
        if(block.timestamp < nextPayment) {
            active = false;
            creator.send(this.balance);
            Cancelled();
        }
    }
    
}

