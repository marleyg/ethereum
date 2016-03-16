// imports some useful base contracts
import "std.sol";

// derive from named contract
// contructor argument for named is registered with namereg
contract Coin is named("Coin") {
    
    // state variable for minter address
    // public means auto genereted getter
    address public minter;
    // hashtable for addresses
    // all keys already exist
    mapping (address => uint) public balances;
    
    // event for UIs, light clients and testing
    event Sent(address sender, address reciever, uint amount);

    // can be applied to function, _ will be replaced by function body
    modifier novalue() {
        if (msg.value != 0) throw; _
    }
    
    // constructor, called when contract is created
    function Coin() {
        // msg.sender is a special address object
        minter = msg.sender;
    }
    
    // mint function
    // address: 160 bit type for ethereum address
    // uint: 256 bit unsigned integer
    // uses the novalue modifier
    function mint(address receiver, uint amount) novalue {
        if(msg.sender == minter) {
            // modifiying a value in the balances mapping
            balances[receiver] += amount;
            // Low level write-access to log
            log2("Minted some coins", bytes32(amount), bytes32(receiver));
        }
    }
    
    function send(address receiver, uint amount) novalue {
        // bail out if there is not enough balance
        if(balances[msg.sender] < amount) return;
        balances[msg.sender] -= amount;
        balances[receiver] += amount;
        // emits Sent event
        Sent(msg.sender, receiver, amount);
    }
    
    // default function
    function () {
        throw;
    }
    
}
