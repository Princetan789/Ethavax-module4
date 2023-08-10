// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract DegenGaming is ERC20, Ownable, ERC20Burnable, Pausable {
    mapping(address => bool) private _blacklisted;
    mapping(uint256 => Reward) public rewards;

    struct Reward {
        string name;
        uint256 value;
    }

    event TokensMinted(address indexed to, uint256 value);
    event AccountBlacklisted(address indexed account);
    event AccountUnblacklisted(address indexed account);
    event RewardRedeemed(address indexed player, string itemName);
    event RewardAdded(uint256 indexed rewardId, string name, uint256 value);
    event RewardUpdated(uint256 indexed rewardId, string newName, uint256 newValue);

    constructor() ERC20("DegenGaming", "DGT") {}

    function mintTokens(address to, uint256 amount) external onlyOwner whenNotPaused {
        require(!isBlacklisted(to), "Player's account is blacklisted due to misconduct");
        _mint(to, amount);
        emit TokensMinted(to, amount);
    }


    function rewardRedeem(uint256 choice) external whenNotPaused {
        require(choice <= 3, "Invalid selection");
        Reward memory selectedReward = rewards[choice];
        require(selectedReward.value > 0, "Reward not available");

        require(balanceOf(msg.sender) >= selectedReward.value, "Not enough balance");
        transfer(owner(), selectedReward.value * 80 / 100); // Transfer 80% of reward value to owner
        emit RewardRedeemed(msg.sender, selectedReward.name);
    }
    
    function rewardsStore() public pure returns (string memory) {
        return "1. Diamond Sword (value = 1000 DGT)\n2. Nether Armour (value = 800 DGT)\n3. Diamond Chestplate (value = 500 DGT)";
    }

    function addReward(uint256 rewardId, string memory name, uint256 value) external onlyOwner {
        rewards[rewardId] = Reward(name, value);
        emit RewardAdded(rewardId, name, value);
    }

    function updateReward(uint256 rewardId, string memory newName, uint256 newValue) external onlyOwner {
        require(rewards[rewardId].value > 0, "Reward does not exist");
        rewards[rewardId].name = newName;
        rewards[rewardId].value = newValue;
        emit RewardUpdated(rewardId, newName, newValue);
    }

    function blacklistAccount(address account) external onlyOwner {
        _blacklisted[account] = true;
        emit AccountBlacklisted(account);
    }

    function unblacklistAccount(address account) external onlyOwner {
        _blacklisted[account] = false;
        emit AccountUnblacklisted(account);
    }

    function isBlacklisted(address account) public view returns (bool) {
        return _blacklisted[account];
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function transfer(address recipient, uint256 amount) public override whenNotPaused returns (bool) {
        require(!isBlacklisted(msg.sender), "Sender's account is blacklisted");
        require(!isBlacklisted(recipient), "Recipient's account is blacklisted");
        return super.transfer(recipient, amount);
    }

    function emergencyWithdraw() external onlyOwner {
        address payable ownerPayable = payable(owner());
        ownerPayable.transfer(address(this).balance);
    }

    function burnMyTokens(uint256 amount) external {
        require(balanceOf(msg.sender) >= amount, "Not enough balance");
        _burn(msg.sender, amount);
    }

    function buyTokens() external payable whenNotPaused {
        require(msg.value > 0, "Must send some Ether");
        uint256 tokensToMint = msg.value * 10; // Adjust the conversion rate as needed
        _mint(msg.sender, tokensToMint);
        emit TokensMinted(msg.sender, tokensToMint);
    }
}
