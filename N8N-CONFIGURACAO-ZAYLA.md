# 🔧 CONFIGURAÇÃO N8N - ZAYLA SECRETÁRIA
**Guia completo de configuração dos nós HTTP**

---

## 📋 ÍNDICE
1. [Variáveis de Ambiente](#variáveis-de-ambiente)
2. [Workflow Completo](#workflow-completo)
3. [Configuração de Cada Nó HTTP](#configuração-de-cada-nó-http)
4. [Testes e Validação](#testes-e-validação)

---

## 🌐 VARIÁVEIS DE AMBIENTE

### Criar no n8n:

1. **BASE_URL**
   ```
   https://vincidentista.vercel.app
   ```

2. **API_TOKEN**
   ```
   Bearer SEU_TOKEN_AQUI
   ```
   *(Substitua `SEU_TOKEN_AQUI` pelo token real do Supabase Service Role Key)*

3. **TIMEOUT_API**
   ```
   10000
   ```
   *(10 segundos em milissegundos)*

---

## 🔄 WORKFLOW COMPLETO

```
┌─────────────────────┐
│  WhatsApp Trigger   │
│  (mensagem recebida)│
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Extrair Telefone   │
│  (Set node)         │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  HTTP 1: BUSCAR     │◄─── Token obrigatório
│  CLIENTE            │
│  (GET /historico)   │
└──────────┬──────────┘
           │
           ▼
      ┌────┴────┐
      │   IF    │
      │ Existe? │
      └────┬────┘
           │
    ┌──────┴──────┐
    │             │
    ▼             ▼
┌───────┐    ┌───────────┐
│EXISTE │    │NÃO EXISTE │
│       │    │           │
└───┬───┘    └─────┬─────┘
    │              │
    │              ▼
    │    ┌─────────────────┐
    │    │ Coletar Dados   │
    │    │ (aguardar msgs) │
    │    └────────┬────────┘
    │             │
    │             ▼
    │    ┌─────────────────┐
    │    │  HTTP 2: CRIAR  │◄─── Token obrigatório
    │    │  CLIENTE        │
    │    │  (POST /criar)  │
    │    └────────┬────────┘
    │             │
    └─────────────┴─────────
                  │
                  ▼
        ┌──────────────────┐
        │ Cliente pergunta │
        │ sobre...?        │
        └────────┬─────────┘
                 │
       ┌─────────┼─────────┬────────┐
       │         │         │        │
       ▼         ▼         ▼        ▼
    ┌─────┐ ┌───────┐ ┌───────┐ ┌──────┐
    │Serv.│ │Planos │ │Barbs. │ │Atua. │
    └──┬──┘ └───┬───┘ └───┬───┘ └───┬──┘
       │        │         │         │
       ▼        ▼         ▼         ▼
   ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐
   │HTTP 3│ │HTTP 4│ │HTTP 5│ │HTTP 6│
   │Listar│ │Listar│ │Listar│ │Atua. │
   │Serv. │ │Plano │ │Barb. │ │Cli.  │
   │      │ │      │ │      │ │      │
   │SEM   │ │COM   │ │SEM   │ │COM   │
   │TOKEN │ │TOKEN │ │TOKEN │ │TOKEN │
   └───┬──┘ └───┬──┘ └───┬──┘ └───┬──┘
       │        │         │         │
       └────────┴─────────┴─────────┘
                  │
                  ▼
        ┌──────────────────┐
        │ Quer agendar?    │
        └────────┬─────────┘
                 │
                 ▼
        ┌──────────────────┐
        │ Atualizar setor  │
        │ → "agendamento"  │
        └────────┬─────────┘
                 │
                 ▼
        ┌──────────────────┐
        │ Transferir para  │
        │ Agente Agendamento│
        └──────────────────┘
```

---

## 🔧 CONFIGURAÇÃO DE CADA NÓ HTTP

### **NÓ HTTP 1: BUSCAR CLIENTE**

**Nome do nó:** `HTTP - Buscar Cliente`

**Configurações básicas:**
- **Method:** `GET`
- **URL:** `{{ $env.BASE_URL }}/api/clientes/historico`
- **Authentication:** `Header Auth`
- **Timeout:** `{{ $env.TIMEOUT_API }}`

**Query Parameters:**
```json
{
  "telefone": "{{ $node['Extrair Telefone'].json['telefone'] }}"
}
```

**Headers:**
```json
{
  "Authorization": "{{ $env.API_TOKEN }}",
  "Content-Type": "application/json"
}
```

**Options:**
- ✅ Continue on Fail: `true` (para tratar erro 404)
- ✅ Ignore SSL Issues: `false`

**Response:**
- **Success (200):** Cliente encontrado → Seguir para conversa contextualizada
- **Not Found (404):** Cliente novo → Seguir para coleta de dados
- **Error (401/403):** Problema de autenticação → Avisar usuário

---

### **NÓ HTTP 2: CRIAR CLIENTE**

**Nome do nó:** `HTTP - Criar Cliente`

**Configurações básicas:**
- **Method:** `POST`
- **URL:** `{{ $env.BASE_URL }}/api/clientes/criar`
- **Authentication:** `Header Auth`
- **Timeout:** `{{ $env.TIMEOUT_API }}`

**Headers:**
```json
{
  "Authorization": "{{ $env.API_TOKEN }}",
  "Content-Type": "application/json"
}
```

**Body (JSON):**
```json
{
  "nome_completo": "{{ $node['Processar Dados'].json['nome_completo'] }}",
  "telefone": "{{ $node['Extrair Telefone'].json['telefone'] }}",
  "email": "{{ $node['Processar Dados'].json['email'] }}",
  "data_nascimento": "{{ $node['Processar Dados'].json['data_nascimento'] }}",
  "profissional_preferido": "{{ $node['Processar Dados'].json['barbeiro_preferido'] }}",
  "observacoes": "{{ $node['Processar Dados'].json['observacoes_completas'] }}",
  "gosta_conversar": {{ $node['Processar Dados'].json['gosta_conversar'] }},
  "como_soube": "{{ $node['Processar Dados'].json['como_soube'] }}"
}
```

**⚠️ IMPORTANTE:**
- `data_nascimento` deve estar no formato `YYYY-MM-DD`
- `gosta_conversar` é boolean (true/false), não string
- `observacoes` deve conter TUDO: alergias, preferências, tratamento

**Options:**
- ✅ Continue on Fail: `true`
- Response: JSON

---

### **NÓ HTTP 3: LISTAR SERVIÇOS**

**Nome do nó:** `HTTP - Listar Serviços`

**Configurações básicas:**
- **Method:** `GET`
- **URL:** `{{ $env.BASE_URL }}/api/servicos`
- **Authentication:** `None` ⚠️ **NÃO PRECISA TOKEN**
- **Timeout:** `{{ $env.TIMEOUT_API }}`

**Headers:**
```json
{
  "Content-Type": "application/json"
}
```

**Options:**
- Response: JSON
- Continue on Fail: `false`

**Processamento da resposta:**

Use um nó `Code` para formatar:

```javascript
const servicos = $input.all()[0].json;

let mensagem = "Nossos principais serviços ✂️:\n\n";

servicos.forEach(servico => {
  mensagem += `💈 *${servico.nome}* - R$ ${servico.preco.toFixed(2)} (${servico.duracao_minutos}min)\n`;
  if (servico.descricao) {
    mensagem += `   ${servico.descricao}\n`;
  }
  mensagem += `\n`;
});

mensagem += "Qual te interessa? 😊";

return { mensagem, servicos };
```

---

### **NÓ HTTP 4: LISTAR PLANOS**

**Nome do nó:** `HTTP - Listar Planos`

**Configurações básicas:**
- **Method:** `GET`
- **URL:** `{{ $env.BASE_URL }}/api/planos/listar`
- **Authentication:** `Header Auth` ⚠️ **PRECISA TOKEN**
- **Timeout:** `{{ $env.TIMEOUT_API }}`

**Query Parameters:**
```json
{
  "ativo": "true"
}
```

**Headers:**
```json
{
  "Authorization": "{{ $env.API_TOKEN }}",
  "Content-Type": "application/json"
}
```

**Processamento da resposta:**

Use um nó `Code` para formatar:

```javascript
const response = $input.all()[0].json;
const planos = response.planos;

let mensagem = "Temos pacotes com desconto! 💎\n\n";

planos.forEach(plano => {
  const descontoPercent = ((plano.economia / plano.valor_original) * 100).toFixed(0);

  mensagem += `📦 *${plano.nome}*\n`;
  mensagem += `   • R$ ${plano.valor_total.toFixed(2)} (de R$ ${plano.valor_original.toFixed(2)})\n`;
  mensagem += `   • Economia de R$ ${plano.economia.toFixed(2)} (${descontoPercent}% off)\n`;
  mensagem += `   • Válido por ${plano.validade_dias} dias\n`;
  mensagem += `\n`;
});

mensagem += "Te interessa algum? 😊";

return { mensagem, planos };
```

---

### **NÓ HTTP 5: LISTAR BARBEIROS**

**Nome do nó:** `HTTP - Listar Barbeiros`

**Configurações básicas:**
- **Method:** `GET`
- **URL:** `{{ $env.BASE_URL }}/api/barbeiros/listar`
- **Authentication:** `None` ⚠️ **NÃO PRECISA TOKEN**
- **Timeout:** `{{ $env.TIMEOUT_API }}`

**Query Parameters:**
```json
{
  "ativo": "true"
}
```

**Headers:**
```json
{
  "Content-Type": "application/json"
}
```

**Processamento da resposta:**

Use um nó `Code` para formatar:

```javascript
const response = $input.all()[0].json;
const barbeiros = response.barbeiros;

let mensagem = "Nossos barbeiros 💈:\n\n";

barbeiros.forEach(barbeiro => {
  const especialidades = barbeiro.especialidades.join(', ');

  mensagem += `👨‍🦱 *${barbeiro.nome}*\n`;
  mensagem += `   • Especialista em ${especialidades}\n`;
  mensagem += `   • ${barbeiro.estatisticas.atendimentos_hoje} atendimentos hoje\n`;
  mensagem += `\n`;
});

mensagem += "💡 *Rodízio automático:* Se não tiver preferência, o sistema escolhe o barbeiro com menos atendimentos!\n\n";
mensagem += "Tem preferência? 😊";

return { mensagem, barbeiros, proximo_rodizio: response.proximo_rodizio };
```

---

### **NÓ HTTP 6: ATUALIZAR CLIENTE**

**Nome do nó:** `HTTP - Atualizar Cliente`

**Configurações básicas:**
- **Method:** `POST`
- **URL:** `{{ $env.BASE_URL }}/api/clientes/atualizar`
- **Authentication:** `Header Auth` ⚠️ **PRECISA TOKEN**
- **Timeout:** `{{ $env.TIMEOUT_API }}`

**Headers:**
```json
{
  "Authorization": "{{ $env.API_TOKEN }}",
  "Content-Type": "application/json"
}
```

**Body (JSON):**
```json
{
  "telefone": "{{ $node['Extrair Telefone'].json['telefone'] }}",
  "email": "{{ $node['Novos Dados'].json['email'] }}",
  "profissional_preferido": "{{ $node['Novos Dados'].json['barbeiro_preferido'] }}",
  "observacoes": "{{ $node['Novos Dados'].json['observacoes'] }}"
}
```

**⚠️ IMPORTANTE:**
- Enviar apenas os campos que o cliente quer atualizar
- Não enviar campos vazios ou null

---

## 🧪 TESTES E VALIDAÇÃO

### **Checklist de Testes:**

#### ✅ **Teste 1: Cliente Novo**

**Input:**
- WhatsApp: "Olá, quanto custa um corte?"
- Telefone: 11999999999 (não cadastrado)

**Esperado:**
1. GET /api/clientes/historico → 404
2. Bot pede dados de cadastro
3. Cliente envia dados
4. POST /api/clientes/criar → 200
5. Bot confirma cadastro

**Validar:**
- [ ] Token enviado no header
- [ ] JSON no formato correto (sem `preferencias` aninhado)
- [ ] Data de nascimento no formato YYYY-MM-DD
- [ ] Cliente criado no Supabase

---

#### ✅ **Teste 2: Cliente Existente**

**Input:**
- WhatsApp: "Oi, me fala os serviços"
- Telefone: 11988888888 (já cadastrado)

**Esperado:**
1. GET /api/clientes/historico → 200 com dados
2. Bot saúda pelo nome
3. GET /api/servicos → 200
4. Bot mostra lista formatada

**Validar:**
- [ ] Token enviado em /historico
- [ ] Nome do cliente aparece na saudação
- [ ] Serviços vêm da API (não hardcoded)
- [ ] Preços formatados corretamente

---

#### ✅ **Teste 3: Listar Planos**

**Input:**
- "Me fala sobre os pacotes"

**Esperado:**
1. GET /api/planos/listar?ativo=true → 200
2. Bot formata com desconto calculado

**Validar:**
- [ ] Token enviado
- [ ] Cálculo de desconto correto
- [ ] Formatação bonita

---

#### ✅ **Teste 4: Erro de Autenticação**

**Input:**
- Token inválido ou expirado

**Esperado:**
1. API retorna 401/403
2. Bot avisa: "Desculpe, estou com dificuldade..."

**Validar:**
- [ ] Bot não trava
- [ ] Mensagem amigável ao usuário
- [ ] Log do erro para debug

---

### **Comandos de Debug:**

**No n8n, adicionar nó "Set" após cada HTTP para logar:**

```json
{
  "api_chamada": "{{ $node['HTTP X'].name }}",
  "status_code": "{{ $node['HTTP X'].statusCode }}",
  "resposta": "{{ $node['HTTP X'].json }}",
  "erro": "{{ $node['HTTP X'].error }}",
  "timestamp": "{{ $now.toISO() }}"
}
```

---

## 📊 MONITORAMENTO

### **Métricas para acompanhar:**

1. **Taxa de sucesso das APIs:**
   - Buscar Cliente: > 98%
   - Criar Cliente: > 95%
   - Listar Serviços: > 99%

2. **Tempo de resposta:**
   - Todas as APIs < 2s

3. **Erros mais comuns:**
   - 404 em Buscar Cliente (normal para novos)
   - 409 em Criar Cliente (já existe)
   - 401/403 (token inválido)

4. **Taxa de conversão:**
   - % de clientes qualificados que passaram para agendamento

---

## 🔒 SEGURANÇA

### **⚠️ NUNCA:**

❌ Commitar token no código
❌ Logar token completo (apenas últimos 4 dígitos)
❌ Compartilhar token em mensagens

### **✅ SEMPRE:**

✅ Usar variáveis de ambiente
✅ Rotacionar token periodicamente
✅ Monitorar uso de API
✅ Validar entrada do usuário antes de enviar

---

## 📝 TROUBLESHOOTING

### **Problema: Erro 401 "Token não fornecido"**

**Solução:**
- Verificar se `Authentication` está em `Header Auth`
- Verificar nome do header: `Authorization`
- Verificar formato: `Bearer SEU_TOKEN` (com espaço após Bearer)

---

### **Problema: Erro 409 "Cliente já cadastrado"**

**Solução:**
- Normal! Significa que cliente já existe
- Fazer GET /api/clientes/historico em vez de criar
- Atualizar fluxo para tratar esse cenário

---

### **Problema: Data de nascimento inválida**

**Solução:**
- Cliente envia: DD/MM/AAAA
- Converter para: YYYY-MM-DD
- Exemplo: 15/05/1990 → 1990-05-15

**Código para converter:**
```javascript
const [dia, mes, ano] = dataNascimento.split('/');
const dataFormatada = `${ano}-${mes}-${dia}`;
```

---

### **Problema: JSON inválido**

**Solução:**
- Não usar `preferencias` aninhado
- Usar campos diretos da API
- Validar antes de enviar

**❌ Errado:**
```json
{
  "preferencias": {
    "barbeiro_preferido": "Alex"
  }
}
```

**✅ Correto:**
```json
{
  "profissional_preferido": "Alex"
}
```

---

## ✅ CHECKLIST FINAL

Antes de colocar em produção:

- [ ] Todas as variáveis de ambiente configuradas
- [ ] Token válido e testado
- [ ] Todos os 6 nós HTTP configurados
- [ ] Autenticação correta (com/sem token)
- [ ] Testes com cliente novo passando
- [ ] Testes com cliente existente passando
- [ ] Tratamento de erros implementado
- [ ] Logs configurados
- [ ] Timeout configurado (10s)
- [ ] Continue on Fail nos lugares certos

---

**🎯 FIM DA CONFIGURAÇÃO N8N**

**Última atualização:** 15/12/2025
**Versão:** 1.0
