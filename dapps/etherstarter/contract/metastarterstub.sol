contract MetaStarterStub {

    enum CampaignStatus {
        INIT,
        STARTED,
        PLEDGED,
        FUNDED,
        COMPLETED_SUCCESS,
        COMPLETED_FAILURE,
        INVALID
    }

    function compute_id (address backend, address creator, bytes32 desc_hash, uint256 lsb, uint256 msb) constant returns (bytes32 id) {
        id = sha3 (backend, creator, desc_hash, lsb, msb);
    }

}

contract MetaStarterBackend is MetaStarterStub {
    
    /* MANDATORY FUNCTIONS */

    function get_preferred_ui () constant returns (bytes32);
    function release_deposit (bytes32 id); // release security deposit, called by metastarter

    function frontier_destroy (bytes32 id); // called by metastarter before frontier ends, reverts all active campaigns
    
    /* OPTIONAL FUNCTIONS: implemented only if the backend has the concept, unimplemented function should return 0 */

    function get_deadline (bytes32 id) constant returns (uint256 deadline); // deadline: no more funding after this date
    function get_goal_fixed (bytes32 id) constant returns (uint256 deadline); // goal: goal if it is set to a fixed value
    function get_recipient (bytes32 id) constant returns (address recipient); // recipient: address of recipient if there is one
}