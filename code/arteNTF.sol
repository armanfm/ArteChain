// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract ArteNFT is ERC721 {

    // ─────────────────────────────────────────
    // Structs
    // ─────────────────────────────────────────

    struct TokenData {
        string cidObra;
        string cidAnalise;
        address autor;
        uint256 timestamp;
    }

    // ─────────────────────────────────────────
    // State
    // ─────────────────────────────────────────

    address public owner;
    address public contratoOracle;

    uint256 private _nextTokenId;

    mapping(uint256 => TokenData) private _tokens;

    // cidObra => tokenId
    mapping(string => uint256) public tokenDaObra;

    // cidObra => aprovado pelo oracle
    mapping(string => bool) public obraAprovada;

    // cidObra => CID da análise
    mapping(string => string) public cidAnaliseDaObra;

    // ─────────────────────────────────────────
    // Events
    // ─────────────────────────────────────────

    event ObraAprovada(
        string indexed cidObra,
        string cidAnalise
    );

    event ObraMintada(
        string indexed cidObra,
        string cidAnalise,
        address indexed autor,
        uint256 tokenId
    );

    // ─────────────────────────────────────────
    // Constructor
    // ─────────────────────────────────────────

    constructor() ERC721("ArteChain", "ARTE") {
        owner = msg.sender;
        _nextTokenId = 1;
    }

    // ─────────────────────────────────────────
    // Modifiers
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
    // Admin
    // ─────────────────────────────────────────

    function setContratoOracle(address _oracle) external onlyOwner {
        require(_oracle != address(0), "Endereco invalido");
        contratoOracle = _oracle;
    }

    // ─────────────────────────────────────────
    // Oracle aprova obra
    // NÃO minta automaticamente
    // ─────────────────────────────────────────

    function aprovarObra(
        string memory cidObra,
        string memory cidAnalise
    ) external onlyOracle {

        require(bytes(cidObra).length > 0, "CID invalido");
        require(bytes(cidAnalise).length > 0, "CID analise invalido");

        obraAprovada[cidObra] = true;
        cidAnaliseDaObra[cidObra] = cidAnalise;

        emit ObraAprovada(cidObra, cidAnalise);
    }

    // ─────────────────────────────────────────
    // Mint manual
    // Usuario escolhe mintar
    // ─────────────────────────────────────────

    function mintManual(
        string memory cidObra
    ) external {

        require(
            obraAprovada[cidObra],
            "Obra nao aprovada"
        );

        require(
            tokenDaObra[cidObra] == 0,
            "NFT ja existe"
        );

        uint256 tokenId = _nextTokenId++;

        _safeMint(msg.sender, tokenId);

        _tokens[tokenId] = TokenData({
            cidObra: cidObra,
            cidAnalise: cidAnaliseDaObra[cidObra],
            autor: msg.sender,
            timestamp: block.timestamp
        });

        tokenDaObra[cidObra] = tokenId;

        emit ObraMintada(
            cidObra,
            cidAnaliseDaObra[cidObra],
            msg.sender,
            tokenId
        );
    }

    // ─────────────────────────────────────────
    // tokenURI
    // aponta pro CID da análise
    // ─────────────────────────────────────────

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {

        require(
            ownerOf(tokenId) != address(0),
            "Token nao existe"
        );

        return string(
            abi.encodePacked(
                "ipfs://",
                _tokens[tokenId].cidAnalise
            )
        );
    }

    // ─────────────────────────────────────────
    // Consultar token
    // ─────────────────────────────────────────

    function getToken(
        uint256 tokenId
    )
        public
        view
        returns (
            string memory cidObra,
            string memory cidAnalise,
            address autor,
            uint256 timestamp
        )
    {
        require(
            ownerOf(tokenId) != address(0),
            "Token nao existe"
        );

        TokenData memory t = _tokens[tokenId];

        return (
            t.cidObra,
            t.cidAnalise,
            t.autor,
            t.timestamp
        );
    }

    // ─────────────────────────────────────────
    // Consultar aprovação
    // ─────────────────────────────────────────

    function obraFoiAprovada(
        string memory cidObra
    ) public view returns (bool) {

        return obraAprovada[cidObra];
    }

    // ─────────────────────────────────────────
    // Total mintado
    // ─────────────────────────────────────────

    function totalMintado()
        public
        view
        returns (uint256)
    {
        return _nextTokenId - 1;
    }
}
