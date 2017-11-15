pragma solidity ^0.4.17;

import "./MiniMeToken.sol";
import "./MiniMeTokenFactory.sol";

/**
 * @title iMaliToken
 * @dev the iMali token implementation with parameters
 */
contract iMaliToken is MiniMeToken {


    /* constructor - must supply a MiniMeTokenFactory address */
    function iMaliToken (address _tokenFactory) 
    public MiniMeToken(_tokenFactory, // factory address
                        address(0x0), // no parent token
                        0,            // no parent token snapshot block
                        "iMali3",      // the glorious token name
                        18,           // eighteen decimals 
                        "IML3",        // token symbol
                        true)         // transfers enabled 
    {
        // setting the version 
        version = "IML_v0.3";
    }
}