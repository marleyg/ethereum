contract Feed {
    
    /* variable for the creator of the contract */
    address creator;
    /* variable for the stored value */
    uint value;
    
    /* event to be fired when the value changes */
    event Update(uint value);
    
    /// @dev constructor, called at deployment
    /// @param initialValue the value after deployment
    function Feed(uint initialValue) {
        /* store the creator of the contract */
        creator = msg.sender;
        /* set the first value */
        update(initialValue);
    }
    
    /// @dev update the stored value
    /// @param value_ the new value
    function update(uint value_) {
        /* check if sender is the creator of the contract */
        if(msg.sender == creator) {
            /* update the value */
            value = value_;
            /* emit update event */
            Update(value);
        }
    }

    /// @dev getter - for a price
    /// @return current value
    function getValue() returns (uint) {
        /* TODO */
        return 0;
    }
    
}