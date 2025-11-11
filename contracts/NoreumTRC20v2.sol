// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * Noreum (NOR) — TRC20 Token v2 (Official)
 * -----------------------------------------
 * Decimals: 18
 * Initial Supply: 18,000,000,000 NOR (minted to deployer)
 *
 * Description:
 * This contract represents the wrapped NOR token on TRON,
 * corresponding 1:1 to the native NOR coin on the Noreum Layer-1 mainnet (chainId 1177).
 *
 * Purpose:
 * - Serves as the official TRC20 bridge asset and early market representation.
 * - Provides liquidity and price discovery before full Layer-1 listing.
 * - Supports future bridging via `bridgeMint` and `bridgeBurn`.
 *
 * Governance:
 * - v1 (6 decimals) was experimental and deprecated.
 * - v2 (18 decimals) is canonical and permanent.
 * - Owner can later transfer control to a DAO, multisig, or canonical bridge.
 */

contract NoreumTRC20v2 {
    string public name = "Noreum";
    string public symbol = "NOR";
    uint8 public decimals = 18;

    uint256 public totalSupply;
    address public owner;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    constructor() {
        owner = msg.sender;

        // 18,000,000,000 * 10^18 = 18e27 units (full supply)
        uint256 initialSupply = 18_000_000_000 * 10**uint256(decimals);
        totalSupply = initialSupply;
        _balances[msg.sender] = initialSupply;

        emit Transfer(address(0), msg.sender, initialSupply);
        emit OwnershipTransferred(address(0), msg.sender);
    }

    // ===== TRC20 Standard =====

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function allowance(address tokenOwner, address spender) external view returns (uint256) {
        return _allowances[tokenOwner][spender];
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        uint256 currentAllowance = _allowances[from][msg.sender];
        require(currentAllowance >= amount, "allowance too low");
        unchecked {
            _approve(from, msg.sender, currentAllowance - amount);
        }
        _transfer(from, to, amount);
        return true;
    }

    // ===== Bridge & Admin Hooks =====

    function bridgeMint(address to, uint256 amount) external onlyOwner {
        require(to != address(0), "zero addr");
        totalSupply += amount;
        _balances[to] += amount;
        emit Transfer(address(0), to, amount);
    }

    function bridgeBurn(address from, uint256 amount) external onlyOwner {
        require(from != address(0), "zero addr");
        uint256 bal = _balances[from];
        require(bal >= amount, "balance too low");
        _balances[from] = bal - amount;
        totalSupply -= amount;
        emit Transfer(from, address(0), amount);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "zero addr");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    // ===== Internal Helpers =====

    function _transfer(address from, address to, uint256 amount) internal {
        require(from != address(0), "from zero");
        require(to != address(0), "to zero");
        uint256 bal = _balances[from];
        require(bal >= amount, "balance too low");
        unchecked {
            _balances[from] = bal - amount;
        }
        _balances[to] += amount;
        emit Transfer(from, to, amount);
    }

    function _approve(address tokenOwner, address spender, uint256 amount) internal {
        require(tokenOwner != address(0), "owner zero");
        require(spender != address(0), "spender zero");
        _allowances[tokenOwner][spender] = amount;
        emit Approval(tokenOwner, spender, amount);
    }
}
