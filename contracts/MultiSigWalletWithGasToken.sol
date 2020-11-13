pragma solidity ^0.4.15;

import "./GasTokenInterface.sol";
import "./MultiSigWallet.sol";

/**
    Multi-sig Wallet with gas token
    Owner should specify the amount of gas token to burn for each operation
    Gas token in this contract will be burnt
    Need to increase gas limit for each operation so that it can burn gas tokens
 */
contract MultiSigWalletWithGasToken is MultiSigWallet {
    GasTokenInterface public gasToken;

    function MultiSigWalletWithGasToken(
        address[] _owners,
        uint _required,
        GasTokenInterface _gasToken
    )
        public MultiSigWallet(_owners, _required)
    {
        require(_gasToken != address(0));
        gasToken = _gasToken;
    }

    function updateGasToken(GasTokenInterface _gasToken) public onlyWallet {
        require(_gasToken != address(0));
        gasToken = _gasToken;
    }

    /// @dev Allows an owner to submit and confirm a transaction.
    /// @param destination Transaction target address.
    /// @param value Transaction ether value.
    /// @param data Transaction data payload.
    /// @param numGasBurn Number gas tokens to be burnt
    /// @return Returns transaction ID.
    function submitTransaction(address destination, uint value, bytes data, uint numGasBurn)
        public
        returns (uint transactionId)
    {
        transactionId = super.submitTransaction(destination, value, data);
        freeGas(numGasBurn);
    }

    /// @dev Allows an owner to confirm a transaction.
    /// @param transactionId Transaction ID.
    /// @param numGasBurn Number gas tokens to be burnt
    function confirmTransaction(uint transactionId, uint numGasBurn)
        public
    {
        super.confirmTransaction(transactionId);
        freeGas(numGasBurn);
    }

    /// @dev Allows an owner to revoke a confirmation for a transaction.
    /// @param transactionId Transaction ID.
    /// @param numGasBurn Number gas tokens to be burnt
    function revokeConfirmation(uint transactionId, uint numGasBurn)
        public
    {
        super.revokeConfirmation(transactionId);
        freeGas(numGasBurn);
    }

    /// @dev Allows anyone to execute a confirmed transaction.
    /// @param transactionId Transaction ID.
    /// @param numGasBurn Number gas tokens to be burnt
    function executeTransaction(uint transactionId, uint numGasBurn)
        public
    {
        super.executeTransaction(transactionId);
        freeGas(numGasBurn);
    }

    function freeGas(uint num_tokens) internal {
        uint safe_num_tokens = 0;
        uint gas = msg.gas;

        if (gas >= 27710) {
            safe_num_tokens = (gas - 27710) / 7020; // (1148 + 5722 + 150);
        }

        if (num_tokens > safe_num_tokens) {
            num_tokens = safe_num_tokens;
        }

        if (num_tokens > 0) {
            gasToken.freeUpTo(num_tokens);
        }
    }
}
