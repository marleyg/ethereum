import "metastarterstub.sol";

/*
    TODO

    Finish natspec comments
*/

/// @title MetaStarter
contract MetaStarter is MetaStarterStub  {    

    uint256 constant min_deposit = 5;
    uint256 constant min_endowment = 5;

    event CampaignCreated (uint256 indexed id); // After create_campaign
    event Contributed (uint256 indexed id); // Whenever contrib_count increases
    event CampaignStatusChanged (uint256 indexed id); // When status changes
    event CampaignInfoChanged (uint256 indexed id); // Whenever info_hash changes   

    event FrontierDestroy (); // contract gets destroyed, for FRONTIER only
    address creator; // FRONTIER only, can call frontier_destroy

    struct Campaign {
        bytes32 desc_hash; // hash over title + description, immutable
        bytes32 info_hash; // hash over updates, mutable by creator
        uint256 identity_lsb; // 256 least significant bits of whisper identity
        uint256 identity_msb; // 256 most significant bits of whisper identity
        address backend; // address of backend contract
        address creator; // address of campaign creator
        uint256 next; // doubly linked list for campaigns iteration. active campaigns left of campaigns[0]
        uint256 prev; // doubly linked list for campaigns iteration. past campaigns right of campaigns[0]
        uint256 deposit; // security deposit for spam prevention
        uint256 registration_date;
        CampaignStatus status;
    }

    struct TrustProvider {
        bytes32 identifier;
        uint256 endowment;
        mapping (address => bool) trusted_backends;
    }

    mapping (uint256 => Campaign) campaigns;
    mapping (address => TrustProvider) trust_providers;

    mapping (uint256 => address) frontier_trust_providers;
    uint256 frontier_trust_providers_count;

    /// @dev Self-destruct function for the end of frontier. Cancels all campaigns and returns endowments
    function frontier_destroy () {

        if (msg.sender != creator) return;

        uint256 id = 0;

        while ((id = iterator_next(id)) != 0) {
            Campaign c = campaigns[id];
            MetaStarterBackend (c.backend).release_deposit.value (c.deposit) (id);
            MetaStarterBackend (c.backend).frontier_destroy (id);
        }

        uint256 i;

        for (i=0; i < frontier_trust_providers_count; i++) {
            address tp_address = frontier_trust_providers[i];
            TrustProvider tp = trust_providers[tp_address];
            tp_address.send (tp.endowment);
        }

        FrontierDestroy ();

        suicide (creator);
    }

    function MetaStarter () {
        creator = msg.sender; // FRONTIER only
    }

    /// @dev Add campaign to the left of the campaign list
    /// @param id ID of the campaign
    function add_active (uint256 id) private {
        Campaign c = campaigns[id];

        c.next = 0;
        c.prev = campaigns[0].prev;

        campaigns[0].prev = id;
        if (c.prev != 0)
            campaigns[c.prev].next = id;
    }

    /// @dev Remove campaign from the campaign list and readds it to the right list
    /// @param id ID of the campaign
    function transfer_inactive (uint256 id) private {
        Campaign c = campaigns[id];

        if (c.prev != 0)
            campaigns[c.prev].next = c.next;
        
        campaigns[c.next].prev = c.prev;

        c.prev = 0;
        c.next = campaigns[0].next;

        campaigns[0].next = id;
        if (c.next != 0)
            campaigns[c.next].prev = id;
    }


    /// @dev Change info_hash iff sender is creator of the campaign
    function modify_info_hash (uint256 id, bytes32 info_hash) {
        Campaign c = campaigns[id];

        if (msg.sender == c.creator) {
            c.info_hash = info_hash;
            CampaignInfoChanged (id);
        }
    }

    /// @notice Register as trust provider with identifier `identifier`
    /// @param identifier Identifier to use for readability
    /// @return true if registration successful, false if not
    function register_trust_provider (bytes32 identifier) returns (bool status) {
        TrustProvider tp = trust_providers[msg.sender];

        if ((tp.identifier == 0) && (msg.value >= min_endowment*tx.gasprice)) {
            tp.identifier = identifier;
            // PROOF OF BURN (not in FRONTIER)
            tp.endowment = msg.value;

            frontier_trust_providers[frontier_trust_providers_count++] = msg.sender;            
            return true;
        }

        return false;
    }

    /// @notice Set trust value for backend `backend` to `trusted`
    /// @param backend Backend to set trust value for
    /// @param trusted New trust value for backend
    function set_trust (address backend, bool trusted) {
        TrustProvider tp = trust_providers[msg.sender];

        if (tp.identifier != 0) {
            tp.trusted_backends[backend] = trusted;
        }
    }

    /// @dev Register campaign with MetaStarter. Value sent with this call is used as security deposit, the timestamp as registration_date. If successful, the campaign will be in INIT state
    /// @param creator Creator of the campaign
    /// @param desc_hash Hash of the description for the campaign
    /// @param lsb 256 lower significant bits of the associated whisper identity
    /// @param msb 256 upper significant bits of the associated whisper identity
    /// @return Id for the registered campaign, 0 on failure
    function register_campaign (address creator, bytes32 desc_hash, uint256 lsb, uint256 msb) returns (uint256 id) {
        var backend = MetaStarterBackend(msg.sender);
        id = compute_id (msg.sender, creator, desc_hash, lsb, msb);
            
        Campaign c = campaigns[id];
        
        if ((c.backend != 0) || (msg.value < min_deposit*tx.gasprice)) {
            return 0;
        }

        c.deposit = msg.value;
        c.backend = backend;
        c.creator = creator;
        c.desc_hash = desc_hash;
        c.identity_lsb = lsb;
        c.identity_msb = msb;
        c.registration_date = block.timestamp;
        c.status = CampaignStatus.INIT;
        
        add_active (id);

        CampaignCreated (id);
        
        return id;
    }

    /// @dev Modifier to check if the sender matches the backend for campaign
    modifier backend_auth (uint256 id) {
        if (campaigns[id].backend == msg.sender) { _ }
    }

    /// @dev Modify status of a campaign. The first time it is set to a COMPLETED state, the security deposit is released, the campaign is marked inactive and further call will be ignored
    /// @param id ID of the campaign
    /// @param status New status for the campaign
    function modify_status (uint256 id, CampaignStatus status) backend_auth (id) {

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

    /// @dev Trigger Contributed event
    function notify_contributed (uint256 id) backend_auth (id) {
        Contributed (id);
    }

    function get_identity (uint256 id) constant returns (uint256 lsb, uint256 msb) {
        lsb = campaigns[id].identity_lsb;
        msb = campaigns[id].identity_msb;
    }

    function get_desc_hash (uint256 id) constant returns (bytes32 next) {
        return campaigns[id].desc_hash;
    }

    function get_info_hash (uint256 id) constant returns (bytes32 prev) {
        return campaigns[id].info_hash;
    }

    function get_creator (uint256 id) constant returns (address creator) {
        return campaigns[id].creator;        
    }

    function get_registration_date (uint256 id) constant returns (uint256 registration_date) {
        return campaigns[id].registration_date;
    }

    function get_campaign_status (uint256 id) constant returns (CampaignStatus status) {
        return campaigns[id].status;
    }

    function get_trust_provider_identifier (address trust_provider) constant returns (bytes32 identifier) {
        return trust_providers[trust_provider].identifier;
    }

    function get_trust_provider_endowment (address trust_provider) constant returns (uint256 endowment) {
        return trust_providers[trust_provider].endowment;
    }

    function get_backend (uint256 id) constant returns (address backend) {
        return campaigns[id].backend;
    }

    function check_trusted (address trust_provider, address backend) constant returns (bool trusted) {
        return trust_providers[trust_provider].trusted_backends[backend];
    }

    /// @dev Get campaign in campaign list after campaign id. iterator_next(0) yields the first completed campaign
    /// @param id ID of the campaign
    /// @return id of the next campaign
    function iterator_next (uint256 id) constant returns (uint256 next) {
        return campaigns[id].next;
    }

    /// @dev Get campaign in campaign list before campaign id. iterator_prev(0) yields the first ongoing campaign
    /// @param id ID of the campaign
    /// @return id of the previous campaign
    function iterator_prev (uint256 id) constant returns (uint256 prev) {
        return campaigns[id].prev;
    }

}
