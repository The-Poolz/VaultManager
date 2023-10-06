// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IVaultManager.sol";
import "./VaultManagerEvents.sol";
import "../Vault/Vault.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@poolzfinance/poolz-helper-v2/contracts/Array.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "./SignCheck.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


contract VaultManager is
    IVaultManager,
    VaultManagerEvents,
    Ownable,
    ERC2981,
    SignCheck,
    ReentrancyGuard
{
    mapping(uint => address) public vaultIdToVault;
    mapping(uint => uint) public vaultIdToTradeStartTime;
    mapping(address => uint[]) public tokenToVaultIds;
    mapping(uint => bool) public isDepositActiveForVaultId;
    mapping(uint => bool) public isWithdrawalActiveForVaultId;

    address[] public allTokens; // just an array of all tokens
    address public trustee;
    uint public totalVaults;

    modifier vaultExists(uint _vaultId) {
        require(
            vaultIdToVault[_vaultId] != address(0),
            "VaultManager: Vault not found"
        );
        _;
    }

    modifier isTrustee() {
        require(trustee == msg.sender, "VaultManager: Not Trustee");
        _;
    }

    modifier isDepositActive(uint _vaultId) {
        require(
            isDepositActiveForVaultId[_vaultId],
            "VaultManager: Deposits are frozen"
        );
        _;
    }

    modifier isWithdrawalActive(uint _vaultId) {
        require(
            isWithdrawalActiveForVaultId[_vaultId],
            "VaultManager: Withdrawals are frozen"
        );
        _;
    }

    modifier notZeroAddress(address _address) {
        require(
            _address != address(0),
            "VaultManager: Zero address not allowed"
        );
        _;
    }

    modifier notEOA(address _address) {
        require(_address.code.length > 0, "VaultManager: EOA not allowed");
        _;
    }

    /**
     * @dev will be used only once to set the trustee address initially.
     */
    function setTrustee(
        address _address
    ) external onlyOwner notZeroAddress(_address) notEOA(_address) {
        require(trustee == address(0), "VaultManager: Trustee already set");
        trustee = _address;
    }

    function setTradeStartTime(
        uint _vaultId,
        uint _tradeStartTime
    ) public onlyOwner vaultExists(_vaultId) {
        vaultIdToTradeStartTime[_vaultId] = _tradeStartTime;
    }

    /**
     * @dev will be used to update the trustee address. This function will need extra approvals to be called.
     */
    function updateTrustee(
        address _address
    ) external onlyOwner notZeroAddress(_address) notEOA(_address) {
        require(trustee != address(0), "VaultManager: Trustee not set yet");
        trustee = _address;
    }

    function setActiveStatusForVaultId(
        uint _vaultId,
        bool _depositStatus,
        bool _withdrawStatus
    ) external onlyOwner vaultExists(_vaultId) {
        isDepositActiveForVaultId[_vaultId] = _depositStatus;
        isWithdrawalActiveForVaultId[_vaultId] = _withdrawStatus;
    }

    function createNewVault(
        address _tokenAddress
    ) external onlyOwner returns (uint vaultId) {
        vaultId = _createNewVault(_tokenAddress);
    }

    function createNewVault(
        address _tokenAddress,
        uint _tradeStartTime
    ) external onlyOwner returns (uint vaultId) {
        vaultId = _createNewVault(_tokenAddress);
        setTradeStartTime(vaultId, _tradeStartTime);
    }

    function createNewVault(
        address _tokenAddress,
        address _royaltyReceiver,
        uint96 _feeNumerator
    ) external onlyOwner returns (uint vaultId) {
        vaultId = _createNewVault(_tokenAddress);
        _setVaultRoyalty(
            vaultId,
            _tokenAddress,
            _royaltyReceiver,
            _feeNumerator
        );
    }

    function createNewVault(
        address _tokenAddress,
        uint _tradeStartTime,
        address _royaltyReceiver,
        uint96 _feeNumerator
    ) external onlyOwner returns (uint vaultId) {
        vaultId = _createNewVault(_tokenAddress);
        setTradeStartTime(vaultId, _tradeStartTime);
        _setVaultRoyalty(
            vaultId,
            _tokenAddress,
            _royaltyReceiver,
            _feeNumerator
        );
    }

    /// @dev used to create vaults with royalty
    /// @param _royaltyReceiver address of the royalty receiver
    /// @param _feeNumerator is set in basis points
    /// @param _feeNumerator 100 points = 1% of the sale price will be sent to the receiver
    /// @param _feeNumerator 500 points = 5% of the sale price will be sent to the receiver
    /// @param _feeNumerator 1000 points = 10% of the sale price will be sent to the receiver
    function _setVaultRoyalty(
        uint _vaultId,
        address _tokenAddress,
        address _royaltyReceiver,
        uint96 _feeNumerator
    ) private notZeroAddress(_royaltyReceiver) {
        require(
            _feeNumerator <= _feeDenominator(),
            "VaultManager: Royalty cannot be more than 100%"
        );
        _setTokenRoyalty(_vaultId, _royaltyReceiver, _feeNumerator);
        emit VaultRoyaltySet(
            _vaultId,
            _tokenAddress,
            _royaltyReceiver,
            _feeNumerator
        );
    }

    function _createNewVault(
        address _tokenAddress
    ) private notZeroAddress(_tokenAddress) returns (uint vaultId) {
        Vault newVault = new Vault(_tokenAddress);
        vaultId = totalVaults++;
        vaultIdToVault[vaultId] = address(newVault);
        tokenToVaultIds[_tokenAddress].push(vaultId);
        Array.addIfNotExsist(allTokens, _tokenAddress);
        isDepositActiveForVaultId[vaultId] = true;
        isWithdrawalActiveForVaultId[vaultId] = true;
        emit NewVaultCreated(vaultId, _tokenAddress);
    }

    /*
     * @dev Will be used by the Trustee to deposit tokens to the vault.
     * @param _from Trustee is responsible to provide the correct _from address.
     */
    function depositByToken(
        address _tokenAddress,
        uint _amount
    )
        external
        override
        nonReentrant
        isTrustee
        isDepositActive(getCurrentVaultIdByToken(_tokenAddress))
        returns (uint vaultId)
    {
        uint balanceBefore = getVaultBalanceByVaultId(
            getCurrentVaultIdByToken(_tokenAddress)
        );
        vaultId = getCurrentVaultIdByToken(_tokenAddress);
        address vaultAddress = vaultIdToVault[vaultId];
        assert(_tokenAddress == Vault(vaultAddress).tokenAddress());
        IERC20(_tokenAddress).transferFrom(trustee, vaultAddress, _amount);
        emit Deposited(vaultId, _tokenAddress, _amount);
        assert(getVaultBalanceByVaultId(vaultId) == balanceBefore + _amount);
    }

    function safeDeposit(
        address _tokenAddress,
        uint _amount,
        address _from,
        bytes memory _signature
    )
        external
        override
        nonReentrant
        isTrustee
        isDepositActive(getCurrentVaultIdByToken(_tokenAddress))
        returns (uint vaultId)
    {
        // Encode the data into a single bytes array
        bytes memory dataToCheck = abi.encodePacked(
            _tokenAddress,
            _from,
            _amount
        );

        // Use the _checkData function from SignCheck
        require(
            _checkData(_from, dataToCheck, _signature),
            "VaultManager: Only origin can deposit"
        );
        vaultId = getCurrentVaultIdByToken(_tokenAddress);
        address vaultAddress = vaultIdToVault[vaultId];
        assert(_tokenAddress == Vault(vaultAddress).tokenAddress());
        IERC20(_tokenAddress).transferFrom(_from, vaultAddress, _amount);
        // emit Deposited(vaultId, _tokenAddress, _from, _amount);
    }

    /**
     * @dev Will be used by the Trustee to deposit tokens to the vault.
     * @param _to Trustee is responsible to provide the correct _to address.
     */
    function withdrawByVaultId(
        uint _vaultId,
        address _to,
        uint _amount
    )
        external
        override
        isTrustee
        nonReentrant
        vaultExists(_vaultId)
        isWithdrawalActive(_vaultId)
    {
        uint balanceBefore = getVaultBalanceByVaultId(_vaultId);
        Vault vault = Vault(vaultIdToVault[_vaultId]);
        vault.withdraw(_to, _amount);
        emit Withdrawn(_vaultId, vault.tokenAddress(), _to, _amount);
        assert(getVaultBalanceByVaultId(_vaultId) == balanceBefore - _amount);
    }

    function getVaultBalanceByVaultId(
        uint _vaultId
    ) public view vaultExists(_vaultId) returns (uint) {
        return Vault(vaultIdToVault[_vaultId]).tokenBalance();
    }

    function getCurrentVaultBalanceByToken(
        address _tokenAddress
    ) external view returns (uint) {
        return
            Vault(vaultIdToVault[getCurrentVaultIdByToken(_tokenAddress)])
                .tokenBalance();
    }

    function getAllVaultBalanceByToken(
        address _tokenAddress
    ) external view returns (uint balance) {
        uint[] memory vaultIds = tokenToVaultIds[_tokenAddress];
        for (uint i = 0; i < vaultIds.length; i++) {
            balance += Vault(vaultIdToVault[vaultIds[i]]).tokenBalance();
        }
    }

    function getTotalVaultsByToken(
        address _tokenAddress
    ) public view returns (uint _totalVaults) {
        _totalVaults = tokenToVaultIds[_tokenAddress].length;
    }

    function getCurrentVaultIdByToken(
        address _tokenAddress
    ) public view returns (uint vaultId) {
        require(
            getTotalVaultsByToken(_tokenAddress) > 0,
            "VaultManager: No vaults for this token"
        );
        vaultId = tokenToVaultIds[_tokenAddress][
            getTotalVaultsByToken(_tokenAddress) - 1
        ];
    }

    function getAllTokens() external view returns (address[] memory) {
        return allTokens;
    }

    function getTotalNumberOfTokens() external view returns (uint) {
        return allTokens.length;
    }

    function vaultIdToTokenAddress(
        uint _vaultId
    ) external view override vaultExists(_vaultId) returns (address token) {
        token = Vault(vaultIdToVault[_vaultId]).tokenAddress();
    }
}
