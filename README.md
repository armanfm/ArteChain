# 🎨 ArteChain — Registro Descentralizado de Arte Digital

> *"Todo dia, artistas brasileiros têm suas obras copiadas, repostadas e vendidas sem crédito e sem compensação. O ArteChain resolve isso."*

---

## O Problema

O mercado de arte digital no Brasil e no mundo enfrenta uma crise de autoria:

- **Plágio silencioso** — obras são copiadas com um print screen e revendidas como originais
- **Sem prova de autoria** — artistas não têm como provar que criaram primeiro
- **Burocracia cara** — registrar no INPI custa centenas de reais e demora meses
- **Sem compensação** — mesmo quando a obra é vendida várias vezes, o criador original não recebe nada

---

## A Solução

O **ArteChain** é um sistema descentralizado de registro e proteção de obras de arte digitais que combina três tecnologias:

- **Blockchain (Ethereum Sepolia)** — registro imutável de autoria
- **Chainlink Functions** — ponte segura entre blockchain e inteligência artificial
- **Gemini Vision (Google)** — análise automática de originalidade

### Como funciona em 3 passos

```
1. Artista faz upload da obra
      → sistema pina automaticamente no IPFS (Pinata)
      → obra recebe um CID único e imutável

2. Chainlink Functions analisa
      → busca a imagem no IPFS
      → envia para o Gemini Vision
      → IA analisa originalidade e possível plágio
      → resultado é pinado no IPFS como prova permanente

3. NFT é emitido automaticamente
      → artista recebe NFT ERC-721 na carteira
      → NFT aponta para a análise completa no IPFS
      → propriedade pode ser transferida ou vendida
```

---

## Diferenciais

### ✅ Análise automática de plágio
Nenhuma plataforma existente faz isso. O Gemini Vision analisa visualmente se a obra é original antes de registrar — sem intervenção humana, sem custo extra.

### ✅ Tudo descentralizado
Sem servidor central. Os contratos rodam na blockchain, as imagens ficam no IPFS, a análise é feita pelos nós do Chainlink. Ninguém pode censurar ou apagar.

### ✅ Verificação pública de plágio
Qualquer pessoa pode fazer upload de uma imagem suspeita e o sistema compara automaticamente com todas as obras registradas usando IA — funciona como um buscador de plágio descentralizado.

### ✅ NFT transferível
O certificado de autoria é um NFT padrão ERC-721 — pode ser vendido, transferido ou usado como prova em processos legais.

### ✅ Registro em segundos, não meses
Comparado ao INPI que demora meses e custa caro, o ArteChain registra em segundos e cobra apenas o gas da transação.

---

## Arquitetura

```
┌─────────────────┐     registrar(CID)      ┌─────────────────┐
│   Artista       │ ──────────────────────► │   Arte.sol      │
│   (MetaMask)    │                          │   (Registro)    │
└─────────────────┘                          └────────┬────────┘
                                                      │ solicitar()
                                                      ▼
                                             ┌─────────────────┐
                                             │ ArteOracle.sol  │
                                             │ (Chainlink)     │
                                             └────────┬────────┘
                                                      │ executa JS
                                                      ▼
                                             ┌─────────────────┐
                                             │  Gemini Vision  │
                                             │  (Google AI)    │
                                             └────────┬────────┘
                                                      │ análise
                                                      ▼
                                             ┌─────────────────┐
                                             │  Pinata (IPFS)  │
                                             │  pina resultado │
                                             └────────┬────────┘
                                                      │ CID análise
                                                      ▼
                                             ┌─────────────────┐
                                             │  ArteNFT.sol    │
                                             │  mint automático│
                                             └─────────────────┘
```

---

## Contratos (Sepolia Testnet)

| Contrato | Função |
|---|---|
| `Arte.sol` | Registro das obras, lista de CIDs, callbacks |
| `ArteOracle.sol` | Integração Chainlink Functions + Gemini + Pinata |
| `ArteNFT.sol` | Token ERC-721 de certificado de autoria |

---

## Stack Tecnológica

| Tecnologia | Uso |
|---|---|
| Solidity 0.8.20 | Contratos inteligentes |
| Chainlink Functions | Execução de código off-chain de forma descentralizada |
| Gemini Vision (Google) | Análise de originalidade e detecção de plágio |
| IPFS + Pinata | Armazenamento descentralizado das obras e análises |
| ERC-721 | Padrão NFT para certificado de autoria |
| MetaMask + Ethers.js | Conexão com a carteira do usuário |

---

## Por que Chainlink Functions?

O Chainlink Functions é o componente central que torna o ArteChain possível. Ele permite que o contrato inteligente **chame APIs externas de forma descentralizada e verificável** — sem depender de um servidor central que poderia ser comprometido ou censurado.

Quando um artista registra uma obra:
1. O contrato dispara uma requisição para o DON (Decentralized Oracle Network)
2. Múltiplos nós independentes executam o mesmo código JS
3. O resultado é consensado e devolvido ao contrato
4. Ninguém — nem o dono do contrato — pode manipular a análise

---

## Instalação e Uso

### Pré-requisitos
- MetaMask instalado
- ETH de teste na Sepolia ([faucet](https://sepoliafaucet.com/))

### Como usar
1. Abra o `artechain.html` no navegador
2. Conecte o MetaMask (rede Sepolia)
3. Cole os endereços dos contratos + Pinata JWT
4. Faça upload da sua obra
5. Clique em **Registrar obra**
6. Aguarde a análise do Gemini e o mint do NFT

### Verificar plágio
1. Vá na aba **🔍 Verificar plágio**
2. Informe sua Gemini API Key
3. Faça upload da imagem suspeita
4. O sistema compara com todas as obras registradas

---



## Equipe

Projeto desenvolvido para o **Hackweb 2026** como solução original para o problema de autoria e plágio no mercado de arte digital brasileiro.

Armando Freire e Izabella Fernandez

---

*ArteChain — Sua arte. Sua prova. Para sempre.*
