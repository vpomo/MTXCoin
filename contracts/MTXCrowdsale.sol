pragma solidity ^0.4.18;


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

    function max64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a < b ? a : b;
    }

    function max256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}


contract ERC20Basic {
    uint256 public totalSupply;

    bool public transfersEnabled;

    function balanceOf(address who) public view returns (uint256);

    function transfer(address to, uint256 value) public returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
}


contract ERC20 {
    uint256 public totalSupply;

    bool public transfersEnabled;

    function balanceOf(address _owner) public constant returns (uint256 balance);

    function transfer(address _to, uint256 _value) public returns (bool success);

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    function approve(address _spender, uint256 _value) public returns (bool success);

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;
    address public ownerTwo;

    event OwnerChanged(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    function Ownable() public {
    }


    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner || msg.sender == ownerTwo);
        _;
    }


    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function changeOwner(address newOwner) internal onlyOwner {
        require(newOwner != address(0));
        OwnerChanged(owner, newOwner);
        owner = newOwner;
    }

    function changeOwnerTwo(address newOwnerTwo) public onlyOwner {
        require(newOwnerTwo != address(0));
        OwnerChanged(ownerTwo, newOwnerTwo);
        ownerTwo = newOwnerTwo;
    }

}


contract BasicToken is ERC20Basic, Ownable {
    using SafeMath for uint256;

    mapping (address => uint256) balances;
    uint256 public endTimeLockedTokensTeam;
    uint256 public fundForTeam =  75 * (10 ** 24);

    /**
    * Protection against short address attack
    */
    modifier onlyPayloadSize(uint numwords) {
        assert(msg.data.length == numwords * 32 + 4);
        _;
    }

    /**
    * @dev transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint256 _value) public onlyPayloadSize(2) returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        require(transfersEnabled);

        // Block the sending of tokens from the fund Team
        if( (now < endTimeLockedTokensTeam) && (msg.sender == owner || msg.sender == ownerTwo) &&
            (_value > balances[owner].sub(fundForTeam)) ){
            revert();
        }

        // SafeMath.sub will throw if there is not enough balance.
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
    * @dev Gets the balance of the specified address.
    * @param _owner The address to query the the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }

}


contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) internal allowed;

    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address _from, address _to, uint256 _value) public onlyPayloadSize(3) returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        require(transfersEnabled);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     *
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param _spender The address which will spend the funds.
     * @param _value The amount of tokens to be spent.
     */
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param _owner address The address which owns the funds.
     * @param _spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address _owner, address _spender) public onlyPayloadSize(2) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    /**
     * approve should be called when allowed[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     */
    function increaseApproval(address _spender, uint _addedValue) public returns (bool success) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool success) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        }
        else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

}


/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/zeppelin-solidity/issues/120
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */

contract MintableToken is StandardToken {
    string public constant name = "MTX Coin";
    string public constant symbol = "MTX";
    uint8 public constant decimals = 18;

    event Mint(address indexed to, uint256 amount);
    event MintFinished();
    event Burn(address indexed burner, uint256 value);

    bool public mintingFinished;

    modifier canMint() {
        require(!mintingFinished);
        _;
    }

    /**
     * @dev Function to mint tokens
     * @param _to The address that will receive the minted tokens.
     * @param _amount The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(address _to, uint256 _amount, address _owner) canMint internal returns (bool) {
        balances[_to] = balances[_to].add(_amount);
        balances[_owner] = balances[_owner].sub(_amount);
        Mint(_to, _amount);
        Transfer(_owner, _to, _amount);
        return true;
    }

    /**
     * @dev Function to stop minting new tokens.
     * @return True if the operation was successful.
     */
    function finishMinting() internal onlyOwner canMint  returns (bool) {
        mintingFinished = true;
        MintFinished();
        return true;
    }

    /**
     * Peterson's Law Protection
     * Claim tokens
     */
    function claimTokens(address _token) public onlyOwner {
        if (_token == 0x0) {
            owner.transfer(this.balance);
            return;
        }
        MintableToken token = MintableToken(_token);
        uint256 balance = token.balanceOf(this);
        token.transfer(owner, balance);
        Transfer(_token, owner, balance);
    }
}


/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale.
 * Crowdsales have a start and end timestamps, where investors can make
 * token purchases. Funds collected are forwarded to a wallet
 * as they arrive.
 */
contract Crowdsale is Ownable, StandardToken {
    using SafeMath for uint256;
    // address where funds are collected
    address public wallet;
    uint256 public startTimePreICO;
    uint256 public endTimePreICO;
    uint256 public startTimeICO;
    uint256 public endTimeICO;

    // amount of raised money in wei
    uint256 public weiRaised;
    uint256 public tokenAllocated;

    function Crowdsale(address _wallet, uint256 _startTime) public {
        require(_wallet != address(0));
        wallet = _wallet;
        startTimePreICO = _startTime;
        endTimePreICO = _startTime + (4 weeks);
        startTimeICO = _startTime + (8 weeks);
        endTimeICO = _startTime + (12 weeks);
        endTimeLockedTokensTeam = endTimeICO + (1 years);
    }
}


contract MTXCrowdsale is Ownable, Crowdsale, MintableToken {
    using SafeMath for uint256;

    enum State {Active, Closed}
    State public state;

    uint256 public weiMinSalePreIco = 3 * 10 ** 18; // 3 ETH
    uint256 public weiMinSaleIco = 1 * 10 ** 17; // 0.1 ETH
    uint256 public weiMinSaleWhiteWaitlist = 1 * 10 ** 17; // 0.1 ETH
    uint256 public weiMaxSaleWhiteWaitlist = 5 * 10 ** 18; // 5 ETH

    uint256 public rate = 20000;

    mapping (address => uint256) public deposited;
    mapping(address => bool) public preICOWhiteList;
    mapping(address => bool) public preICOWaitList;
    mapping(address => bool) public iCOWhiteList;
    mapping(address => bool) public iCOWaitList;

    uint256 public constant INITIAL_SUPPLY = 750 * (10 ** 6) * (10 ** uint256(decimals));
    uint256 public fundForSale = 375 * (10 ** 6) * (10 ** uint256(decimals));
    //uint256 public fundForTeam =  75 * (10 ** 6) * (10 ** uint256(decimals));

    uint256 public countInvestor;

    event TokenPurchase(address indexed beneficiary, uint256 value, uint256 amount);
    event TokenLimitReached(uint256 tokenRaised, uint256 purchasedToken);
    event Finalized();

    function MTXCrowdsale(address _owner, address _wallet, address _ownerTwo, uint256 _startTime) public
    Crowdsale(_wallet, _startTime)
    {

        require(_wallet != address(0));
        require(_owner != address(0));
        require(_ownerTwo != address(0));
        require(_startTime > 0);
        owner = _owner;
        owner = msg.sender;
        ownerTwo = _ownerTwo;
        transfersEnabled = true;
        mintingFinished = false;
        state = State.Active;
        totalSupply = INITIAL_SUPPLY;
        bool resultMintForOwner = mintForOwner(owner);
        require(resultMintForOwner);
    }

    modifier inState(State _state) {
        require(state == _state);
        _;
    }

    /**
   * @dev Adds single address to whitelist or waitlist.
   * param _selectList: 1 - preICOWhiteList, 2 - preICOWaitList
   * 3 - iCOWhiteList, 4 - iCOWaitList
   * param _beneficiary Address to be added to the whitelist
   */
    function addToWhiteOrWaitList(uint8 _selectList, address _beneficiary) external onlyOwner {
        require(0 < _selectList && _selectList < 5);
        setValueTrueList(_selectList, _beneficiary);
    }

    /**
     * @dev Adds list of addresses to whitelist or waitlist. Not overloaded due to limitations with truffle testing.
     * param _beneficiaries Addresses to be added to the whitelist
     */
    function addManyToWhiteOrWaitList(uint8 _selectList, address[] _beneficiaries) external onlyOwner {
        require(0 < _selectList && _selectList < 5);
        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            setValueTrueList(_selectList, _beneficiaries[i]);
        }
    }

    /**
     * @dev Removes single address from whitelist.
     * param _beneficiary Address to be removed to the whitelist
     */
    function removeFromWhiteOrWaitList(uint8 _selectList, address _beneficiary) external onlyOwner {
        require(0 < _selectList && _selectList < 5);
        setValueFalseList(_selectList, _beneficiary);
    }

    function setValueTrueList(uint8 _selectList, address _beneficiary) internal onlyOwner {
        if(_selectList == 1){
            preICOWhiteList[_beneficiary] = true;
        }
        if(_selectList == 2){
            preICOWaitList[_beneficiary] = true;
        }
        if(_selectList == 3){
            iCOWhiteList[_beneficiary] = true;
        }
        if(_selectList == 4){
            iCOWaitList[_beneficiary] = true;
        }
    }

    function setValueFalseList(uint8 _selectList, address _beneficiary) internal onlyOwner {
        if(_selectList == 1){
            preICOWhiteList[_beneficiary] = false;
        }
        if(_selectList == 2){
            preICOWaitList[_beneficiary] = false;
        }
        if(_selectList == 3){
            iCOWhiteList[_beneficiary] = false;
        }
        if(_selectList == 4){
            iCOWaitList[_beneficiary] = false;
        }
    }

    // fallback function can be used to buy tokens
    function() payable public {
        buyTokens(msg.sender);
    }

    // low level token purchase function
    function buyTokens(address _investor) public inState(State.Active) payable returns (uint256){
        require(_investor != address(0));
        uint256 weiAmount = msg.value;
        uint256 tokens = validPurchaseTokens(weiAmount);
        if (tokens == 0) {revert();}
        weiRaised = weiRaised.add(weiAmount);
        tokenAllocated = tokenAllocated.add(tokens);
        mint(_investor, tokens, owner);

        TokenPurchase(_investor, weiAmount, tokens);
        if (deposited[_investor] == 0) {
            countInvestor = countInvestor.add(1);
        }
        deposit(_investor);
        wallet.transfer(weiAmount);
        return tokens;
    }

    /**
    *
    * during pre-ICO or presale only with a min. of 3 ETH
    * >= 50 ETH 20% discount
    * 25 to 49.99999999 ETH 15% discount
    * 10 to 24.99999999 ETH 10% discount
    * 3 to 9.999999999 ETH 5% discount
    */
    function getTotalAmountOfTokens(uint256 _weiAmount) internal view returns (uint256) {
        uint256 currentDate = now;
        uint256 amountOfTokens = 0;
        if(currentDate >= startTimePreICO && currentDate < startTimeICO){
            // preICO Whitelist
            if(currentDate >= startTimePreICO && currentDate < (startTimePreICO + 1 days)){
                require(preICOWhiteList[msg.sender]);
                require(weiMinSaleWhiteWaitlist <= _weiAmount && _weiAmount <= weiMaxSaleWhiteWaitlist);
                amountOfTokens = _weiAmount.mul(rate.div(100).mul(105));
                return amountOfTokens;
            }
            // preICO Waitlist
            if(currentDate >= (startTimePreICO + 1 days) && currentDate < (startTimePreICO + 2 days)){
                require(preICOWaitList[msg.sender]);
                require(weiMinSaleWhiteWaitlist <= _weiAmount && _weiAmount <= weiMaxSaleWhiteWaitlist);
                amountOfTokens = _weiAmount.mul(rate.div(100).mul(105));
                return amountOfTokens;
            }
            if(_weiAmount < weiMinSalePreIco){
                return 0;
            }
            if (_weiAmount < 10 * 10**18){
                amountOfTokens = _weiAmount.mul(rate.div(100).mul(105));
            }
            if (_weiAmount >= 10 * 10**18 && _weiAmount < 25 * 10**18){
                amountOfTokens = _weiAmount.mul(rate.div(100).mul(110));
            }
            if (_weiAmount >= 25 * 10**18 && _weiAmount < 50 * 10**18){
                amountOfTokens = _weiAmount.mul(rate.div(100).mul(115));
            }
            if (_weiAmount >= 50 * 10**18){
                amountOfTokens = _weiAmount.mul(rate.div(100).mul(120));
            }
        }
        if(currentDate >= startTimeICO && currentDate < endTimeICO){
            // preICO Whitelist
            if(currentDate >= startTimeICO && currentDate < (startTimeICO + 1 days)){
                require(iCOWhiteList[msg.sender]);
                require(weiMinSaleWhiteWaitlist <= _weiAmount && _weiAmount <= weiMaxSaleWhiteWaitlist);
                amountOfTokens = _weiAmount.mul(rate);
                return amountOfTokens;
            }
            // preICO Waitlist
            if(currentDate >= (startTimeICO + 1 days) && currentDate < (startTimeICO + 2 days)){
                require(iCOWaitList[msg.sender]);
                require(weiMinSaleWhiteWaitlist <= _weiAmount && _weiAmount <= weiMaxSaleWhiteWaitlist);
                amountOfTokens = _weiAmount.mul(rate);
                return amountOfTokens;
            }
            if(_weiAmount < weiMinSaleIco){
                return 0;
            }
            amountOfTokens = _weiAmount.mul(rate);
        }
        return amountOfTokens;
    }

    function deposit(address investor) internal {
        require(state == State.Active);
        deposited[investor] = deposited[investor].add(msg.value);
    }

    function mintForOwner(address _wallet) internal returns (bool result) {
        result = false;
        require(_wallet != address(0));
        balances[_wallet] = balances[_wallet].add(INITIAL_SUPPLY);
        result = true;
    }

    function getDeposited(address _investor) public view returns (uint256){
        return deposited[_investor];
    }

    function validPurchaseTokens(uint256 _weiAmount) public inState(State.Active) returns (uint256) {
        uint256 addTokens = getTotalAmountOfTokens(_weiAmount);
        if (tokenAllocated.add(addTokens) > fundForSale) {
            TokenLimitReached(tokenAllocated, addTokens);
            return 0;
        }
        return addTokens;
    }

    function finalize() public onlyOwner inState(State.Active) returns (bool result) {
        result = false;
        state = State.Closed;
        wallet.transfer(this.balance);
        finishMinting();
        Finalized();
        result = true;
    }

    function removeContract() public onlyOwner {
        selfdestruct(owner);
    }

    function changeRate(uint256 _newRate) public onlyOwner {
        require(_newRate > 0);
        rate = _newRate;
    }

    /**
     * @dev Function to burn tokens.
     * @return True if the operation was successful.
     */
    function ownerBurnToken(uint _value) public onlyOwner returns (bool) {
        require(_value > 0);
        require(_value <= balances[owner]);
        require(_value < totalSupply.sub(fundForTeam.add(tokenAllocated)));

        balances[owner] = balances[owner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(owner, _value);
        return true;
    }

}

