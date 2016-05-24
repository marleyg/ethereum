contract Subscription {
    
    /* indicates wether the subscription is still active */
    bool active;
    /* timestamp of the next not-yet-collected payment */
    uint nextPayment;
    /* amount of wei that needs to be paid for each time period */
    uint price;
    /* duration of a time period */
    uint time;
    /* recipient of the payments */
    address recipient;
    /* creator of the contract */
    address creator;
    
    /* event when there is not enough wei to collect */
    event FailedToPay();
    /* event when collecting was successful */
    event Paid();
    /* event when the subscription has been cancelled */
    event Cancelled();
    
    /// @dev constructor, called at deployment
    /// @param recipient_ recipient of the payments
    /// @param price_ amount of wei that needs to be paid for each time period
    /// @param time_ duration of a time period
    function Subscription(address recipient_, uint price_, uint time_) {
        /* set the fields passed as arguments */
        price = price_;
        time = time_;
        recipient = recipient_;
        /* the next payment is required immediately */
        nextPayment = block.timestamp;
        /* mark the subscription as active */
        active = true;
        /* store the creator */
        creator = msg.sender;
    }
    
    /* modifier for checking if the subscription is still active */
    modifier require_active () { if(active) { _ } else throw; }
    
    /// @dev send one payment to the recipient if possible
    /* uses require_active modifier */
    function collect() require_active {
        /* check if a payment is due */
        if(block.timestamp >= nextPayment) {
            /* check if too little wei is in the contract */
            if(this.balance < price) {
                /* emit FailedToPay event */
                FailedToPay();
            } else {
                /* set the nextPayment timestamp for the next payment */
                nextPayment += time;
                /* send the money to the recipient */
                recipient.send(price);
                /* emit Paid event */
                Paid();
            }
        } else {
            /* logging error */
            log0("too soon");
        }
    }
    
    /// @dev cancel the subscription, works only if there is no payment due    
    /* uses require_active modifier */
    function cancel() require_active {
        /* check if sender is the creator */
        if(msg.sender == creator) {
            /* check if no payment is due */
            if(block.timestamp < nextPayment) {
                /* mark the subscription as cancelled */
                active = false;
                /* send remaining wei back to creator */
                creator.send(this.balance);
                /* emit Cancelled event */
                Cancelled();
            }
        }
    }
    
}
