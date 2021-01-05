pragma solidity ^0.4.15;

import "./GasTokenInterface.sol";
import "./MultiSigWallet.sol";

/**
    Multi-sig Wallet with gas token
    Auto calculate the optimal amoun of gas tokens to be burnt
    Gas token in this contract will be burnt
    Need to increase gas limit for each operation so that it can burn gas tokens
    Can use a single gas holder for all multisig
 */
contract MultiSigWalletWithGasToken is MultiSigWallet {

    GasTokenInterface public gasToken;
    address public gasHolder;

    modifier burnGasToken {
        uint256 gasStart = msg.gas;
        _;
        uint256 gasAfter = msg.gas;
        uint256 gasSpent = 21000 + gasStart - gasAfter + 16 * msg.data.length;
        uint256 numberGasBurns = (gasSpent + 14154) / 41947;

        uint256 safeNumberGas;
        if (gasAfter >= 27710) {
            safeNumberGas = (gasAfter - 27710) / 7020; // (1148 + 5722 + 150)
        }
        if (numberGasBurns > safeNumberGas) {
            numberGasBurns = safeNumberGas;
        }
        if (numberGasBurns == 0) return;

        if (gasHolder == address(this)) {
            gasToken.freeUpTo(numberGasBurns);
        } else {
            gasToken.freeFromUpTo(gasHolder, numberGasBurns);
        }
    }

    function MultiSigWalletWithGasToken(
        address[] _owners,
        uint _required,
        GasTokenInterface _gasToken,
        address _gasHolder
    )
        public MultiSigWallet(_owners, _required)
    {
        require(_gasToken != address(0));
        gasToken = _gasToken;
        gasHolder = _gasHolder != address(0) ? _gasHolder : address(this);
    }

    /// @dev set _gasHolder == address(0) if want to use gas from this contract
    function updateGasInfo(
        GasTokenInterface _gasToken,
        address _gasHolder
    ) public onlyWallet {
        require(_gasToken != address(0));
        gasToken = _gasToken;
        gasHolder = _gasHolder != address(0) ? _gasHolder : address(this);
    }

    /// @dev Allows an owner to submit and confirm a transaction with burning gas
    /// @param destination Transaction target address.
    /// @param value Transaction ether value.
    /// @param data Transaction data payload.
    function submitTransactionWithGasToken(address destination, uint value, bytes data)
        public burnGasToken
        returns (uint transactionId)
    {
        transactionId = super.submitTransaction(destination, value, data);
    }

    /// @dev Allows an owner to confirm a transaction with burning gas
    /// @param transactionId Transaction ID.
    function confirmTransactionWithGasToken(uint transactionId)
        public burnGasToken
    {
        super.confirmTransaction(transactionId);
    }

    /// @dev Allows an owner to revoke a confirmation for a transaction with burning gas
    /// @param transactionId Transaction ID.
    function revokeConfirmationWithGasToken(uint transactionId)
        public burnGasToken
    {
        super.revokeConfirmation(transactionId);
    }

    /// @dev Allows anyone to execute a confirmed transaction with burning gas
    /// @param transactionId Transaction ID.
    function executeTransactionWithGasToken(uint transactionId)
        public burnGasToken
    {
        super.executeTransaction(transactionId);
    }
}
