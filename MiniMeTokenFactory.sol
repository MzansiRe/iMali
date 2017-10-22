pragma solidity ^0.4.17;

import "https://github.com/MzansiRe/iMali/blob/master/Controlled.sol";

/**
 * @title MiniMeTokenFactory
 * @dev used to create clone tokens
 */
contract MiniMeTokenFactory is Controlled {

    address public _address;

    /* clone creation method */
    function createCloneToken(
        address _parentToken,
        uint _snapshotBlock,
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol,
        bool _transfersEnabled
    ) public returns (MiniMeToken) {
        MiniMeToken newToken = new MiniMeToken(
            this,
            _parentToken,
            _snapshotBlock,
            _tokenName,
            _decimalUnits,
            _tokenSymbol,
            _transfersEnabled
            );
        
        _address = address(this);
        newToken.transferControl(msg.sender);
        return newToken;
    }
    
}
