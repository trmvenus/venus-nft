// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @notice - This is the Venus NFT contract
 */
contract Mars is ERC20, ERC20Burnable, Ownable {
    // Mapping from manager address to flag
    mapping(address => bool) private _managers;

    event ManagerAppended(address indexed newManager);

    constructor(string memory _name, string memory _symbol)
        ERC20(_name, _symbol)
    { }

    modifier onlyManagers() {
        require(_managers[_msgSender()] == true, "Mars: caller is not the manager");
        _;
    }

    function mint(address account, uint256 amount) public onlyManagers {
        super._mint(account, amount);
    }

    function addManager(address newManager) public onlyOwner {
        _managers[newManager] = true;
    }

    function _addManager(address newManager) private {
        emit ManagerAppended(newManager);
    }
}
