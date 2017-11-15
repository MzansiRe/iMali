var campaign = artifacts.require("./Campaign.sol");

it("should fail because time is before start of campaign", async function () {
    let meta = await campaign.deployed();
    try {
      await meta.theFloatMultiplier.call(1512086300);
    } catch (e) {
      return true;
    }
    throw new Error("I should never see this!")
  })