contract Feed {
    
    address creator;
    uint public value;
    
    event Update(uint value);
    
    function Feed(uint initialValue) {
        creator = msg.sender;
        update(initialValue);
    }
    
    function update(uint value_) {
        if(msg.sender == creator) {
            value = value_;
            Update(value);
        }
    }
    
}
