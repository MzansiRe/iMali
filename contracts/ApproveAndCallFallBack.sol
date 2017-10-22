pragma solidity ^0.4.17;

/**
 * @title ApproveAndCallFallBack
 * @dev Used to ping receiver of approval
 */
contract ApproveAndCallFallBack { 
  function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; 
}
