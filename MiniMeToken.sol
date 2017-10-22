pragma solidity ^0.4.17;

import "https://github.com/MzansiRe/iMali/blob/master/SafeMath.sol";
import "https://github.com/MzansiRe/iMali/blob/master/Controlled.sol";
import "https://github.com/MzansiRe/iMali/blob/master/ApproveAndCallFallBack.sol";
import "https://github.com/MzansiRe/iMali/blob/master/MiniMeTokenFactory.sol";
import "https://github.com/MzansiRe/iMali/blob/master/TokenController.sol";

/**
 * @title MiniMeToken
 * @dev A MiniMeToken implementation modified with SafeMath
 * @dev https://github.com/Giveth/minime/blob/master/contracts/MiniMeToken.sol
 */
contract MiniMeToken is Controlled {
using SafeMath for uint256;

    /* basic token parameters */
    string public name;                
    uint8 public decimals;             
    string public symbol;              
    string public version; 

    /* data structure to keep logs on token distribution */
    struct  Checkpoint {
        uint128 fromBlock;
        uint128 value; }

    /* the parent token from which a clone is generated - 0x0 for new token */
    MiniMeToken public parentToken;
    
    /* the block of the parent token from which the clone is generated - 0 for new token */
    uint public parentSnapShotBlock;

    /* block number at which the new token is created */
    uint public creationBlock;

    /* mappings for balances and allowances */
    mapping (address => Checkpoint[]) balances;
    mapping (address => mapping (address => uint256)) allowed;

    /* logs the history of the tokens total supply */
    Checkpoint[] totalSupplyHistory;

    /* switch that enables/disables transfers */
    bool public transfersEnabled;

    /* token factory used to create clones*/
    MiniMeTokenFactory public tokenFactory;

    /* constructor */
    function MiniMeToken(
        address _tokenFactory,
        address _parentToken,
        uint _parentSnapShotBlock,
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol,
        bool _transfersEnabled
    )  public {
        tokenFactory = MiniMeTokenFactory(_tokenFactory);
        name = _tokenName;                                 
        decimals = _decimalUnits;                          
        symbol = _tokenSymbol;                             
        parentToken = MiniMeToken(_parentToken);
        parentSnapShotBlock = _parentSnapShotBlock;
        transfersEnabled = _transfersEnabled;
        creationBlock = block.number;
    }

    /* ERC20 transfer method */
    function transfer(address _to, uint256 _amount) public returns (bool success) {
        require(transfersEnabled);
        return _transfer(msg.sender, _to, _amount); }
   
    /* ERC20 transferFrom method */
    function transferFrom(address _from, address _to, uint256 _amount) public returns (bool success) {
        if (msg.sender != controller) {
            require(transfersEnabled);

            // Check that msg.sender is authorized to spend specified _amount
            if (allowed[_from][msg.sender] < _amount) return false;
            
            // Decrement msg.sender's allowance
            allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
        }
        // Execute transfer
        return _transfer(_from, _to, _amount); }
  
    /* Internal transfer method with SafeMath */
    function _transfer(address _from, address _to, uint _amount) internal returns (bool) {

    // allows for zero _amount transfers - as required by ERC20 standard
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
       if (_amount == 0) { Transfer(_from, _to, _amount);
                           return true; }
    
    // Checks for correct continuity 
       require(parentSnapShotBlock < block.number);
    // Prevent transfer to 0x0 address
        require(_to != address(0));
    // Prevent transfers to this contract's address
        require(_to != address(this));
    
    // Check that _from address has enough tokens for exchange 
        var previousBalanceFrom = balanceOfAt(_from, block.number);
        if (previousBalanceFrom < _amount) {
           return false;
        }
     
    // Alerts the token controller of the transfer
        if (isContract(controller)) {
           require(TokenController(controller).onTransfer(_from, _to, _amount));
        }

    // First update the balance array with the new value for _from address
        updateValueAtNow(balances[_from], previousBalanceFrom.sub(_amount));

    // Then update the balance array with the new value for the _to address
        var previousBalanceTo = balanceOfAt(_to, block.number);
        require(previousBalanceTo.add(_amount) >= previousBalanceTo); // Check for overflow
        updateValueAtNow(balances[_to], previousBalanceTo.add(_amount));

    // Log the event
        Transfer(_from, _to, _amount);

       return true; }  

    /* ERC20 balanceOf method */
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balanceOfAt(_owner, block.number); }

    /* ERC20 approve method */
    function approve(address _spender, uint256 _amount) public returns (bool success) {
        require(transfersEnabled);

        // To change the approve amount you first have to reduce the addresses`
        //  allowance to zero by calling `approve(_spender,0)` if it is not
        //  already 0 to mitigate the race condition described here:
        //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        require((_amount == 0) || (allowed[msg.sender][_spender] == 0));

        // Alerts the token controller of the approve function call
        if (isContract(controller)) {
            require(TokenController(controller).onApprove(msg.sender, _spender, _amount));
        }

        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true; }

    /* ERC20 allowance method */
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender]; }

    /* method used to approve and alert _spender */
    function approveAndCall(address _spender, uint256 _amount, bytes _extraData) public returns (bool success) {
        require(approve(_spender, _amount));

        ApproveAndCallFallBack(_spender).receiveApproval(msg.sender, _amount, this, _extraData);

        return true; }

    /* ERC20 totalSupply method*/
    function totalSupply() public constant returns (uint) {
        return totalSupplyAt(block.number); }

    /* returns balance of _owner at the specified _blockNumber */
    function balanceOfAt(address _owner, uint _blockNumber) public constant
        returns (uint) {

        // These next few lines are used when the balance of the token is
        //  requested before a check point was ever created for this token, it
        //  requires that the `parentToken.balanceOfAt` be queried at the
        //  genesis block for that token as this contains initial balance of
        //  this token
        if ((balances[_owner].length == 0)
            || (balances[_owner][0].fromBlock > _blockNumber)) {
            if (address(parentToken) != 0) {
                return parentToken.balanceOfAt(_owner, min(_blockNumber, parentSnapShotBlock));
            } else {
                // Has no parent
                return 0;
            }

        // This will return the expected balance during normal situations
        } else {
            return getValueAt(balances[_owner], _blockNumber);
        }
    }

    /* returns totalSupply at specified _blockNumber */
    function totalSupplyAt(uint _blockNumber) public constant returns(uint) {

        // These next few lines are used when the totalSupply of the token is
        //  requested before a check point was ever created for this token, it
        //  requires that the `parentToken.totalSupplyAt` be queried at the
        //  genesis block for this token as that contains totalSupply of this
        //  token at this block number.
        if ((totalSupplyHistory.length == 0)
            || (totalSupplyHistory[0].fromBlock > _blockNumber)) {
            if (address(parentToken) != 0) {
                return parentToken.totalSupplyAt(min(_blockNumber, parentSnapShotBlock));
            } else {
                return 0;
            }

        // This will return the expected totalSupply during normal situations
        } else {
            return getValueAt(totalSupplyHistory, _blockNumber);
        }
    }

    /* method to create clone tokens */
    function createCloneToken(
        string _cloneTokenName,
        uint8 _cloneDecimalUnits,
        string _cloneTokenSymbol,
        uint _snapshotBlock,
        bool _transfersEnabled
        ) public returns(address) {
        if (_snapshotBlock == 0) _snapshotBlock = block.number;
        MiniMeToken cloneToken = tokenFactory.createCloneToken(
            this,
            _snapshotBlock,
            _cloneTokenName,
            _cloneDecimalUnits,
            _cloneTokenSymbol,
            _transfersEnabled
            );

        cloneToken.transferControl(msg.sender);

        // An event to make the token easy to find on the blockchain
        NewCloneToken(address(cloneToken), _snapshotBlock);
        return address(cloneToken);
    }

    /* token creation method*/
    function generateTokens(address _owner, uint _amount
    ) onlyController public returns (bool) {
        uint curTotalSupply = totalSupply();
        require(curTotalSupply.add(_amount) >= curTotalSupply); // Check for overflow
        uint previousBalanceTo = balanceOf(_owner);
        require(previousBalanceTo.add(_amount) >= previousBalanceTo); // Check for overflow
        updateValueAtNow(totalSupplyHistory, curTotalSupply.add(_amount));
        updateValueAtNow(balances[_owner], previousBalanceTo.add(_amount));
        Transfer(0, _owner, _amount);
        return true;
    }

    /* token burn method */
    function destroyTokens(address _owner, uint _amount
    ) onlyController public returns (bool) {
        uint curTotalSupply = totalSupply();
        require(curTotalSupply >= _amount);
        uint previousBalanceFrom = balanceOf(_owner);
        require(previousBalanceFrom >= _amount);
        updateValueAtNow(totalSupplyHistory, curTotalSupply.sub(_amount));
        updateValueAtNow(balances[_owner], previousBalanceFrom.sub(_amount));
        Transfer(_owner, 0, _amount);
        return true;
    }

    /* transfer enable/disable method */
    function enableTransfers(bool _transfersEnabled) onlyController public {
        transfersEnabled = _transfersEnabled;
    }

    /* returns the number of tokens at a given block number */
    function getValueAt(Checkpoint[] storage checkpoints, uint _block
    ) constant internal returns (uint) {
        if (checkpoints.length == 0) return 0;

        // Shortcut for the actual value
        if (_block >= checkpoints[checkpoints.length-1].fromBlock)
            return checkpoints[checkpoints.length-1].value;
        if (_block < checkpoints[0].fromBlock) return 0;

        // Binary search of the value in the array
        uint min = 0;
        uint max = checkpoints.length-1;
        while (max > min) {
            uint mid = (max + min + 1)/ 2;
            if (checkpoints[mid].fromBlock<=_block) {
                min = mid;
            } else {
                max = mid-1;
            }
        }
        return checkpoints[min].value;
    }

    /* method to update the `balances` map and the `totalSupplyHistory` */
    function updateValueAtNow(Checkpoint[] storage checkpoints, uint _value
    ) internal  {
        if ((checkpoints.length == 0)
        || (checkpoints[checkpoints.length -1].fromBlock < block.number)) {
               Checkpoint storage newCheckPoint = checkpoints[ checkpoints.length++ ];
               newCheckPoint.fromBlock =  uint128(block.number);
               newCheckPoint.value = uint128(_value);
           } else {
               Checkpoint storage oldCheckPoint = checkpoints[checkpoints.length-1];
               oldCheckPoint.value = uint128(_value);
           }
    }

    /* method to check if queried _address is a contract */
    function isContract(address _addr) constant internal returns(bool) {
        uint size;
        if (_addr == 0) return false;
        assembly {
            size := extcodesize(_addr)
        }
        return size>0;
    }

    /* returns the minimum of two uint arguments */
    function min(uint a, uint b) pure internal returns (uint) {
        return a < b ? a : b;
    }

    /// @notice The fallback function: If the contract's controller has not been
    ///  set to 0, then the `proxyPayment` method is called which relays the
    ///  ether and creates tokens as described in the token controller contract
    function () public  payable {
        require(isContract(controller));
        require(TokenController(controller).proxyPayment.value(msg.value)(msg.sender));
    }


    /// @notice This method can be used by the controller to extract mistakenly
    ///  sent tokens to this contract.
    /// @param _token The address of the token contract that you want to recover
    ///  set to 0 in case you want to extract ether.
    function claimTokens(address _token) onlyController public {
        if (_token == 0x0) {
            controller.transfer(this.balance);
            return;
        }

        MiniMeToken token = MiniMeToken(_token);
        uint balance = token.balanceOf(this);
        token.transfer(controller, balance);
        ClaimedTokens(_token, controller, balance);
    }

    /* events */
    event ClaimedTokens(address indexed _token, address indexed _controller, uint _amount);
    event Transfer(address indexed _from, address indexed _to, uint256 _amount);
    event NewCloneToken(address indexed _cloneToken, uint _snapshotBlock);
    event Approval(address indexed _owner, address indexed _spender, uint256 _amount);

}
