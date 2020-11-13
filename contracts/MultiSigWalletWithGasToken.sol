pragma solidity ^0.4.15;

import "./GasTokenInterface.sol";
import "./MultiSigWallet.sol";

/**
    Multi-sig Wallet with gas token
    Auto calculate the optimal amoun of gas tokens to be burnt
    Gas token in this contract will be burnt
    Need to increase gas limit for each operation so that it can burn gas tokens
 */
contract MultiSigWalletWithGasToken is MultiSigWallet {

    // Total gas consumption for the tx:
    // tx_gas + baseGasConsumption + x * burntGasConsumption where x is number of gas tokens that are burnt
    // gas refunded: refundedGasPerToken * x
    // refundedGasPerToken * x <= 1/2 * (tx_gas + baseGasConsumption + x * burntGasConsumption)
    // example using GST2: https://gastoken.io/
    // baseGasConsumption: 14,154
    // burntGasConsumption: 6,870
    // refundedGasPerToken: 24,000
    struct GasTokenConfiguration {
        GasTokenInterface gasToken;
        uint64 baseGasConsumption;
        uint64 burntGasConsumption;
        uint64 refundedGasPerToken;
    }

    GasTokenConfiguration public gasTokenConfig;

    function MultiSigWalletWithGasToken(
        address[] _owners,
        uint _required,
        GasTokenInterface _gasToken,
        uint64 _baseGasConsumption,
        uint64 _burntGasConsumption,
        uint64 _refundedGasPerToken
    )
        public MultiSigWallet(_owners, _required)
    {
        require(_gasToken != address(0));
        require(_baseGasConsumption > 0);
        require(_burntGasConsumption > 0);
        require(_refundedGasPerToken > _burntGasConsumption);

        gasTokenConfig = GasTokenConfiguration({
            gasToken: _gasToken,
            baseGasConsumption: _baseGasConsumption,
            burntGasConsumption: _burntGasConsumption,
            refundedGasPerToken: _refundedGasPerToken
        });
    }

    function updateGasToken(
        GasTokenInterface _gasToken,
        uint64 _baseGasConsumption,
        uint64 _burntGasConsumption,
        uint64 _refundedGasPerToken
    ) public onlyWallet {
        require(_gasToken != address(0));
        require(_baseGasConsumption > 0);
        require(_burntGasConsumption > 0);
        require(_refundedGasPerToken > _burntGasConsumption);

        gasTokenConfig = GasTokenConfiguration({
            gasToken: _gasToken,
            baseGasConsumption: _baseGasConsumption,
            burntGasConsumption: _burntGasConsumption,
            refundedGasPerToken: _refundedGasPerToken
        });
    }

    /// @dev Allows an owner to submit and confirm a transaction.
    /// @param destination Transaction target address.
    /// @param value Transaction ether value.
    /// @param data Transaction data payload.
    function submitTransaction(address destination, uint value, bytes data)
        public
        returns (uint transactionId)
    {
        uint gasBefore = msg.gas;
        transactionId = super.submitTransaction(destination, value, data);
        freeGas(gasBefore);
    }

    /// @dev Allows an owner to confirm a transaction.
    /// @param transactionId Transaction ID.
    function confirmTransaction(uint transactionId)
        public
    {
        uint gasBefore = msg.gas;
        super.confirmTransaction(transactionId);
        freeGas(gasBefore);
    }

    /// @dev Allows an owner to revoke a confirmation for a transaction.
    /// @param transactionId Transaction ID.
    function revokeConfirmation(uint transactionId)
        public
    {
        uint gasBefore = msg.gas;
        super.revokeConfirmation(transactionId);
        freeGas(gasBefore);
    }

    /// @dev Allows anyone to execute a confirmed transaction.
    /// @param transactionId Transaction ID.
    function executeTransaction(uint transactionId)
        public
    {
        uint gasBefore = msg.gas;
        super.executeTransaction(transactionId);
        freeGas(gasBefore);
    }

    function freeGas(uint gasBefore) internal {
        uint safe_num_tokens = 0;
        uint gasAfter = msg.gas;

        GasTokenConfiguration memory config = gasTokenConfig;

        // total gas use: gasBefore - gasAfter + baseGasConsumption + x * burntGasConsumption
        // refunded: x * refundedGasPerToken
        // x * refundedGasPerToken <= 1/2 * (gasBefore - gasAfter + baseGasConsumption + x * burntGasConsumption)
        // x <= (gasBefore - gasAfter + baseGasConsumption) / (2 * refundedGasPerToken - burntGasConsumption)
        uint num_tokens = (gasBefore - gasAfter + uint(config.baseGasConsumption))
            / uint(2 * config.refundedGasPerToken - config.burntGasConsumption); 

        if (gasAfter >= 27710) {
            safe_num_tokens = (gasAfter - 27710) / 7020; // (1148 + 5722 + 150);
        }

        if (num_tokens > safe_num_tokens) {
            num_tokens = safe_num_tokens;
        }

        if (num_tokens > 0) {
            config.gasToken.freeUpTo(num_tokens);
        }
    }
}
