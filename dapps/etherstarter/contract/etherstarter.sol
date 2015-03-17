import "metastarterstub.sol";
import "metastarter.sol";

contract EtherStarter is MetaStarterBackend {    
    
    MetaStarter metastarter; 
    address creator; // only for setting ui hash   
    bytes32 ui_hash;
    
    struct Contribution {
        address sender;
        uint256 value;
    }

    struct Campaign {
        address recipient;
        uint256 goal;
        uint256 deadline;
        uint256 contrib_total; // amount raised
        uint256 contrib_count; // number of contributions
        mapping (uint256 => Contribution) contrib; // maps contribution id to contribution
        bool has_ended; // block.timestamp > deadline
    }    

    mapping (bytes32 => Campaign) campaigns;    
    
    function EtherStarter (address meta_address) {
        metastarter = MetaStarter (meta_address);
        creator = msg.sender;
    }

    function set_ui (bytes32 ui) {
        if ((ui_hash == 0) && (msg.sender == creator)) {
            ui_hash = ui;
        }
    }
    
    function create_campaign (address recipient, uint256 goal, uint256 deadline, uint256 identity_lsb, uint256 identity_msb, bytes32 desc_hash) {        
        if (deadline < block.timestamp) return;                

        metastarter.register_campaign.value(msg.value) (msg.sender, desc_hash, identity_lsb, identity_msb);
        
        var id = compute_id (this, msg.sender, desc_hash, identity_lsb, identity_msb);
        
        Campaign c = campaigns [id];

        c.recipient = recipient;
        c.goal = goal;
        c.deadline = deadline;
        
        metastarter.modify_status (id, CampaignStatus.STARTED);
    }

    function contribute (bytes32 id) {
        Campaign c = campaigns[id];

        if (c.recipient == 0) {
            msg.sender.send (msg.value);
            return;
        }

        if (block.timestamp > c.deadline) {
            if (c.has_ended) {
                msg.sender.send (msg.value);
                metastarter.notify_contributed (id);
                metastarter.modify_status (id, CampaignStatus.COMPLETED_SUCCESS);
            } else {
                for (uint256 i = 0; i < c.contrib_count;i++) {
                        c.contrib [i].sender.send (c.contrib[i].value);
                    }
                msg.sender.send (msg.value);
                c.has_ended = true;
                metastarter.modify_status (id, CampaignStatus.COMPLETED_FAILURE);
            }
        } else {
            var total = c.contrib_total + msg.value;
            c.contrib_total = total;

            Contribution con = c.contrib[c.contrib_count];

            con.sender = msg.sender;
            con.value = msg.value;

            if (c.has_ended) {
                c.recipient.send (msg.value);
            } else if (total >= c.goal) {
                c.recipient.send (total);
                c.has_ended = true;
                metastarter.modify_status (id, CampaignStatus.FUNDED);
            }
            c.contrib_count++;
            metastarter.notify_contributed (id);
        }
    }

    function release_deposit (bytes32 id) {
        if (msg.sender == address(metastarter)) {
            Campaign c = campaigns[id];

            metastarter.get_creator (id).send (msg.value);
        }
    }

    function get_preferred_ui () constant returns (bytes32) {
        return ui_hash;
    }

    function get_goal_fixed (bytes32 id) constant returns (uint256 total) {
        return campaigns[id].goal;
    }

    function get_recipient (bytes32 id) constant returns (address recipient) {
        return campaigns[id].recipient;
    }

    function get_deadline (bytes32 id) constant returns (uint256 deadline) {
        return campaigns[id].deadline;
    }
}
