/**********************************************************************
*These solidity codes have been obtained from Etherscan for extracting
*the smartcontract related info.
*The data will be used by MATRIX AI team as the reference basis for
*MATRIX model analysis,extraction of contract semantics,
*as well as AI based data analysis, etc.
**********************************************************************/
pragma solidity 0.4.24;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 {
  function totalSupply() constant public returns (uint);

  function balanceOf(address who) constant public returns (uint256);

  function transfer(address to, uint256 value) public returns (bool);

  function allowance(address owner, address spender) public constant returns (uint256);

  function transferFrom(address from, address to, uint256 value) public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);

  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
}

/// @dev `Owned` is a base level contract that assigns an `owner` that can be
///  later changed
contract Owned {

    /// @dev `owner` is the only address that can call a function with this
    /// modifier
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    address public owner;

    /// @notice The Constructor assigns the message sender to be `owner`
    function Owned() public {owner = msg.sender;}

    /// @notice `owner` can step down and assign some other address to this role
    /// @param _newOwner The address of the new owner. 0x0 can be used to create
    ///  an unowned neutral vault, however that cannot be undone
    function changeOwner(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }
}

contract Callable is Owned {

    //sender => _allowed
    mapping(address => bool) public callers;

    //modifiers
    modifier onlyCaller {
        require(callers[msg.sender]);
        _;
    }

    //management of the repositories
    function updateCaller(address _caller, bool allowed) public onlyOwner {
        callers[_caller] = allowed;
    }
}

contract EternalStorage is Callable {

    mapping(bytes32 => uint) uIntStorage;
    mapping(bytes32 => string) stringStorage;
    mapping(bytes32 => address) addressStorage;
    mapping(bytes32 => bytes) bytesStorage;
    mapping(bytes32 => bool) boolStorage;
    mapping(bytes32 => int) intStorage;

    // *** Getter Methods ***
    function getUint(bytes32 _key) external view returns (uint) {
        return uIntStorage[_key];
    }

    function getString(bytes32 _key) external view returns (string) {
        return stringStorage[_key];
    }

    function getAddress(bytes32 _key) external view returns (address) {
        return addressStorage[_key];
    }

    function getBytes(bytes32 _key) external view returns (bytes) {
        return bytesStorage[_key];
    }

    function getBool(bytes32 _key) external view returns (bool) {
        return boolStorage[_key];
    }

    function getInt(bytes32 _key) external view returns (int) {
        return intStorage[_key];
    }

    // *** Setter Methods ***
    function setUint(bytes32 _key, uint _value) onlyCaller external {
        uIntStorage[_key] = _value;
    }

    function setString(bytes32 _key, string _value) onlyCaller external {
        stringStorage[_key] = _value;
    }

    function setAddress(bytes32 _key, address _value) onlyCaller external {
        addressStorage[_key] = _value;
    }

    function setBytes(bytes32 _key, bytes _value) onlyCaller external {
        bytesStorage[_key] = _value;
    }

    function setBool(bytes32 _key, bool _value) onlyCaller external {
        boolStorage[_key] = _value;
    }

    function setInt(bytes32 _key, int _value) onlyCaller external {
        intStorage[_key] = _value;
    }

    // *** Delete Methods ***
    function deleteUint(bytes32 _key) onlyCaller external {
        delete uIntStorage[_key];
    }

    function deleteString(bytes32 _key) onlyCaller external {
        delete stringStorage[_key];
    }

    function deleteAddress(bytes32 _key) onlyCaller external {
        delete addressStorage[_key];
    }

    function deleteBytes(bytes32 _key) onlyCaller external {
        delete bytesStorage[_key];
    }

    function deleteBool(bytes32 _key) onlyCaller external {
        delete boolStorage[_key];
    }

    function deleteInt(bytes32 _key) onlyCaller external {
        delete intStorage[_key];
    }
}

/*
 * Database Contract
 * Davy Van Roy
 * Quinten De Swaef
 */
contract FundRepository is Callable {

    using SafeMath for uint256;

    EternalStorage public db;

    //platform -> platformId => _funding
    mapping(bytes32 => mapping(string => Funding)) funds;

    struct Funding {
        address[] funders; //funders that funded tokens
        address[] tokens; //tokens that were funded
        mapping(address => TokenFunding) tokenFunding;
    }

    struct TokenFunding {
        mapping(address => uint256) balance;
        uint256 totalTokenBalance;
    }

    constructor(address _eternalStorage) public {
        db = EternalStorage(_eternalStorage);
    }

    function updateFunders(address _from, bytes32 _platform, string _platformId) public onlyCaller {
        bool existing = db.getBool(keccak256(abi.encodePacked("funds.userHasFunded", _platform, _platformId, _from)));
        if (!existing) {
            uint funderCount = getFunderCount(_platform, _platformId);
            db.setAddress(keccak256(abi.encodePacked("funds.funders.address", _platform, _platformId, funderCount)), _from);
            db.setUint(keccak256(abi.encodePacked("funds.funderCount", _platform, _platformId)), funderCount.add(1));
        }
    }

    function updateBalances(address _from, bytes32 _platform, string _platformId, address _token, uint256 _value) public onlyCaller {
        if (balance(_platform, _platformId, _token) <= 0) {
            //add to the list of tokens for this platformId
            uint tokenCount = getFundedTokenCount(_platform, _platformId);
            db.setAddress(keccak256(abi.encodePacked("funds.token.address", _platform, _platformId, tokenCount)), _token);
            db.setUint(keccak256(abi.encodePacked("funds.tokenCount", _platform, _platformId)), tokenCount.add(1));
        }

        //add to the balance of this platformId for this token
        db.setUint(keccak256(abi.encodePacked("funds.tokenBalance", _platform, _platformId, _token)), balance(_platform, _platformId, _token).add(_value));

        //add to the balance the user has funded for the request
        db.setUint(keccak256(abi.encodePacked("funds.amountFundedByUser", _platform, _platformId, _from, _token)), amountFunded(_platform, _platformId, _from, _token).add(_value));

        //add the fact that the user has now funded this platformId
        db.setBool(keccak256(abi.encodePacked("funds.userHasFunded", _platform, _platformId, _from)), true);
    }

    function claimToken(bytes32 platform, string platformId, address _token) public onlyCaller returns (uint256) {
        require(!issueResolved(platform, platformId), "Can't claim token, issue is already resolved.");
        uint256 totalTokenBalance = balance(platform, platformId, _token);
        db.deleteUint(keccak256(abi.encodePacked("funds.tokenBalance", platform, platformId, _token)));
        return totalTokenBalance;
    }

    function finishResolveFund(bytes32 platform, string platformId) public onlyCaller returns (bool) {
        db.setBool(keccak256(abi.encodePacked("funds.issueResolved", platform, platformId)), true);
        db.deleteUint(keccak256(abi.encodePacked("funds.funderCount", platform, platformId)));
        return true;
    }

    //constants
    function getFundInfo(bytes32 _platform, string _platformId, address _funder, address _token) public view returns (uint256, uint256, uint256) {
        return (
        getFunderCount(_platform, _platformId),
        balance(_platform, _platformId, _token),
        amountFunded(_platform, _platformId, _funder, _token)
        );
    }

    function issueResolved(bytes32 _platform, string _platformId) public view returns (bool) {
        return db.getBool(keccak256(abi.encodePacked("funds.issueResolved", _platform, _platformId)));
    }

    function getFundedTokenCount(bytes32 _platform, string _platformId) public view returns (uint256) {
        return db.getUint(keccak256(abi.encodePacked("funds.tokenCount", _platform, _platformId)));
    }

    function getFundedTokensByIndex(bytes32 _platform, string _platformId, uint _index) public view returns (address) {
        return db.getAddress(keccak256(abi.encodePacked("funds.token.address", _platform, _platformId, _index)));
    }

    function getFunderCount(bytes32 _platform, string _platformId) public view returns (uint) {
        return db.getUint(keccak256(abi.encodePacked("funds.funderCount", _platform, _platformId)));
    }

    function getFunderByIndex(bytes32 _platform, string _platformId, uint index) external view returns (address) {
        return db.getAddress(keccak256(abi.encodePacked("funds.funders.address", _platform, _platformId, index)));
    }

    function amountFunded(bytes32 _platform, string _platformId, address _funder, address _token) public view returns (uint256) {
        return db.getUint(keccak256(abi.encodePacked("funds.amountFundedByUser", _platform, _platformId, _funder, _token)));
    }

    function balance(bytes32 _platform, string _platformId, address _token) view public returns (uint256) {
        return db.getUint(keccak256(abi.encodePacked("funds.tokenBalance", _platform, _platformId, _token)));
    }
}

contract ClaimRepository is Callable {
    using SafeMath for uint256;

    EternalStorage public db;

    constructor(address _eternalStorage) public {
        //constructor
        require(_eternalStorage != address(0), "Eternal storage cannot be 0x0");
        db = EternalStorage(_eternalStorage);
    }

    function addClaim(address _solverAddress, bytes32 _platform, string _platformId, string _solver, address _token, uint256 _requestBalance) public onlyCaller returns (bool) {
        if (db.getAddress(keccak256(abi.encodePacked("claims.solver_address", _platform, _platformId))) != address(0)) {
            require(db.getAddress(keccak256(abi.encodePacked("claims.solver_address", _platform, _platformId))) == _solverAddress, "Adding a claim needs to happen with the same claimer as before");
        } else {
            db.setString(keccak256(abi.encodePacked("claims.solver", _platform, _platformId)), _solver);
            db.setAddress(keccak256(abi.encodePacked("claims.solver_address", _platform, _platformId)), _solverAddress);
        }

        uint tokenCount = db.getUint(keccak256(abi.encodePacked("claims.tokenCount", _platform, _platformId)));
        db.setUint(keccak256(abi.encodePacked("claims.tokenCount", _platform, _platformId)), tokenCount.add(1));
        db.setUint(keccak256(abi.encodePacked("claims.token.amount", _platform, _platformId, _token)), _requestBalance);
        db.setAddress(keccak256(abi.encodePacked("claims.token.address", _platform, _platformId, tokenCount)), _token);
        return true;
    }

    function isClaimed(bytes32 _platform, string _platformId) view external returns (bool claimed) {
        return db.getAddress(keccak256(abi.encodePacked("claims.solver_address", _platform, _platformId))) != address(0);
    }

    function getSolverAddress(bytes32 _platform, string _platformId) view external returns (address solverAddress) {
        return db.getAddress(keccak256(abi.encodePacked("claims.solver_address", _platform, _platformId)));
    }

    function getSolver(bytes32 _platform, string _platformId) view external returns (string){
        return db.getString(keccak256(abi.encodePacked("claims.solver", _platform, _platformId)));
    }

    function getTokenCount(bytes32 _platform, string _platformId) view external returns (uint count) {
        return db.getUint(keccak256(abi.encodePacked("claims.tokenCount", _platform, _platformId)));
    }

    function getTokenByIndex(bytes32 _platform, string _platformId, uint _index) view external returns (address token) {
        return db.getAddress(keccak256(abi.encodePacked("claims.token.address", _platform, _platformId, _index)));
    }

    function getAmountByToken(bytes32 _platform, string _platformId, address _token) view external returns (uint token) {
        return db.getUint(keccak256(abi.encodePacked("claims.token.amount", _platform, _platformId, _token)));
    }
}

contract ApproveAndCallFallBack {
  function receiveApproval(address from, uint256 _amount, address _token, bytes _data) public;
}

/*
 * @title String & slice utility library for Solidity contracts.
 * @author Nick Johnson <