pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; 
        return msg.data;
    }
}

contract ERC20 is Context {
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    
    constructor (string memory name_, string memory symbol_, uint256 totalSupply_) {
        _name = name_;
        _symbol = symbol_;
        _totalSupply = totalSupply_;
    }
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }
    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    
    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    
    function balanceOf(address account) public view virtual returns (uint256) {
        return _balances[account];
    }
    
    function transfer(address recipient, uint256 amount) public virtual returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    
    function allowance(address owner, address spender) public view virtual returns (uint256) {
        return _allowances[owner][spender];
    }

    
    function approve(address spender, uint256 amount) public virtual returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    
    function transferFrom(address sender, address recipient, uint256 amount) public virtual returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }
    
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }
    
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }
    
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }
    
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }
    
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

contract Owned {
    address public owner;
    constructor() { owner = msg.sender; }
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
}
    
contract Ballot{
    struct Voter {
        uint weight; 
        bool voted;  
        uint vote;   
    }
    struct Proposal{
        uint votecount;
    }
    
    Proposal[] public proposals;
    enum Stage{Init, Reg, Vote, Done}
    Stage public stage = Stage.Init;
    
    address chairperson;
    address public ReqAtAddress;
    address public ReqKeyAddress;
    address public addressofAT;
    address public addressofDO;
    address public addressofAA;
   
    mapping(address=>Voter)voters;
    uint startTime;
    uint len;
    modifier validStage(Stage reqStage){
        require(stage==reqStage);
        _;
    }
    
    event votingCompleted();
    
    constructor(uint _numProposals) {
        for(uint i=0;i<_numProposals;i++)
        {
            proposals.push(Proposal({votecount: 0}));
        }
        len= _numProposals;
        chairperson= msg.sender;
        voters[chairperson].weight =1;
        stage = Stage.Reg;
        startTime = block.timestamp;
    }
    
    function register(address toVoter) public validStage(Stage.Reg){
        if(msg.sender != chairperson || voters[toVoter].voted)return;
        require(voters[toVoter].weight==0);
        voters[toVoter].weight=1;
        voters[toVoter].voted=false;
        if(block.timestamp>(startTime+20 seconds)){
            stage= Stage.Vote;
        }
    }
    
    function setAddress1(address _ReqAtAddress, address _ReqKeyAddress, address _addressofAt, address _addressofDO, address _addressofAA) external {
        ReqAtAddress= _ReqAtAddress;
        ReqKeyAddress = _ReqKeyAddress;
        addressofAT = _addressofAt;
        addressofDO = _addressofDO;
        addressofAA = _addressofAA;
        
    }
    
    function callReqAt() external returns(bool){
        RequestAT r = RequestAT(ReqAtAddress);
        return r.checkA(addressofAA);
    }
    
    function callReqKey() external returns(bool){
        RequestKey R = RequestKey(ReqKeyAddress);
        return R.checkAt(addressofDO,addressofAA);
    }
    
    function Vote(uint toProposal) public validStage(Stage.Vote){
        
        Voter storage sender = voters[msg.sender];
        if(sender.voted || toProposal>=len)return;
        require(sender.weight != 0);
        sender.voted = true;
        sender.vote = toProposal;
        proposals[toProposal].votecount += sender.weight;
        if(block.timestamp>(startTime+20 seconds)){
            stage= Stage.Done;
            emit votingCompleted();
        }
    }
        
    function winningProposal() public validStage(Stage.Done) view returns(uint8 _winningProposal){
        uint256 winningVotecount=0;
        for(uint8 prop=0;prop<len;prop++)
            if(proposals[prop].votecount>winningVotecount){
                winningVotecount = proposals[prop].votecount;
                _winningProposal=prop;
            }
        assert(winningVotecount>0);
    }
        
}

contract RequestAT {
    function checkA(address addressofAA) external returns (bool) {
        AT my_at= AT(addressofAA);
        if(my_at.checkAttribute(1,"Registered","Permit")== true){
           return my_at.sendToken(msg.sender, 2); 
        }
        return false;
    }
}    


contract RequestKey {
    function checkAt(address addressofDO, address addressofAA) external returns (bool){
        DO my_ap = DO(addressofDO);
        if(my_ap.verifyAT(addressofAA,msg.sender,2,"Permit")==true){
            return my_ap.sendKey(msg.sender,"4008b1066bd42a3625dbd4fc4e95275533e49b51590d9856c96996e6063357ae");
        }
        return false;
    }
}

abstract contract AT is ERC20("UD Token","UD",100), Ballot, Owned{
    
    string public Symbol;
    string public Name;
    uint8 public Decimals;
    uint256 public Totalsupply;
    
    mapping(address => uint) balances;
    mapping(uint256 => Data) CheckAttribute;
    mapping (address => bool) public frozenAccount;
    
    event Sendtoken(address from, address to, uint tokens);
    event FrozenFunds(address target, bool frozen);
    
    struct Data{
        uint256 AttributeID;
        string attribute;
        string approve;
    }
    
    function AttributeToken() public{
        Symbol = symbol();
        Name = name();
        Decimals = decimals();
        Totalsupply = totalSupply();
        balances[addressofAA] = Totalsupply;
    }
    
    
    function checkAttribute(uint256 AttributeID, string memory attribute, string memory approve) public returns (bool success){
        CheckAttribute[AttributeID] = Data(AttributeID, attribute, approve);
        return true;
    }
    function sendToken(address to, uint tokens) public returns (bool success){
        require(!frozenAccount[to]);
        emit Sendtoken(msg.sender, to, tokens);
        return true;
    }
    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }
}

abstract contract DO is ERC20{
    uint256 allowed;
    event Sendkey(address from, address to, bytes encryptedKey);
    event VerifyAT(address to, uint tokens, bytes approve);
    
    struct AESData{
        bytes encryptedKey;
    }
    function sendKey(address to, bytes memory encryptedKey) public returns (bool success){
        emit Sendkey (msg.sender, to, encryptedKey);
        return true;
    }
    function verifyAT(address from, address to, uint tokens, bytes memory approve) public returns (bool success){
        allowed= allowance(to,from); 
        allowed = tokens;
        require(balanceOf(to) >= balanceOf(from));
        emit VerifyAT(to, tokens, approve);
        return true;
    }
}


