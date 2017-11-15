var SafeMath = artifacts.require("./SafeMath.sol");
var Controlled = artifacts.require("./Controlled.sol");
var TokenController = artifacts.require("./TokenController.sol");
var MiniMeTokenFactory = artifacts.require("./MiniMeTokenFactory.sol");
var MiniMeToken = artifacts.require("./MiniMeToken.sol");
var iMaliToken = artifacts.require("iMaliToken.sol");
var Campaign = artifacts.require("./Campaign.sol");

module.exports = function(deployer) {
  deployer.deploy(MiniMeTokenFactory)
  .then(function() {
   return deployer.deploy(iMaliToken,MiniMeTokenFactory.address);
  });
  deployer.deploy(Campaign);
};
  
  /*
deployer.deploy(MiniMeTokenFactory)
.then(function() {
  return deployer.deploy(iMaliToken, MiniMeTokenFactory.address);
});*/
