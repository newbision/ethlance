pragma solidity ^0.5.0;

import "proxy/MutableForwarder.sol";
import "./EthlanceRegistry.sol";
import "./EthlanceFeedback.sol";


/// @title User Contract which represents a User's information
/// describing their price points and skills for employment, for being
/// a candidate, and for being an Arbiter for jobs.
contract EthlanceUser {
    uint public constant version = 1;
    EthlanceRegistry public constant registry = EthlanceRegistry(0xdaBBdABbDABbDabbDaBbDabbDaBbdaBbdaBbDAbB);

    struct Candidate {
	bool is_registered;
	uint64 hourly_rate; // In units of currency
	uint16 currency_type; // 0: Ethereum, 1: USD, ...
	// Additional Data in IPFS Metahash
    }

    struct Employer {
	bool is_registered;
	// Additional Data in IPFS Metahash
    }

    struct Arbiter {
	bool is_registered;
	uint payment_value; // Based on payment_type:
	                    // [0] In units of currency
                            // [1] 1-100 for percentage
	uint16 currency_type; // 0: Ethereum, 1: USD, ...
	uint8 payment_type; // 0: Flat Rate, 1: Percentage
	// Additonal Data in IPFS Metahash
    }

    address public user_address;
    uint public user_id;
    uint public date_created;
    uint public date_updated;
    string public metahash_ipfs;
    
    // The entity that constructed contract
    address public owner;

    Candidate public candidate_data;
    Employer public employer_data;
    Arbiter public arbiter_data;
	

    function construct(uint _user_id, address _address, string calldata _metahash)
	external {
	require(owner == address(0), "EthlanceUser contract already constructed.");
	owner = msg.sender;

	user_id = _user_id;
	user_address = _address;
	date_created = now;
	date_updated = now;
	metahash_ipfs = _metahash;
	
    }


    /// @dev Fire events specific to the User
    /// @param event_name Unique to give the fired event
    /// @param event_data Additional event data to include in the
    /// fired event.
    function fireEvent(string memory event_name, uint[] memory event_data) private {
	registry.fireEvent(event_name, version, event_data);
    }


    function updateMetahash(string memory _metahash)
	public
        isUser {
	metahash_ipfs = _metahash;
	updateDateUpdated();
    }


    function updateDateUpdated() internal {
	date_updated = now;
    }


    /// @dev Register Candidate for the User.
    /// @dev Note: Requires that the address is a registered user.
    /// @param hourly_rate Based on currency, the hourly suggested
    /// amount for payment.
    /// @param currency_type The type of currency to be paid in.
    function registerCandidate(uint64 hourly_rate, uint16 currency_type)
	public 
        isUser {
	require(!candidate_data.is_registered,
		"Given user is already registered as a Candidate");
	require(currency_type <= 1, "Currency Type out of range");

	candidate_data.is_registered = true;
	candidate_data.hourly_rate = hourly_rate;
	candidate_data.currency_type = currency_type;
	updateDateUpdated();

	// Fire "UserRegisteredCandidate" Event
	uint[] memory edata = new uint[](1);
	edata[0] = user_id;
	fireEvent("UserRegisteredCandidate", edata);
    }


    /// @dev Update Candidate's rate of hourly pay and currency type.
    /// @param hourly_rate The rate of hourly pay for a particular currency.
    ///                    For USD, a unit of pay is a cent. For
    ///                    Ethereum, the unit of pay is a wei.
    /// @param currency_type Type of hourly pay. 0 - Eth, 1 - USD.
    function updateCandidateRate(uint64 hourly_rate,
				 uint16 currency_type)
	public
        isUser {
	candidate_data.hourly_rate = hourly_rate;
	candidate_data.currency_type = currency_type;
	updateDateUpdated();

	// Fire "UserRegisteredCandidate" Event
	uint[] memory edata = new uint[](1);
	edata[0] = user_id;
	fireEvent("UserCandidateUpdate", edata);
    }

    
    /// @dev Return the user's candidate data
    /// @return Tuple of candidate data.
    function getCandidateData()
	public view returns(bool is_registered,
			    uint64 hourly_rate,
			    uint16 currency_type) {
	is_registered = candidate_data.is_registered;
	hourly_rate = candidate_data.hourly_rate;
	currency_type = candidate_data.currency_type;
    }


    /// @dev Registers an Arbiter for the User.
    /// @param payment_value Unit of payment based on currency_type
    /// and payment_type
    /// @param currency_type Type of currency for the payment value
    ///        0 - ETH, 1 - USD
    /// @param payment_type Type of payment that the arbiter takes.
    ///        0 - Flat Rate, 1 - Percentage
    function registerArbiter(uint payment_value,
			     uint16 currency_type,
			     uint8 payment_type)
	public
        isUser {
	require(!arbiter_data.is_registered,
		"Given user is already registered as an Arbiter.");
	require(currency_type <= 1, "Currency Type out of range");

	arbiter_data.is_registered = true;
	arbiter_data.payment_value = payment_value;
	arbiter_data.currency_type = currency_type;
	arbiter_data.payment_type = payment_type;
	updateDateUpdated();

	// Fire Event
	uint[] memory edata = new uint[](1);
	edata[0] = user_id;
	fireEvent("UserRegisteredArbiter", edata);
    }


    /// @dev Updates the given arbiter's rate of payment.
    /// @param payment_value unit of payment based on currency_type
    /// and payment_type
    /// @param currency_type Type of currency for the payment value
    ///        0 - ETH, 1 - USD
    /// @param payment_type Type of payment that the arbiter takes.
    ///        0 - Flat Rate, 1 - Percentage
    function updateArbiterRate(uint payment_value,
			       uint16 currency_type,
			       uint8 payment_type)
	public
        isUser {
	arbiter_data.payment_value = payment_value;
	arbiter_data.currency_type = currency_type;
	arbiter_data.payment_type = payment_type;
	updateDateUpdated();

	// Fire Event
	uint[] memory edata = new uint[](1);
	edata[0] = user_id;
	fireEvent("UserArbiterUpdated", edata);
    }


    /// @dev Gets the user's arbiter data.
    /// @return Tuple containing the arbiter data
    function getArbiterData()
	public view
	returns(bool is_registered,
		uint payment_value,
		uint16 currency_type,
		uint8 payment_type) {
	is_registered = arbiter_data.is_registered;
	payment_value = arbiter_data.payment_value;
	currency_type = arbiter_data.currency_type;
	payment_type = arbiter_data.payment_type;
    }


    /// @dev Registers an Employee for the User.
    function registerEmployer()
	public
	isUser {
	require(!employer_data.is_registered,
		"Given user is already registered as an Employer.");

	employer_data.is_registered = true;
	updateDateUpdated();

	// Fire Event
	uint[] memory edata = new uint[](1);
	edata[0] = user_id;
	fireEvent("UserRegisteredEmployer", edata);
    }
    

    /// @dev Gets the user's employer data.
    /// @return Tuple containing the employer data
    function getEmployerData()
	public view
	returns(bool is_registered) {
	is_registered = employer_data.is_registered;
    }
    

    //
    // Modifiers
    //
    
    /// @dev Checks if the msg.sender is the user assigned to the user
    /// contract.
    modifier isUser {
	require(user_address == msg.sender,
		"Unauthorized: Given User does not own this user contract.");
	_;
    }
    

}
