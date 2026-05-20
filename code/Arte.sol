// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IArteOracle {
    function solicitar(string memory cidObra, address autor) external;
}

contract Arte {

    // ─────────────────────────────────────────
    //  Structs
    // ─────────────────────────────────────────

    struct Obra {
        address autor;
        string  cidObra;    // CID da imagem no IPFS
        string  pHash;      // hash perceptual calculado pelo Chainlink
        string  cidAnalise; // vazio = pendente
        bool    aprovada;   // true = aprovada, false = rejeitada
        uint256 timestamp;
    }

    // ─────────────────────────────────────────
    //  State
    // ─────────────────────────────────────────

    mapping(string => Obra) public obras;
    string[] public listaObras;

    address public owner;
    address public contratoOracle;
    address public contratoNFT;

    // ─────────────────────────────────────────
    //  Events
    // ─────────────────────────────────────────

    event ObraRegistrada (string indexed cidObra, address indexed autor);
    event ObraAprovada   (string indexed cidObra, string cidAnalise);
    event ObraRejeitada  (string indexed cidObra, string cidAnalise);

    // ─────────────────────────────────────────
    //  Constructor
    // ─────────────────────────────────────────

    constructor() {
        owner = msg.sender;
    }

    // ─────────────────────────────────────────
    //  Modifiers
    // ─────────────────────────────────────────

    modifier onlyOwner() {
        require(msg.sender == owner, "Nao autorizado");
        _;
    }

    modifier onlyOracle() {
        require(msg.sender == contratoOracle, "Apenas o Oracle");
        _;
    }

    // ─────────────────────────────────────────
    //  Admin
    // ─────────────────────────────────────────

    function setContratoOracle(address _oracle) external onlyOwner {
        require(_oracle != address(0), "Endereco invalido");
        contratoOracle = _oracle;
    }

    function setContratoNFT(address _nft) external onlyOwner {
        require(_nft != address(0), "Endereco invalido");
        contratoNFT = _nft;
    }

    // ─────────────────────────────────────────
    //  Registrar obra
    // ─────────────────────────────────────────

    function registrar(string memory cidObra) public {
        require(contratoOracle != address(0), "Oracle nao configurado");
        require(bytes(cidObra).length > 0, "CID invalido");
        require(obras[cidObra].timestamp == 0, "Obra ja registrada");

        obras[cidObra] = Obra({
            autor:      msg.sender,
            cidObra:    cidObra,
            pHash:      "",   // calculado pelo Chainlink
            cidAnalise: "",   // vazio = pendente
            aprovada:   false,
            timestamp:  block.timestamp
        });
        listaObras.push(cidObra);

        emit ObraRegistrada(cidObra, msg.sender);

        IArteOracle(contratoOracle).solicitar(cidObra, msg.sender);
    }

    // ─────────────────────────────────────────
    //  Callbacks do Oracle
    // ─────────────────────────────────────────

    function aprovar(
        string memory cidObra,
        string memory cidAnalise,
        string memory pHash
    ) external onlyOracle {
        require(obras[cidObra].timestamp != 0, "Obra nao existe");
        require(bytes(obras[cidObra].cidAnalise).length == 0, "Obra ja analisada");
        obras[cidObra].cidAnalise = cidAnalise;
        obras[cidObra].pHash      = pHash;
        obras[cidObra].aprovada   = true;
        emit ObraAprovada(cidObra, cidAnalise);
    }

    function rejeitar(
        string memory cidObra,
        string memory cidAnalise,
        string memory pHash
    ) external onlyOracle {
        require(obras[cidObra].timestamp != 0, "Obra nao existe");
        require(bytes(obras[cidObra].cidAnalise).length == 0, "Obra ja analisada");
        obras[cidObra].cidAnalise = cidAnalise;
        obras[cidObra].pHash      = pHash;
        obras[cidObra].aprovada   = false;
        emit ObraRejeitada(cidObra, cidAnalise);
    }

    // ─────────────────────────────────────────
    //  Consultas
    // ─────────────────────────────────────────

    function getObra(string memory cidObra) public view returns (
        address autor,
        string memory pHash,
        string memory cidAnalise,
        bool aprovada,
        uint256 timestamp,
        bool pendente
    ) {
        Obra memory o = obras[cidObra];
        return (
            o.autor,
            o.pHash,
            o.cidAnalise,
            o.aprovada,
            o.timestamp,
            bytes(o.cidAnalise).length == 0
        );
    }

    // Retorna CIDs e pHashes das obras aprovadas
    // Chainlink chama isso via RPC pra montar o banco de comparação
    function getObrasAprovadas() public view returns (
        string[] memory cids,
        string[] memory pHashes
    ) {
        uint256 count = 0;
        for (uint i = 0; i < listaObras.length; i++) {
            if (obras[listaObras[i]].aprovada) count++;
        }
        cids    = new string[](count);
        pHashes = new string[](count);
        uint256 j = 0;
        for (uint i = 0; i < listaObras.length; i++) {
            if (obras[listaObras[i]].aprovada) {
                cids[j]    = listaObras[i];
                pHashes[j] = obras[listaObras[i]].pHash;
                j++;
            }
        }
    }

    function totalObras() public view returns (uint256) {
        return listaObras.length;
    }

    function getObrasPorPagina(uint256 offset, uint256 limit) public view returns (string[] memory) {
        uint256 end = offset + limit;
        if (end > listaObras.length) end = listaObras.length;
        if (offset >= end) return new string[](0);
        string[] memory result = new string[](end - offset);
        for (uint i = offset; i < end; i++) result[i - offset] = listaObras[i];
        return result;
    }
}
