import "metastarterstub.sol";
import "metastarter.sol";

/// @title EtherStarter
contract EtherStarter is MetaStarterBackend {    
    
    MetaStarter metastarter; 
    uint256 ui_hash;
    
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
    }    

    mapping (uint256 => Campaign) campaigns;    
    
    function EtherStarter (address meta_address, uint256 ui) {
        metastarter = MetaStarter (meta_address);
        ui_hash = ui;
    }

    /// @notice Create a campaign for `goal` wei for recipient `recipient`
    /// @dev Create a campaign and register it with MetaStarter. Requires at MetaStarter.min_deposit * gasPrice as security deposit.
    /// @param recipient Recipient for the raised funds
    /// @param goal Minimum value required for payout
    /// @param deadline Deadline for campaign
    /// @param identity_lsb 256 lower significant bits of the associated whisper identity
    /// @param identity_msb 256 upper significant bits of the associated whisper identity
    /// @param desc_hash Hash of the description for the campaign
    /// @return true if campaign was created, false if not
    function create_campaign (address recipient, uint256 goal, uint256 deadline, uint256 identity_lsb, uint256 identity_msb, uint256 desc_hash) returns (bool success) {        
        if (deadline < block.timestamp) return;                
        if (goal == 0) return;

        var id = metastarter.register_campaign.value(msg.value) (msg.sender, desc_hash, identity_lsb, identity_msb);

        if (id != 0) {            

            Campaign c = campaigns [id];

            c.recipient = recipient;
            c.goal = goal;
            c.deadline = deadline;
            
            metastarter.modify_status (id, CampaignStatus.STARTED);

            return true;
        }
        
        return false;
    }

    /// @dev Returns all contributions for campaign
    /// @param id ID of the campaign
    function revert_campaign (uint256 id) private {
        Campaign c = campaigns[id];

        for (uint256 i = 0; i < c.contrib_count;i++) {
            c.contrib [i].sender.send (c.contrib[i].value);
        }
    }

    /// @dev FRONTIER only
    function frontier_destroy (uint256 id) {
        if (msg.sender == address(metastarter)) {
            revert_campaign (id);
        }
    }

    /// @notice Contribute to campaign `id`
    /// @param id ID of the campaign
    function contribute (uint256 id) {
        Campaign c = campaigns[id];

        if (c.recipient == 0) {
            msg.sender.send (msg.value);
            return;
        }

        var status = metastarter.get_campaign_status (id);

        if (block.timestamp > c.deadline) {
            if (status == CampaignStatus.FUNDED) {
                msg.sender.send (msg.value);
                metastarter.notify_contributed (id);
                metastarter.modify_status (id, CampaignStatus.COMPLETED_SUCCESS);
            } else if (status == CampaignStatus.STARTED) {
                revert_campaign (id);
                msg.sender.send (msg.value);                
                metastarter.modify_status (id, CampaignStatus.COMPLETED_FAILURE);
            }
        } else {
            var total = c.contrib_total + msg.value;
            c.contrib_total = total;

            Contribution con = c.contrib[c.contrib_count];

            con.sender = msg.sender;
            con.value = msg.value;

            if (status == CampaignStatus.FUNDED) {
                c.recipient.send (msg.value);
            } else if (total >= c.goal) {
                c.recipient.send (total);
                metastarter.modify_status (id, CampaignStatus.FUNDED);
            }

            c.contrib_count++;
            metastarter.notify_contributed (id);
        }
    }

    function release_deposit (uint256 id) {
        if (msg.sender == address(metastarter)) {
            metastarter.get_creator (id).send (msg.value);
        }
    }

    function get_progress (uint256 id) constant returns (uint256 progress) {
        return campaigns[id].contrib_total;
    }

    function get_preferred_ui () constant returns (uint256) {
        return ui_hash;
    }

    function get_goal_fixed (uint256 id) constant returns (uint256 total) {
        return campaigns[id].goal;
    }

    function get_recipient (uint256 id) constant returns (address recipient) {
        return campaigns[id].recipient;
    }

    function get_deadline (uint256 id) constant returns (uint256 deadline) {
        return campaigns[id].deadline;
    }

    function () returns (uint256) {
        return 0;
    }
}
