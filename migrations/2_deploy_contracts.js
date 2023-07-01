const MyContract = artifacts.require("MyContract");
const SimpleStorage = artifacts.require("SimpleStorage");
const DiceGame = artifacts.require("DiceGame");
const Strings = artifacts.require("Strings");

module.exports = function(deployer) {
  deployer.deploy(MyContract);
  deployer.deploy(SimpleStorage);
  deployer.deploy(DiceGame);
  deployer.deploy(Strings);
};
