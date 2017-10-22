pragma solidity ^0.4.17;

import "https://github.com/MzansiRe/iMali/blob/master/MiniMeToken.sol";

/**
 * @title iMaliToken
 * @dev the iMali token implementation with parameters
 */
contract iMaliToken is MiniMeToken {
    
    // one hundred million tokens is the total initial supply
    uint256 public INITIAL_SUPPLY = 100000000 * 10**18;

    /* constructor - must supply a MiniMeTokenFactory address */
    function iMaliToken (address _tokenFactory) 
    public MiniMeToken(_tokenFactory, // factory address
                        address(0x0), // no parent token
                        0,            // no parent token snapshot block
                        "iMali2",     // the glorious token name
                        18,           // eighteen decimals 
                        "IML2",       // token symbol
                        false)        // transfers disabled 
    {
        // setting the version 
        version = "IML_v0.2";
        // generate tokens and send to contract deployer
        generateTokens(msg.sender, INITIAL_SUPPLY);
    }
}
