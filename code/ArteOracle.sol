// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@chainlink/contracts/src/v0.8/functions/v1_0_0/FunctionsClient.sol";
import "@chainlink/contracts/src/v0.8/functions/v1_0_0/libraries/FunctionsRequest.sol";

// ─────────────────────────────────────────
// Interfaces
// ─────────────────────────────────────────

interface IArte {

    function aprovar(
        string memory cidObra,
        string memory cidAnalise,
        string memory pHash
    ) external;

    function rejeitar(
        string memory cidObra,
        string memory cidAnalise,
        string memory pHash
    ) external;

    function getObrasAprovadas()
        external
        view
        returns (
            string[] memory cids,
            string[] memory pHashes
        );
}

contract ArteOracle is FunctionsClient {

    using FunctionsRequest for FunctionsRequest.Request;

    // ─────────────────────────────────────────
    // State
    // ─────────────────────────────────────────

    address public owner;
    address public contratoArte;

    uint64  public subscriptionId;
    uint32  public gasLimit;
    bytes32 public donID;

    string  public functionsSource;

    uint8   public secretsSlotId;
    uint64  public secretsVersion;

    struct PendingRequest {
        string  cidObra;
        address autor;
    }

    mapping(bytes32 => PendingRequest) private _pending;

    // ─────────────────────────────────────────
    // Events
    // ─────────────────────────────────────────

    event OracleSolicitado(
        string indexed cidObra,
        bytes32 indexed requestId
    );

    event OracleAprovado(
        string indexed cidObra,
        string cidAnalise
    );

    event OracleRejeitado(
        string indexed cidObra,
        string cidAnalise
    );

    event OracleFalhou(
        string indexed cidObra,
        string erro
    );

    // ─────────────────────────────────────────
    // Constructor
    // ─────────────────────────────────────────

    constructor(
        uint64  _subscriptionId,
        bytes32 _donID,
        uint8   _secretsSlotId,
        uint64  _secretsVersion
    )
        FunctionsClient(
            0xb83E47C2bC239B3bf370bc41e1459A34b41238D0
        )
    {
        owner            = msg.sender;
        subscriptionId   = _subscriptionId;
        donID            = _donID;
        gasLimit         = 300_000;
        secretsSlotId    = _secretsSlotId;
        secretsVersion   = _secretsVersion;
    }

    // ─────────────────────────────────────────
    // Modifiers
    // ─────────────────────────────────────────

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Nao autorizado"
        );
        _;
    }

    modifier onlyArte() {
        require(
            msg.sender == contratoArte,
            "Apenas Arte.sol"
        );
        _;
    }

    // ─────────────────────────────────────────
    // Admin
    // ─────────────────────────────────────────

    function setContratoArte(
        address _arte
    ) external onlyOwner {

        require(
            _arte != address(0),
            "Endereco invalido"
        );

        contratoArte = _arte;
    }

    function setFunctionsSource(
        string calldata _source
    ) external onlyOwner {

        functionsSource = _source;
    }

    function setChainlinkParams(
        uint64  _subId,
        bytes32 _donID,
        uint32  _gasLimit,
        uint8   _slotId,
        uint64  _version
    ) external onlyOwner {

        subscriptionId = _subId;
        donID          = _donID;
        gasLimit       = _gasLimit;
        secretsSlotId  = _slotId;
        secretsVersion = _version;
    }

    // ─────────────────────────────────────────
    // Solicitar análise
    // ─────────────────────────────────────────

    function solicitar(
        string memory cidObra,
        address autor
    ) external onlyArte {

        require(
            bytes(functionsSource).length > 0,
            "functionsSource nao configurado"
        );

        (
            string[] memory cids,
            string[] memory pHashes
        ) = IArte(contratoArte).getObrasAprovadas();

        // limita comparação
        string memory cidsList  = "";
        string memory pHashList = "";

        for (uint i = 0; i < cids.length && i < 10; i++) {

            if (i > 0) {

                cidsList = string(
                    abi.encodePacked(
                        cidsList,
                        ",",
                        cids[i]
                    )
                );

                pHashList = string(
                    abi.encodePacked(
                        pHashList,
                        ",",
                        pHashes[i]
                    )
                );

            } else {

                cidsList  = cids[i];
                pHashList = pHashes[i];
            }
        }

        FunctionsRequest.Request memory req;

        req.initializeRequest(
            FunctionsRequest.Location.Inline,
            FunctionsRequest.CodeLanguage.JavaScript,
            functionsSource
        );

        req.addDONHostedSecrets(
            secretsSlotId,
            secretsVersion
        );

        string[] memory args = new string[](3);

        args[0] = cidObra;
        args[1] = cidsList;
        args[2] = pHashList;

        req.setArgs(args);

        bytes32 requestId = _sendRequest(
            req.encodeCBOR(),
            subscriptionId,
            gasLimit,
            donID
        );

        _pending[requestId] = PendingRequest({
            cidObra: cidObra,
            autor: autor
        });

        emit OracleSolicitado(
            cidObra,
            requestId
        );
    }

    // ─────────────────────────────────────────
    // Callback Chainlink
    // ─────────────────────────────────────────

    function fulfillRequest(
        bytes32 requestId,
        bytes memory response,
        bytes memory err
    ) internal override {

        PendingRequest memory req =
            _pending[requestId];

        if (
            bytes(req.cidObra).length == 0
        ) return;

        delete _pending[requestId];

        // erro Chainlink

        if (err.length > 0) {

            IArte(contratoArte).rejeitar(
                req.cidObra,
                "",
                ""
            );

            emit OracleFalhou(
                req.cidObra,
                string(err)
            );

            return;
        }

        // resposta:
        // APROVADO:cidAnalise:pHash
        // REJEITADO:cidAnalise:pHash

        string memory resultado =
            string(response);

        if (
            _startsWith(
                resultado,
                "APROVADO:"
            )
        ) {

            (
                string memory cidAnalise,
                string memory pHash
            ) = _parseResposta(
                _slice(resultado, 9)
            );

            IArte(contratoArte).aprovar(
                req.cidObra,
                cidAnalise,
                pHash
            );

            emit OracleAprovado(
                req.cidObra,
                cidAnalise
            );

        } else {

            (
                string memory cidAnalise,
                string memory pHash
            ) = _parseResposta(
                _slice(resultado, 10)
            );

            IArte(contratoArte).rejeitar(
                req.cidObra,
                cidAnalise,
                pHash
            );

            emit OracleRejeitado(
                req.cidObra,
                cidAnalise
            );
        }
    }

    // ─────────────────────────────────────────
    // Helpers
    // ─────────────────────────────────────────

    function _startsWith(
        string memory str,
        string memory prefix
    )
        internal
        pure
        returns (bool)
    {
        bytes memory s = bytes(str);
        bytes memory p = bytes(prefix);

        if (s.length < p.length)
            return false;

        for (uint i = 0; i < p.length; i++) {

            if (s[i] != p[i])
                return false;
        }

        return true;
    }

    function _slice(
        string memory str,
        uint256 from
    )
        internal
        pure
        returns (string memory)
    {
        bytes memory s = bytes(str);

        if (from >= s.length)
            return "";

        bytes memory result =
            new bytes(s.length - from);

        for (
            uint i = from;
            i < s.length;
            i++
        ) {
            result[i - from] = s[i];
        }

        return string(result);
    }

    // cidAnalise:pHash

    function _parseResposta(
        string memory str
    )
        internal
        pure
        returns (
            string memory cidAnalise,
            string memory pHash
        )
    {
        bytes memory b = bytes(str);

        uint splitAt = b.length;

        for (uint i = 0; i < b.length; i++) {

            if (b[i] == 0x3A) {
                splitAt = i;
                break;
            }
        }

        bytes memory cid =
            new bytes(splitAt);

        bytes memory hash =
            new bytes(
                b.length > splitAt + 1
                    ? b.length - splitAt - 1
                    : 0
            );

        for (uint i = 0; i < splitAt; i++) {
            cid[i] = b[i];
        }

        for (
            uint i = splitAt + 1;
            i < b.length;
            i++
        ) {
            hash[i - splitAt - 1] = b[i];
        }

        return (
            string(cid),
            string(hash)
        );
    }
}
