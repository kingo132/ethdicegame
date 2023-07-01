const SimpleStorage = artifacts.require("SimpleStorage");
const DiceGame = artifacts.require('DiceGame');

contract('SimpleStorage', (accounts) => {
  it('should store the value 89.', async () => {
    const simpleStorageInstance = await SimpleStorage.deployed();
    await simpleStorageInstance.set(89, { from: accounts[0] });

    const storedData = await simpleStorageInstance.get.call();

    assert.equal(storedData, 89, "The value 89 was not stored.");
  });
});

contract('DiceGame', (accounts) => {
  let game;

  beforeEach(async () => {
    game = await DiceGame.new();
  });

  it('should allow to become a banker with sufficient deposit', async () => {
    await game.becomeBanker({ from: accounts[0], value: web3.utils.toWei('40', 'ether') });

    const banker = await game.banker();
    const deposit = await game.bankerDeposit();

    assert.equal(banker, accounts[0]);
    assert.equal(deposit, web3.utils.toWei('40', 'ether'));
  });

  it('should allow betting during the betting period', async () => {
    await game.becomeBanker({ from: accounts[0], value: web3.utils.toWei('40', 'ether') });

    // simulate waiting 30 seconds
    await new Promise((resolve) => setTimeout(resolve, 30000));

    await game.checkBankerSettled({ from: accounts[1] });
    await game.bet(0, { from: accounts[1], value: web3.utils.toWei('1', 'ether') });

    const player = await game.players(accounts[1]);

    assert.equal(player.betAmount, web3.utils.toWei('1', 'ether'));
    assert.equal(player.betType.toNumber(), 0);

    game.rollDice();
  });

  // add more tests...
});
