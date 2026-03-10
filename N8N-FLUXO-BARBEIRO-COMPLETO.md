# 🤖 Fluxo Completo N8N - Barbeiro (Consulta e Cancelamento)

Fluxo para barbeiros consultarem agendamentos e cancelarem via WhatsApp.

---

## 📊 Visão Geral do Fluxo

```
WhatsApp → N8N Webhook → Identificar Intenção → API (Consultar ou Cancelar) → WhatsApp Resposta
```

---

## 🔧 Estrutura do Workflow N8N

### 1. **Webhook WhatsApp** (Trigger)
Recebe mensagens do barbeiro.

**Configuração:**
- Trigger: Webhook
- Método: POST
- Dados recebidos: `{ "from": "5511999999999", "message": "quais meus agendamentos hoje" }`

---

### 2. **Identificar Barbeiro**
Busca informações do barbeiro pelo telefone.

**Node: HTTP Request**
```
Método: GET
URL: https://vincidentista.vercel.app/api/barbeiros/listar
```

**Code Node (Extrair Barbeiro):**
```javascript
// Encontrar barbeiro pelo telefone
const telefone = $input.item.json.from.replace(/\D/g, ''); // Remove caracteres especiais
const barbeiros = $input.item.json.barbeiros || [];

const barbeiro = barbeiros.find(b =>
  b.telefone.replace(/\D/g, '').includes(telefone.slice(-9)) // Últimos 9 dígitos
);

if (!barbeiro) {
  return {
    json: {
      erro: true,
      mensagem: "Barbeiro não encontrado. Verifique se seu número está cadastrado."
    }
  };
}

return {
  json: {
    barbeiro_id: barbeiro.id,
    barbeiro_nome: barbeiro.nome,
    barbeiro_telefone: barbeiro.telefone
  }
};
```

---

### 3. **Analisar Intenção da Mensagem**

**Code Node (Classificar Intenção):**
```javascript
const mensagem = $input.item.json.message.toLowerCase();

// Extrair intenção
let intencao = 'desconhecido';
let quando = '';
let clienteNome = '';
let hora = '';

// === CONSULTAR AGENDAMENTOS ===
if (mensagem.includes('agendamento') || mensagem.includes('cliente') || mensagem.includes('agenda')) {
  intencao = 'consultar';

  // Detectar "quando"
  if (mensagem.includes('hoje')) {
    quando = 'hoje';
  } else if (mensagem.includes('amanhã') || mensagem.includes('amanha')) {
    quando = 'amanha';
  } else if (mensagem.includes('segunda')) {
    quando = 'segunda';
  } else if (mensagem.includes('terça') || mensagem.includes('terca')) {
    quando = 'terca';
  } else if (mensagem.includes('quarta')) {
    quando = 'quarta';
  } else if (mensagem.includes('quinta')) {
    quando = 'quinta';
  } else if (mensagem.includes('sexta')) {
    quando = 'sexta';
  } else if (mensagem.includes('sábado') || mensagem.includes('sabado')) {
    quando = 'sabado';
  } else if (mensagem.includes('domingo')) {
    quando = 'domingo';
  } else {
    // Tentar extrair data no formato DD/MM
    const dataMatch = mensagem.match(/(\d{1,2})\/(\d{1,2})/);
    if (dataMatch) {
      const dia = dataMatch[1].padStart(2, '0');
      const mes = dataMatch[2].padStart(2, '0');
      const ano = new Date().getFullYear();
      quando = `${dia}/${mes}/${ano}`;
    } else {
      quando = 'hoje'; // Padrão
    }
  }
}

// === CANCELAR AGENDAMENTO ===
else if (mensagem.includes('cancel') || mensagem.includes('desmarc')) {
  intencao = 'cancelar';

  // Extrair nome do cliente
  // Exemplos: "cancela o agendamento do João", "desmarca o Fabio"
  const nomeMatch = mensagem.match(/(?:do|da|de)\s+(\w+)/i);
  if (nomeMatch) {
    clienteNome = nomeMatch[1];
  }

  // Extrair hora
  // Exemplos: "às 14h", "as 14:00", "14h", "14:30"
  const horaMatch = mensagem.match(/(\d{1,2}):?(\d{2})?(?:h|hs)?/);
  if (horaMatch) {
    const horas = horaMatch[1].padStart(2, '0');
    const minutos = horaMatch[2] || '00';
    hora = `${horas}:${minutos}`;
  }
}

return {
  json: {
    intencao: intencao,
    quando: quando,
    cliente_nome: clienteNome,
    hora: hora,
    mensagem_original: $input.item.json.message
  }
};
```

---

### 4. **Switch (IF) - Dividir Fluxo**

**IF Node:**
```
Condição: {{ $json.intencao }}
- Caso 1: "consultar" → Rota para Consultar Agendamentos
- Caso 2: "cancelar" → Rota para Cancelar Agendamento
- Padrão: Mensagem de ajuda
```

---

## 🔍 ROTA 1: Consultar Agendamentos

### HTTP Request - Consultar
```
Método: GET
URL: https://vincidentista.vercel.app/api/barbeiro/agendamentos
Query Parameters:
  - barbeiro: {{ $node["Identificar Barbeiro"].json["barbeiro_id"] }}
  - quando: {{ $node["Analisar Intenção"].json["quando"] }}
Headers:
  - Authorization: Bearer SEU_TOKEN_AQUI
```

**Resposta esperada:**
```json
{
  "success": true,
  "data": {
    "barbeiro": { "id": "...", "nome": "Hiago" },
    "descricao": "hoje (21/12/2024)",
    "total_agendamentos": 3,
    "valor_total": 210.00,
    "agendamentos": [...],
    "mensagem_whatsapp": "📅 *Agendamentos - hoje*\n\n..."
  }
}
```

### WhatsApp - Enviar Resposta
```
Método: Enviar Mensagem
Para: {{ $node["Webhook WhatsApp"].json["from"] }}
Mensagem: {{ $node["HTTP Request - Consultar"].json["data"]["mensagem_whatsapp"] }}
```

---

## ❌ ROTA 2: Cancelar Agendamento

### Opção A: Cancelar com botões (RECOMENDADO)

Se você usar botões interativos no WhatsApp, pode enviar o ID do agendamento direto:

**WhatsApp - Listar com Botões:**
```javascript
// Ao listar agendamentos, criar botões para cancelar
const agendamentos = $node["HTTP Request - Consultar"].json.data.agendamentos;

let mensagem = $node["HTTP Request - Consultar"].json.data.mensagem_whatsapp;
mensagem += "\n\n❌ *Para cancelar:*\n";
mensagem += "Clique no botão do agendamento que deseja cancelar.";

const botoes = agendamentos.map(ag => ({
  id: `cancelar_${ag.id}`,
  title: `Cancelar ${ag.hora} - ${ag.cliente.split(' ')[0]}`
}));

return {
  json: {
    mensagem: mensagem,
    botoes: botoes
  }
};
```

**HTTP Request - Cancelar (com botão):**
```
Método: POST
URL: https://vincidentista.vercel.app/api/barbeiros/cancelar-meu-agendamento
Body:
{
  "agendamento_id": "{{ $json.button_data.split('_')[1] }}"
}
```

---

### Opção B: Cancelar com texto (ALTERNATIVA)

### Validar Dados para Cancelamento
**Code Node:**
```javascript
const clienteNome = $node["Analisar Intenção"].json["cliente_nome"];
const hora = $node["Analisar Intenção"].json["hora"];

if (!clienteNome || !hora) {
  return {
    json: {
      erro: true,
      mensagem: "❌ Para cancelar, preciso do *nome do cliente* e do *horário*.\n\n" +
               "Exemplo: 'Cancela o agendamento do João às 14h'"
    }
  };
}

return {
  json: {
    erro: false,
    cliente_nome: clienteNome,
    hora: hora
  }
};
```

### HTTP Request - Cancelar

**⭐ FORMA 1 - RECOMENDADA (Usando ID do agendamento):**
```
Método: POST
URL: https://vincidentista.vercel.app/api/barbeiros/cancelar-meu-agendamento
Headers:
  - Content-Type: application/json
Body (JSON):
{
  "agendamento_id": "{{ $json["agendamento_id"] }}"
}
```

**FORMA 2 - ALTERNATIVA (Usando nome e hora):**
```
Método: POST
URL: https://vincidentista.vercel.app/api/barbeiros/cancelar-meu-agendamento
Headers:
  - Content-Type: application/json
Body (JSON):
{
  "barbeiro_nome": "{{ $node["Identificar Barbeiro"].json["barbeiro_id"] }}",
  "cliente_nome": "{{ $node["Validar Dados"].json["cliente_nome"] }}",
  "hora": "{{ $node["Validar Dados"].json["hora"] }}"
}
```

**Resposta esperada:**
```json
{
  "success": true,
  "message": "Agendamento cancelado com sucesso!",
  "data": {
    "agendamento_id": "...",
    "cliente": "João Silva",
    "data": "21/12/2024",
    "hora": "14:00",
    "valor": 70.00,
    "mensagem_whatsapp": "✅ *Agendamento cancelado com sucesso!*\n\n..."
  }
}
```

### WhatsApp - Enviar Confirmação
```
Método: Enviar Mensagem
Para: {{ $node["Webhook WhatsApp"].json["from"] }}
Mensagem: {{ $node["HTTP Request - Cancelar"].json["data"]["mensagem_whatsapp"] }}
```

---

## 🆘 ROTA 3: Mensagem de Ajuda (Padrão)

**Code Node - Mensagem de Ajuda:**
```javascript
return {
  json: {
    mensagem: "🤖 *Olá! Sou seu assistente virtual.*\n\n" +
              "📋 *Comandos disponíveis:*\n\n" +
              "▫️ Ver agendamentos:\n" +
              "   • 'Meus agendamentos hoje'\n" +
              "   • 'Agenda de amanhã'\n" +
              "   • 'Clientes na terça'\n" +
              "   • 'Agenda do dia 25/12'\n\n" +
              "▫️ Cancelar agendamento:\n" +
              "   • 'Cancela o agendamento do João às 14h'\n" +
              "   • 'Desmarca o cliente Fabio das 10:30'\n\n" +
              "💡 Como posso ajudar?"
  }
};
```

**WhatsApp - Enviar Ajuda:**
```
Método: Enviar Mensagem
Para: {{ $node["Webhook WhatsApp"].json["from"] }}
Mensagem: {{ $node["Mensagem de Ajuda"].json["mensagem"] }}
```

---

## 🎯 Exemplos de Uso

### Exemplo 1: Consultar agendamentos de hoje
**Barbeiro envia:**
```
Quais meus agendamentos hoje?
```

**Bot responde:**
```
📅 *Agendamentos - hoje (21/12/2024)*

👤 *Barbeiro:* Hiago
📊 *Total:* 3 agendamento(s)
💰 *Valor total:* R$ 210.00

─────────────────

*1. 09:00* - João Silva
   📞 11999999999
   ✂️ Corte + Barba
   💵 R$ 70.00

*2. 11:00* - Maria Santos
   📞 11988888888
   ✂️ Corte Feminino
   💵 R$ 80.00

*3. 14:00* - Carlos Oliveira
   📞 11977777777
   ✂️ Barba Completa
   💵 R$ 60.00
```

---

### Exemplo 2: Consultar próxima terça
**Barbeiro envia:**
```
Quantos clientes tenho na terça?
```

**Bot responde:**
```
📅 *Agendamentos - terça-feira (24/12/2024)*

👤 *Barbeiro:* Hiago
📊 *Total:* 5 agendamento(s)
💰 *Valor total:* R$ 350.00

[... lista de agendamentos ...]
```

---

### Exemplo 3: Cancelar agendamento
**Barbeiro envia:**
```
Cancela o agendamento do João às 14h
```

**Bot responde:**
```
✅ *Agendamento cancelado com sucesso!*

📅 *Data:* 21/12/2024
🕐 *Hora:* 14:00
👤 *Cliente:* João Silva
📞 *Telefone:* 11999999999
💵 *Valor:* R$ 70.00

O cliente será notificado sobre o cancelamento.
```

---

### Exemplo 4: Erro ao cancelar (faltam dados)
**Barbeiro envia:**
```
Cancela o João
```

**Bot responde:**
```
❌ Para cancelar, preciso do *nome do cliente* e do *horário*.

Exemplo: 'Cancela o agendamento do João às 14h'
```

---

## 📝 Configurações Importantes

### Token de Autorização
A API `/api/barbeiro/agendamentos` requer autenticação:

```
Headers:
  Authorization: Bearer SEU_TOKEN_AQUI
```

Obter o token:
1. Acesse o dashboard da dentista
2. Vá em Configurações → API
3. Copie o token

### Webhook WhatsApp
Configure o webhook do WhatsApp para apontar para o N8N:
- URL: `https://seu-n8n.com/webhook/barbeiro`
- Método: POST

---

## 🔄 Fluxograma Completo

```
┌─────────────────┐
│ WhatsApp Trigger│
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│Identificar      │
│Barbeiro (API)   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│Analisar Intenção│
│(Code Node)      │
└────────┬────────┘
         │
         ▼
    ┌────┴────┐
    │  SWITCH │
    └─┬───┬───┬┘
      │   │   │
  ┌───┘   │   └───┐
  │       │       │
  ▼       ▼       ▼
┌────┐ ┌────┐ ┌────┐
│CON │ │CAN │ │HLP │
│SUL │ │CEL │ │    │
│TAR │ │AR  │ │    │
└─┬──┘ └─┬──┘ └─┬──┘
  │      │      │
  ▼      ▼      ▼
┌─────────────────┐
│WhatsApp Response│
└─────────────────┘
```

---

## 🛠️ Troubleshooting

### Erro: "Barbeiro não encontrado"
- Verifique se o telefone está cadastrado no sistema
- Confira se o barbeiro está ativo (`ativo = true`)

### Erro: "Agendamento não encontrado" (ao cancelar)
- Verifique se o nome do cliente está correto
- Confirme o horário (formato HH:MM)
- Certifique-se que o agendamento é de hoje (ou passe a data)

### Erro: "Token inválido"
- Verifique se o token está correto no header Authorization
- Formato: `Bearer SEU_TOKEN` (com espaço após "Bearer")

---

## ✅ Checklist de Implementação

- [ ] Criar workflow no N8N
- [ ] Configurar webhook do WhatsApp
- [ ] Adicionar token de autorização nas requisições
- [ ] Testar consulta de agendamentos
- [ ] Testar cancelamento de agendamento
- [ ] Configurar mensagem de ajuda
- [ ] Testar com barbeiro real
- [ ] Monitorar logs de erro

---

## 📚 APIs Utilizadas

1. **GET `/api/barbeiros/listar`**
   - Lista todos os barbeiros
   - Usado para identificar barbeiro pelo telefone

2. **GET `/api/barbeiro/agendamentos`** ⭐
   - Consulta agendamentos com linguagem natural
   - Parâmetros: `barbeiro` (UUID ou nome), `quando` (hoje, terca, etc.)

3. **POST `/api/barbeiros/cancelar-meu-agendamento`**
   - Cancela agendamento do barbeiro
   - Body: `barbeiro_nome`, `cliente_nome`, `hora`, `data` (opcional)

---

**Documentação gerada em:** 21/12/2024
**Versão:** 1.0
