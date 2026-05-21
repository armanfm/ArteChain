# 💰 ArteChain — Vantagens Econômicas

## O problema do registro tradicional

Hoje, um artista brasileiro que quer proteger sua obra precisa enfrentar:

| Aspecto | Biblioteca Nacional (EDA/FBN) |
|---------|-------------------------------|
| Custo (pessoa física) | **R$ 40,00** |
| Custo (pessoa jurídica) | **R$ 80,00** |
| Certidão de busca | R$ 40,00 |
| Tempo de processamento | **30 a 90 dias** |
| Forma de envio | Presencial ou Correios |
| Documentação | Física (papel + CD/PDF) |
| Verificação de plágio | Manual, sem garantias |
| Alcance | Apenas Brasil |
| Imutabilidade | Depende do servidor da Fundação |

*Fonte: Instrução Normativa nº 02/2024 — Biblioteca Nacional, vigente desde janeiro de 2025.*

---

## A solução ArteChain

O ArteChain entrega o mesmo serviço — com **menos custo, mais rapidez e verificação automática de originalidade**.

### Custo por obra

| Plataforma | Custo | Tempo | Verificação anti-plágio |
|------------|-------|-------|--------------------------|
| **Biblioteca Nacional** | R$ 40 (PF) / R$ 80 (PJ) | 30-90 dias | ❌ Não tem |
| **Verisart / Artory** | R$ 25 a R$ 150 + assinatura | imediato | ❌ Não tem |
| **ArteChain (Ethereum Mainnet)** | ~R$ 24 | 30 segundos | ✅ IA + on-chain |
| **ArteChain (Polygon/Base)** | ~R$ 5 a R$ 7 | 30 segundos | ✅ IA + on-chain |

### Decomposição do custo na Ethereum Mainnet

```
Etapa 1 — Registro do pHash via Chainlink Functions
  ≈ 0.2 LINK   →  R$ 9,60

Etapa 2 — Análise visual com Gemini via Chainlink
  ≈ 0.3 LINK   →  R$ 14,40

TOTAL                R$ 24,00
```

### Decomposição em Layer 2 (Polygon ou Base)

```
Mesmas duas chamadas Chainlink   ≈  R$ 24,00
Mas o gás cai para               ≈  R$ 0,50
                                 ─────────
TOTAL                                R$ 24,50
```

*(O custo Chainlink é o mesmo. O ganho real está no gás das transações de registro e mint, que em L2 ficam praticamente gratuitos.)*

---

## Comparação direta

```
Biblioteca Nacional:     R$ 40       90 dias       sem IA
ArteChain Ethereum:      R$ 24       30 segundos   com IA
                         ─────────────────────────────────
                         40% mais barato
                         99,99% mais rápido
                         + verificação automática
```

---

## Diferenciais que NENHUM concorrente entrega

```
✅ Verificação automática de similaridade visual
   → algoritmo pHash DCT roda ON-CHAIN
   → Hamming distance em Solidity verificável

✅ Análise por IA
   → Gemini Vision compara obra nova com a mais similar
   → resultado fica registrado no IPFS

✅ NFT opcional ERC-721
   → autor decide se quer comercializar
   → registro é independente do NFT

✅ Imutabilidade real
   → blockchain pública, não servidor centralizado
   → ninguém pode "perder" sua obra

✅ Internacional desde o dia 1
   → qualquer pessoa no mundo registra
   → reconhecido em qualquer jurisdição que aceite blockchain

✅ Sem burocracia
   → wallet + clique = registro
   → sem CPF, sem Correios, sem papel
```

---

## Mercado-alvo

```
🎨 Artistas digitais independentes
   → não têm dinheiro pra R$ 40 + advogado
   → R$ 24 cabe no bolso

🎨 Criadores internacionais
   → não conseguem registrar no Brasil
   → ArteChain é global

🎨 NFT artists
   → já estão no Web3
   → registro on-chain é natural

🎨 Estúdios de design
   → registram centenas de obras/mês
   → economia escala
```

---

## Cálculo de economia anual

```
Cenário: artista que registra 20 obras por ano

Biblioteca Nacional:    20 × R$ 40 = R$ 800/ano
ArteChain Ethereum:     20 × R$ 24 = R$ 480/ano
ArteChain Polygon/Base: 20 × R$ 7  = R$ 140/ano

Economia anual: R$ 320 (Ethereum) ou R$ 660 (L2)
```

---

## Pitch direto pra mentoria

> "Pra registrar uma obra de arte no Brasil hoje você paga R$ 40, espera 90 dias, manda papel pelos Correios e ainda assim ninguém verifica se a obra é original — só guardam o que você enviou.
>
> O ArteChain cobra R$ 24, demora 30 segundos, é totalmente digital e ainda verifica automaticamente similaridade com todas as obras já registradas usando IA on-chain. E em Layer 2 o custo cai pra R$ 5.
>
> É 40% mais barato, 99% mais rápido e com uma funcionalidade que nem o órgão oficial oferece."

---

## Fontes

- Biblioteca Nacional — Instrução Normativa nº 02/2024 (vigente desde 01/01/2025)
- Poder360 — *Biblioteca Nacional muda taxas de direitos autorais após 18 anos*
- Agência Brasil — *Biblioteca Nacional: digitalização facilita registro para autores*
- Coinbase/CoinMarketCap — preço LINK em maio/2026 (~US$ 9,65)
- Documentação Chainlink Functions — custo médio por request

