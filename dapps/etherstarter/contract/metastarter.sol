import "metastarterstub.sol";

/*
    TODO

    Port to natspec
    Fix issues where deposits and endowments are lost
*/

contract MetaStarter is MetaStarterStub  {    

    uint256 constant min_deposit = 50000;
    uint256 constant min_endowment = 5000;

    event CampaignCreated (bytes32 id); // After create_campaign
    event Contributed (bytes32 id); // Whenever contrib_count increases
    event CampaignStatusChanged (bytes32 id); // When status changes
    event CampaignInfoChanged (bytes32 id); // Whenever info_hash changes   
    event AuthError (); // Debugging only

    struct ShhIdentity {
        uint256 lsb; // 256 least significant bits of whisper identity
        uint256 msb; // 256 most significant bits of whisper identity
    }

    struct Campaign {
        bytes32 desc_hash; // hash over title + description, immutable
        bytes32 info_hash; // hash over updates, mutable by creator
        ShhIdentity identity; // associated whsiper identity
        address backend; // address of backend contract
        address creator; // address of campaign creator
        bytes32 next; // doubly linked list for campaigns iteration. active campaigns left of campaigns[0]
        bytes32 prev; // doubly linked list for campaigns iteration. past campaigns right of campaigns[0]
        uint256 deposit; // security deposit for spam prevention
        CampaignStatus status;
    }

    struct TrustProvider {
        bytes32 identifier;
        uint256 endowment;
        mapping (address => bool) trusted_backends;
    }

    mapping (bytes32 => Campaign) campaigns;
    mapping (address => TrustProvider) trust_providers;

    // add campaign to the left of the campaign list
    function add_active (bytes32 id) private {
        Campaign c = campaigns[id];

        c.next = 0;
        c.prev = campaigns[0].prev;

        campaigns[0].prev = id;
        if (c.prev != 0)
            campaigns[c.prev].next = id;
    }

    // removes campaign from list and readds it to the right list
    function transfer_inactive (bytes32 id) private {
        Campaign c = campaigns[id];

        if (c.prev != 0)
            campaigns[c.prev].next = c.next;
        if (c.next != 0)
            campaigns[c.next].prev = c.prev;

        c.prev = 0;
        c.next = campaigns[0].next;

        campaigns[0].next = id;
        if (c.next != 0)
            campaigns[c.next].prev = id;
    }


    // Change info_hash if sender is creator
    function modify_info_hash (bytes32 id, bytes32 info_hash) {
        Campaign c = campaigns[id];

        if (msg.sender == c.creator) {
            c.info_hash = info_hash;
            CampaignInfoChanged (id);
        }
    }

    function register_trust_provider (bytes32 identifier) {
        TrustProvider tp = trust_providers[msg.sender];

        if ((tp.identifier == 0) && (msg.value >= min_endowment*tx.gasprice)) {
            tp.identifier = identifier;
            // PROOF OF BURN!!!
            tp.endowment = msg.value;
        } else {
            // ENDOWMENT IS LOST - FIX!!!
        }
    }

    function set_trust (address backend, bool trusted) {
        TrustProvider tp = trust_providers[msg.sender];

        if (tp.identifier != 0) {
            tp.trusted_backends[backend] = trusted;
        }
    }

    function register_campaign (address creator, bytes32 desc_hash, uint256 lsb, uint256 msb) returns (bool status) {
        var backend = MetaStarterBackend(msg.sender);
        var id = compute_id (msg.sender, creator, desc_hash, lsb, msb);
            
        Campaign c = campaigns[id];
        
        if (c.creator != 0) {
            status = false;
            return;
        }

        if (msg.value < min_deposit*tx.gasprice) {
            // DEPOSIT IS LOST - FIX!!!
            status = false;
            return;
        }
        
        c.deposit = msg.value;
        c.backend = backend;
        c.creator = creator;
        c.desc_hash = desc_hash;
        c.identity.lsb = lsb;
        c.identity.msb = msb;
        c.status = CampaignStatus.INIT;
        
        add_active (id);

        CampaignCreated (id);
        
        status = true;
        return;
    }

    modifier backend_auth (bytes32 id) {
        if (campaigns[id].backend == msg.sender) { _ } else AuthError();
    }

    function modify_status (bytes32 id, CampaignStatus status) backend_auth(id) {

        Campaign c = campaigns[id];

        if ((c.status == CampaignStatus.COMPLETED_SUCCESS) || (c.status == CampaignStatus.COMPLETED_FAILURE)) {
            return;
        }
        
        c.status = status;

        if ((status == CampaignStatus.COMPLETED_SUCCESS) || (status == CampaignStatus.COMPLETED_FAILURE)) {
            transfer_inactive (id);
            MetaStarterBackend (c.backend).release_deposit.value (c.deposit) (id);
        }

        CampaignStatusChanged (id);
    }

    function get_identity (bytes32 id) constant returns (uint256 lsb, uint256 msb) {
        lsb = campaigns[id].identity.lsb;
        msb = campaigns[id].identity.msb;
    }

    function get_desc_hash (bytes32 id) constant returns (bytes32 next) {
        return campaigns[id].desc_hash;
    }

    function get_info_hash (bytes32 id) constant returns (bytes32 prev) {
        return campaigns[id].info_hash;
    }

    function get_creator (bytes32 id) constant returns (address creator) {
        return campaigns[id].creator;
    }

    function get_campaign_status (bytes32 id) constant returns (CampaignStatus status) {
        return campaigns[id].status;
    }

    // Iterator functions for campaigns lis

    function iterator_next (bytes32 id) constant returns (bytes32 next) {
        return campaigns[id].next;
    }

    function iterator_prev (bytes32 id) constant returns (bytes32 prev) {
        return campaigns[id].prev;
    }

}
