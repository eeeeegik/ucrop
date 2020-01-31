pragma solidity ^0.4.11;

contract Ownable {

  address public owner;

  function Ownable() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner, "Только owner может вызвать эту функцию");
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    owner = newOwner;
  }

}

contract Brain is Ownable{
    
    uint256 public tokensAmount = 0;
    uint256 public maxUcropPerCDPValue = 100;
    uint256 public maxUcropPerClient = 1000;
    uint256 public lastEtherRateInfo = 111;

    address public ucropTokenAddress;
    
    mapping(address=>uint256) public tokensPerClient; //учет количества токенов по каждому клиенту
    mapping(address=>address) public CDPHolder;  //Это и все, что ниже дешевле хранить в токене?
    mapping(address=>uint256) public CDPDeposit; //
    mapping(address=>uint256) public CDPUcropGiven; // до сюда
    
    address[] public contracts; // index of created contracts
    
    function setUcropTokenAddress(address _newUcropTokenAddress)
    onlyOwner
    public
    {
        ucropTokenAddress = _newUcropTokenAddress;
    }
    
    modifier onlyToken()
    {
        require(ucropTokenAddress == msg.sender);
        _;
    }

    function getContractCount() // useful to know the row count in contracts index
        public
        constant
        returns(uint CDPCount)
    {
        return contracts.length;
    }
    
    modifier isLimit(uint256 _amountToGet) {
        require(_amountToGet <= maxUcropPerCDPValue && _amountToGet > 0, "Желаемое количество превышает максимально возможное для одного CDP");
        require(tokensPerClient[msg.sender] + _amountToGet <= maxUcropPerClient, "Желаемое количество превышает максимально возможное для одного клиента");
        _;
    }

    function createNewCDP(uint256 _depositedEther, address _clientAddress, uint256 _givenTokens) //deploy a new contract
        //isLimit(_amountToGet)
        public
        onlyToken
        returns(address newCDP)
    {
        CDP c = new CDP(_depositedEther, lastEtherRateInfo, _clientAddress, _givenTokens);
        contracts.push(c);
        CDPHolder[c] = _clientAddress;
        CDPDeposit[c] = _depositedEther;
        CDPUcropGiven[c] = _givenTokens;
        //c.transferOwnership(_clientAddress);
        tokensAmount = tokensAmount + _givenTokens;
        return c;
    }
    
    modifier CDPUcropGivenCheck(address _CDP, uint _value)
    {
        require(CDPUcropGiven[_CDP]==_value, "вы должны полностью вернуть то же количество токенов, сколько взяли у данного CDP");
        
        _;
    }
    
     modifier CDPHolderCheck(address _CDP, address _client)
    {
        require(1==1, "только владелец CDP может закрыть CDP");
        _;
    }
    
    function startKillingCDP(address _CDP, uint _value, address _client)
    onlyToken
    CDPUcropGivenCheck(_CDP, _value)
    CDPHolderCheck(_CDP, _client)//пустышка. TODO: реализовать логику открытия аукциона
    returns (bool successStartKilling)
    {
        return true;
    }
    
    function deleteAllCDPInfo(address _CDP) 
    onlyToken
    returns (uint DepositValue)
    {
        delete CDPUcropGiven[_CDP];
        delete CDPHolder[_CDP];
        DepositValue = CDPDeposit[_CDP];
        delete CDPDeposit[_CDP];
        return DepositValue;
    }
    
    //информация о курсе валюты
    function broadcastRate(uint _1EtherCost, uint32 _UcropEtherRatio)
        public
        onlyOwner
    {
        for(uint i=0; i < contracts.length; i++)
        {
            CDP existingCDP = CDP(contracts[i]); //обращаемся к каждому адресу существующих CDP
            existingCDP.getRateInfo(_1EtherCost); //сообщаем им информацию о курсе эфира
        }
        lastEtherRateInfo = _1EtherCost;
        
        UcropToken workingToken = UcropToken(ucropTokenAddress);
        workingToken.setRate(_UcropEtherRatio);  //сообщаем токену информацию о курсе Укропа к Эфиру
    }

    
}

contract CDP is Ownable{
    
    uint256 public EtherDeposited; //количество заблокированного эфира, на этом CDP
    uint256 public lastRateInfo; //последняя полученная информация о курсе Эфира
    uint256 public UcropGiven;
    address public clientAddress; //адрес покупателя токенов
    bool public canBeClosedOnlyByClient = true; //флаг, что CDP может быть закрыт только покупателем токенов
    uint256 tokenAmount;
    address tokenAddress;//когда токен будет задеплоен, станет доступен

    constructor (uint256 _EtherDeposited, uint256 _lastRateInfo, address _clientAddress, uint _UcropGiven) public {
        EtherDeposited = _EtherDeposited;
        lastRateInfo = _lastRateInfo;
        clientAddress = _clientAddress;
        //tokenAmount = calcTokenAmount(_lastRateInfo);
        UcropGiven = _UcropGiven;
    }
    
    /*function calcTokenAmount(uint _lastEtherRateInfo)
    internal 
    returns (uint256 calculatedTokenAmount)
    {
        uint256 a = ( uint(_lastEtherRateInfo) / 2); //двойное крипто-обеспечение 
        return a; //выдаем токенов в два раза меньше стоимости внесенного эфира
    }*/
    
    function getRateInfo(uint _1EtherCost) 
        external
        onlyOwner
    {
        lastRateInfo = _1EtherCost;
        
        //в случае, если курс Эфира ниже допустимого минимума
        if(lastRateInfo < 75)
        {
            toAuctionOff();
        }
    }

    //выставление содержимого CDP на открытый аукцион
    function toAuctionOff()
        private
    {
        canBeClosedOnlyByClient = false;
    }
    
    
    /*function() payable {
        uint256 UcropAmount = msg.value;
        uint256 tokens = tokenAmount;
        //??
        //u.mint(msg.sender, tokens); // пробую написать специальную функцию генерации токенов в CDP
        
    }*/
    
    function killCDP() 
    onlyOwner
    {
        selfdestruct(owner);
    }

  
}


contract UcropToken is Ownable{
    
    string public constant name = "Ucrop token";
    string public constant symbol = "ucr";
    uint32 constant public decimals = 18;
    uint32 public rate = 2; 
    uint256 public totalSupply ;
    address public BrainAddress;
    mapping(address=>uint256) public balances;
    mapping (address => mapping(address => uint)) allowed;
    
  function mint(address  _to, uint _value, uint _depositedEther) internal {
    assert(totalSupply + _value >= totalSupply && balances[_to] + _value >= balances[_to]);
    balances[_to] += _value;
    totalSupply += _value;
    
    Brain b = Brain(BrainAddress);
    b.createNewCDP(_depositedEther, _to, _value);  //вызов функции создания CDP в Brain
  }

  function balanceOf(address _owner) public constant returns (uint balance) {
    return balances[_owner];
  }

  function transfer(address _to, uint _value) public returns (bool success) {
      if(balances[msg.sender] >= _value && balances[_to] + _value >= balances[_to]) 
      {
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
      }
      return false;
    }
  
  function StartClosingCDP(address _CDP, uint _value) 
  public
  returns (bool successStartClosingCDP)
  {
    if(balances[msg.sender] >= _value /* && balances[address(this)] + _value >= balances[address(this)]*/)
        {
            Brain b = Brain(BrainAddress);
            b.startKillingCDP(_CDP, _value, msg.sender);
            balances[msg.sender] -= _value;
            balances[address(this)] += _value;
            Transfer(msg.sender, address(this), _value);
            
            uint EtherDeposit = b.deleteAllCDPInfo(_CDP);
            msg.sender.transfer(EtherDeposit);
            return true;
        }
    return false;
  }
  
  

  function transferFrom(address _from, address _to, uint _value) public returns (bool success) {
    if( allowed[_from][msg.sender] >= _value &&
    balances[_from] >= _value
    && balances[_to] + _value >= balances[_to]) {
      allowed[_from][msg.sender] -= _value;
      balances[_from] -= _value;
      balances[_to] += _value;
      Transfer(_from, _to, _value);
      return true;
    }
    return false;
  }

  function approve(address _spender, uint _value) public returns (bool success) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) public constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }

  event Transfer(address indexed _from, address indexed _to, uint _value);

  event Approval(address indexed _owner, address indexed _spender, uint _value);

  function getTokenAmount(uint256 _value) internal view returns (uint256) {
    return _value / rate;
  }

  function setRate(uint32 _value) public
  onlyBrain
  {
      rate = _value;
  }
  
  modifier onlyBrain()
  {
      require(msg.sender == BrainAddress, "только Brain может устанавливать rate");
      _;
  }

  function setBrainAddress(address _newBrainAddress)
  onlyOwner
  {
      BrainAddress = _newBrainAddress;
  }


  /*function returnEther(address _to, uint _returnedUcropAmount, uint _CDPDeposit)
  //onlyBrain
  balancesPositive(_to)
  equal(_returnedUcropAmount, _CDPDeposit)
  public
  {
      balances[_to] = balances[_to] - _returnedUcropAmount;
      _to.transfer(_CDPDeposit);
  }
  
  modifier balancesPositive(address _client)
  {
      require(balances[_client] > 0);
      _;
  }
  
  modifier equal(uint _returnedUcropAmount, uint _CDPDeposit)
  {
      require(_returnedUcropAmount == _CDPDeposit, "количество возвращаемых Ucrop должно быть равно долгу CDP ");
      _;
  }*/

  function () payable {
    uint256 weiAmount = msg.value;
    uint256 tokens = getTokenAmount(weiAmount);
    mint(msg.sender, tokens, weiAmount);
  }

}
