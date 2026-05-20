const cidObra   = args[0];
const cidsList  = args[1];
const pHashList = args[2];

const PINATA_JWT = secrets.PINATA_JWT;
const GEMINI_KEY = secrets.GEMINI_KEY;

if (!cidObra)    throw new Error("CID nao fornecido");
if (!PINATA_JWT) throw new Error("PINATA_JWT nao encontrado");
if (!GEMINI_KEY) throw new Error("GEMINI_KEY nao encontrado");

// ── DCT pHash ─────────────────────────────────────────────

function dct1D(arr) {
  const N=arr.length, r=new Array(N).fill(0);
  for(let k=0;k<N;k++){let s=0;for(let n=0;n<N;n++)s+=arr[n]*Math.cos(Math.PI/N*(n+.5)*k);r[k]=s;}
  return r;
}

function calcPHash(grid) {
  const dr=grid.map(r=>dct1D(r));
  const d2=[];
  for(let i=0;i<32;i++)d2[i]=new Array(32).fill(0);
  for(let j=0;j<32;j++){const c=dr.map(r=>r[j]),dc=dct1D(c);for(let i=0;i<32;i++)d2[i][j]=dc[i];}
  const lf=[];
  for(let i=0;i<8;i++)for(let j=0;j<8;j++)lf.push(d2[i][j]);
  const med=lf.slice(1).reduce((a,b)=>a+b,0)/(lf.length-1);
  let bits="";for(let i=0;i<lf.length;i++)bits+=lf[i]>=med?"1":"0";
  let hex="";for(let i=0;i<bits.length;i+=4)hex+=parseInt(bits.slice(i,i+4),2).toString(16);
  return hex;
}

function hamming(h1,h2){
  if(!h1||!h2||h1.length!==h2.length)return 0;
  let d=0;
  for(let i=0;i<h1.length;i++){
    const b1=parseInt(h1[i],16).toString(2).padStart(4,"0");
    const b2=parseInt(h2[i],16).toString(2).padStart(4,"0");
    for(let j=0;j<4;j++)if(b1[j]!==b2[j])d++;
  }
  return Math.round(((h1.length*4-d)/(h1.length*4))*100);
}

function extrairGrid(bytes, ox, oy, wf, hf) {
  const total=bytes.length, SIZE=32, grid=[];
  for(let i=0;i<SIZE;i++){
    grid[i]=[];
    for(let j=0;j<SIZE;j++){
      const px=ox+(j/SIZE)*wf, py=oy+(i/SIZE)*hf;
      const idx=Math.floor((py*Math.sqrt(total)+px)*3);
      const r=bytes[Math.min(idx,total-1)]||0;
      const g=bytes[Math.min(idx+1,total-1)]||0;
      const b=bytes[Math.min(idx+2,total-1)]||0;
      grid[i][j]=0.299*r+0.587*g+0.114*b;
    }
  }
  return grid;
}

function pHashRegiao(bytes,ox,oy,wf,hf){return calcPHash(extrairGrid(bytes,ox,oy,wf,hf));}

// Multi-variação — pega o MAIOR score (igual MarcasChain)
function melhorScore(bytes1, bytes2) {
  const scores=[
    hamming(pHashRegiao(bytes1,0,0,1,1),   pHashRegiao(bytes2,0,0,1,1)),
    hamming(pHashRegiao(bytes1,.15,.15,.7,.7), pHashRegiao(bytes2,.15,.15,.7,.7)),
    hamming(pHashRegiao(bytes1,.25,.25,.5,.5), pHashRegiao(bytes2,.25,.25,.5,.5)),
    hamming(pHashRegiao(bytes1,0,0,.5,1),  pHashRegiao(bytes2,0,0,.5,1)),
    hamming(pHashRegiao(bytes1,.5,0,.5,1), pHashRegiao(bytes2,.5,0,.5,1)),
    hamming(pHashRegiao(bytes1,0,0,1,.5),  pHashRegiao(bytes2,0,0,1,.5)),
    hamming(pHashRegiao(bytes1,0,.5,1,.5), pHashRegiao(bytes2,0,.5,1,.5)),
  ];
  return Math.max(...scores);
}

// ── 1. Baixar imagem nova ─────────────────────────────────

const res = await Functions.makeHttpRequest({
  url:`https://gateway.pinata.cloud/ipfs/${cidObra}`,
  method:"GET", responseType:"arraybuffer", timeout:7000
});
if(res.error||!res.data) throw new Error("Falha ao baixar imagem");

const bytes1=new Uint8Array(res.data);
let bin="";for(let i=0;i<bytes1.length;i++)bin+=String.fromCharCode(bytes1[i]);
const img1b64=btoa(bin);
const img1mime=res.headers?.["content-type"]?.split(";")[0]||"image/jpeg";
const pHashNovo=pHashRegiao(bytes1,0,0,1,1);

// ── 2. Encontra melhor match (maior score) ────────────────

let melhorMatch={cid:null, score:0};

if(cidsList && pHashList){
  const cids=cidsList.split(",").filter(Boolean);
  const hashes=pHashList.split(",").filter(Boolean);
  for(let i=0;i<cids.length;i++){
    const s=hamming(pHashNovo, hashes[i]);
    if(s>melhorMatch.score) melhorMatch={cid:cids[i], score:s};
  }
  // Se tem match, baixa e faz multi-variação
  if(melhorMatch.cid){
    const rm=await Functions.makeHttpRequest({
      url:`https://gateway.pinata.cloud/ipfs/${melhorMatch.cid}`,
      method:"GET", responseType:"arraybuffer", timeout:7000
    });
    if(!rm.error&&rm.data){
      const bytes2=new Uint8Array(rm.data);
      const scoreMulti=melhorScore(bytes1,bytes2);
      if(scoreMulti>melhorMatch.score) melhorMatch.score=scoreMulti;
    }
  }
}

// ── 3. Gemini SEMPRE decide — vê as duas imagens ─────────

let decisao="APROVADO";
let observacao="Obra original — sem similaridade significativa com obras registradas.";
let nivel="BAIXA";

if(melhorMatch.cid){
  // Baixa imagem do match pro Gemini comparar
  const rm2=await Functions.makeHttpRequest({
    url:`https://gateway.pinata.cloud/ipfs/${melhorMatch.cid}`,
    method:"GET", responseType:"arraybuffer", timeout:6000
  });

  let img2b64=null, img2mime="image/jpeg";
  if(!rm2.error&&rm2.data){
    const bytes2=new Uint8Array(rm2.data);
    let bin2="";for(let i=0;i<bytes2.length;i++)bin2+=String.fromCharCode(bytes2[i]);
    img2b64=btoa(bin2);
    img2mime=rm2.headers?.["content-type"]?.split(";")[0]||"image/jpeg";
  }

  if(img2b64){
    const prompt=`Você é o sistema de análise do ArteChain — registro descentralizado de arte digital.
Compare as DUAS imagens (primeira = obra nova sendo registrada, segunda = obra já registrada no sistema com ${melhorMatch.score}% de similaridade de hash).

Você tem a PALAVRA FINAL — aprove ou rejeite independente do score do algoritmo.
Analise o CONTEÚDO VISUAL real das imagens.

REGRAS OBRIGATÓRIAS:
- NÃO use: plágio, cópia, ilegal, infração, crime
- USE: "similaridade visual", "elementos semelhantes", "composição similar"
- Seja técnico e neutro
- A decisão final cabe ao autor e profissionais especializados

Responda APENAS JSON válido sem markdown:
{"decisao":"APROVADO ou REJEITADO","similaridade":<0-100>,"nivel":"BAIXA ou MEDIA ou ALTA","observacao":"<max 60 palavras em português>"}`;

    const gemRes=await Functions.makeHttpRequest({
      url:`https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=${GEMINI_KEY}`,
      method:"POST",
      headers:{"Content-Type":"application/json"},
      data:{
        contents:[{parts:[
          {inline_data:{mime_type:img1mime,data:img1b64}},
          {inline_data:{mime_type:img2mime,data:img2b64}},
          {text:prompt}
        ]}],
        generationConfig:{maxOutputTokens:200,temperature:0.1}
      },
      timeout:7000
    });

    if(!gemRes.error){
      const raw=gemRes.data?.candidates?.[0]?.content?.parts?.[0]?.text||"";
      try{
        const clean=raw.replace(/```json\s*/gi,"").replace(/```\s*/g,"").trim();
        const p=JSON.parse(clean);
        decisao    = p.decisao    || decisao;
        observacao = p.observacao || observacao;
        nivel      = p.nivel      || nivel;
      }catch(e){}
    }
  }
} else {
  // Sem obras pra comparar — Gemini analisa originalidade geral
  const prompt=`Você é o sistema de análise do ArteChain.
Esta é a PRIMEIRA obra sendo registrada ou não há obras similares no sistema.
Analise se esta obra é original (não é cópia de obra famosa, personagem com copyright, etc).
REGRAS: NÃO use: plágio, cópia, ilegal, infração. A decisão final cabe ao autor.
Responda APENAS JSON válido sem markdown:
{"decisao":"APROVADO ou REJEITADO","similaridade":0,"nivel":"BAIXA","observacao":"<max 60 palavras em português>"}`;

  const gemRes=await Functions.makeHttpRequest({
    url:`https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=${GEMINI_KEY}`,
    method:"POST",
    headers:{"Content-Type":"application/json"},
    data:{
      contents:[{parts:[
        {inline_data:{mime_type:img1mime,data:img1b64}},
        {text:prompt}
      ]}],
      generationConfig:{maxOutputTokens:200,temperature:0.1}
    },
    timeout:7000
  });

  if(!gemRes.error){
    const raw=gemRes.data?.candidates?.[0]?.content?.parts?.[0]?.text||"";
    try{
      const clean=raw.replace(/```json\s*/gi,"").replace(/```\s*/g,"").trim();
      const p=JSON.parse(clean);
      decisao    = p.decisao    || decisao;
      observacao = p.observacao || observacao;
      nivel      = p.nivel      || nivel;
    }catch(e){}
  }
}

// ── 4. Pinar análise no Pinata ───────────────────────────

const pinRes=await Functions.makeHttpRequest({
  url:"https://api.pinata.cloud/pinning/pinJSONToIPFS",
  method:"POST",
  headers:{"Content-Type":"application/json","Authorization":`Bearer ${PINATA_JWT}`},
  data:{
    pinataContent:{
      versao:"5.0", rede:"sepolia",
      timestamp:Math.floor(Date.now()/1000),
      obra:{cidObra, pHash:pHashNovo},
      match:melhorMatch.cid?{cidMatch:melhorMatch.cid,score:melhorMatch.score}:null,
      analise:{modelo:"gemini-2.0-flash",algoritmo:"pHash-DCT-multivariacao",
        decisao, nivel, observacao,
        aviso:"Esta análise é informativa. A decisão final cabe ao autor e profissionais especializados."}
    },
    pinataMetadata:{name:`artechain-v5-${cidObra.slice(0,8)}-${Date.now()}`},
    pinataOptions:{cidVersion:0}
  },
  timeout:7000
});

if(pinRes.error) throw new Error("Pinata error: "+pinRes.message);
const cidAnalise=pinRes.data?.IpfsHash;
if(!cidAnalise) throw new Error("Pinata nao retornou CID");

// ── 5. Retorna APROVADO ou REJEITADO ─────────────────────

const prefixo=decisao==="REJEITADO"?"REJEITADO":"APROVADO";
return Functions.encodeString(`${prefixo}:${cidAnalise}:${pHashNovo}`);
