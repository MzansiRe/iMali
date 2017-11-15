'use strict';
const assertJump = require("./assertJump.js");

var Ownable = artifacts.require("./Controlled.sol");

contract('Ownable', function(accounts) {
  let ownable;

  beforeEach(async function() {
    ownable = await Ownable.new();
  });

  it('should have an owner', async function() {
    let owner = await ownable.controller();
    assert.isTrue(owner !== 0);
  });

  it('changes owner after transfer', async function() {
    let other = accounts[1];
    await ownable.transferControl(other);
    let owner = await ownable.controller();

    assert.isTrue(owner === other);
  });

  it('should prevent non-owners from transfering', async function() {
    const other = accounts[2];
    const owner = await ownable.controller.call();
    assert.isTrue(owner !== other);
    try {
      await ownable.transferControl(other, {from: other});
      assert.fail('should have thrown before');
    } catch(error) {
      assertJump(error);
    }
  });
/*
  it('should guard ownership against stuck state', async function() {
    let originalOwner = await ownable.controller();
    try {
      await ownable.transferControl(null, {from: originalOwner});
      assert.fail();
    } catch(error) {
      assertJump(error);
    }
  });*/

});