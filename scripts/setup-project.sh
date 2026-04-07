#!/usr/bin/env bash
# =============================================================================
# setup-project.sh
# Configura o GitHub Project #3 (Kanban de IC) com colunas corretas,
# cria todas as issues e as adiciona ao projeto na coluna certa.
#
# Pré-requisitos:
#   1. gh CLI instalado e autenticado: gh auth login
#   2. Permissão de escrita no repositório e no projeto
#
# Uso:
#   chmod +x scripts/setup-project.sh
#   ./scripts/setup-project.sh
# =============================================================================

set -euo pipefail

OWNER="gabrrkl7"
REPO="iniciacao-cientifica-engenharia-de-software"
PROJECT_NUMBER=3

echo "=============================================="
echo "  Setup: GitHub Project #3 — Kanban IC"
echo "=============================================="

# ---------------------------------------------------------------------------
# 1. Buscar o node ID do projeto (Projects v2)
# ---------------------------------------------------------------------------
echo ""
echo "🔍 Buscando Project #${PROJECT_NUMBER}..."

PROJECT_ID=$(gh api graphql -f query="
{
  user(login: \"${OWNER}\") {
    projectV2(number: ${PROJECT_NUMBER}) {
      id
      title
    }
  }
}" --jq '.data.user.projectV2.id')

if [[ -z "$PROJECT_ID" ]]; then
  echo "❌ Projeto #${PROJECT_NUMBER} não encontrado para o usuário ${OWNER}."
  echo "   Verifique se o projeto existe e se você tem permissão de acesso."
  exit 1
fi

echo "✅ Projeto encontrado: ID = ${PROJECT_ID}"

# ---------------------------------------------------------------------------
# 2. Buscar o campo Status (campo de coluna/kanban)
# ---------------------------------------------------------------------------
echo ""
echo "🔍 Buscando campo 'Status' do projeto..."

FIELD_INFO=$(gh api graphql -f query="
{
  node(id: \"${PROJECT_ID}\") {
    ... on ProjectV2 {
      fields(first: 20) {
        nodes {
          ... on ProjectV2SingleSelectField {
            id
            name
            options {
              id
              name
            }
          }
        }
      }
    }
  }
}")

STATUS_FIELD_ID=$(echo "$FIELD_INFO" | \
  python3 -c "
import json, sys
data = json.load(sys.stdin)
fields = data['data']['node']['fields']['nodes']
for f in fields:
    if f.get('name') == 'Status':
        print(f['id'])
        break
")

if [[ -z "$STATUS_FIELD_ID" ]]; then
  echo "❌ Campo 'Status' não encontrado. Verifique se o projeto é do tipo Board/Kanban."
  exit 1
fi

echo "✅ Campo Status encontrado: ID = ${STATUS_FIELD_ID}"

# ---------------------------------------------------------------------------
# 3. Ler IDs das opções atuais do campo Status
# ---------------------------------------------------------------------------
echo ""
echo "📋 Opções atuais do campo Status:"
echo "$FIELD_INFO" | python3 -c "
import json, sys
data = json.load(sys.stdin)
fields = data['data']['node']['fields']['nodes']
for f in fields:
    if f.get('name') == 'Status':
        for opt in f.get('options', []):
            print(f\"  - {opt['name']} (id: {opt['id']})\")
"

# ---------------------------------------------------------------------------
# 4. Criar/garantir as 5 colunas corretas
#    As opções do campo SingleSelect em Projects v2 são gerenciadas via UI
#    ou via mutation updateProjectV2Field. Aqui fazemos via mutation.
# ---------------------------------------------------------------------------
echo ""
echo "⚙️  Atualizando colunas do Kanban..."
echo "   ➜ As colunas são gerenciadas como opções do campo 'Status'."
echo "   ➜ Colunas desejadas:"
echo "      📚 A Fazer"
echo "      🔄 Em Andamento"
echo "      👀 Em Revisão"
echo "      ✅ Concluído"
echo "      📑 Submetido/Publicado"
echo ""
echo "   ⚠️  A atualização das opções do campo Status via API GraphQL"
echo "   requer a mutation 'updateProjectV2Field' que está disponível"
echo "   apenas quando as opções precisam ser criadas/renomeadas."
echo "   Execute o seguinte comando para atualizar as opções:"
echo ""

# Lemos os IDs das opções existentes para reutilizá-los
EXISTING_OPTIONS=$(echo "$FIELD_INFO" | python3 -c "
import json, sys
data = json.load(sys.stdin)
fields = data['data']['node']['fields']['nodes']
for f in fields:
    if f.get('name') == 'Status':
        opts = f.get('options', [])
        for o in opts:
            print(o['name'] + '::' + o['id'])
")

# Construir mapeamento de nome -> id
declare -A OPT_MAP
while IFS= read -r line; do
  if [[ -n "$line" ]]; then
    NAME="${line%%::*}"
    ID="${line##*::}"
    OPT_MAP["$NAME"]="$ID"
  fi
done <<< "$EXISTING_OPTIONS"

# As 5 colunas desejadas
DESIRED_COLS=("📚 A Fazer" "🔄 Em Andamento" "👀 Em Revisão" "✅ Concluído" "📑 Submetido/Publicado")

# Verificar quais já existem; criar as que faltam via updateProjectV2Field
OPTIONS_JSON="["
FIRST=true
for COL in "${DESIRED_COLS[@]}"; do
  if [[ -n "${OPT_MAP[$COL]+_}" ]]; then
    ID="${OPT_MAP[$COL]}"
    if [[ "$FIRST" == "false" ]]; then OPTIONS_JSON+=","; fi
    OPTIONS_JSON+="{\"id\":\"${ID}\",\"name\":\"${COL}\",\"color\":\"GRAY\"}"
    FIRST=false
    echo "   ✅ Coluna já existe: ${COL}"
  else
    if [[ "$FIRST" == "false" ]]; then OPTIONS_JSON+=","; fi
    OPTIONS_JSON+="{\"name\":\"${COL}\",\"color\":\"GRAY\"}"
    FIRST=false
    echo "   ➕ Coluna a criar: ${COL}"
  fi
done
OPTIONS_JSON+="]"

# Executar a mutation para atualizar o campo Status com as 5 colunas
UPDATE_RESULT=$(gh api graphql -f query="
mutation {
  updateProjectV2Field(input: {
    projectId: \"${PROJECT_ID}\"
    fieldId: \"${STATUS_FIELD_ID}\"
    singleSelectOptions: ${OPTIONS_JSON}
  }) {
    projectV2Field {
      ... on ProjectV2SingleSelectField {
        id
        name
        options {
          id
          name
        }
      }
    }
  }
}" 2>&1) || true

if echo "$UPDATE_RESULT" | grep -q '"id"'; then
  echo ""
  echo "✅ Colunas atualizadas com sucesso!"
else
  echo ""
  echo "⚠️  Não foi possível atualizar as colunas automaticamente."
  echo "   Acesse: https://github.com/users/${OWNER}/projects/${PROJECT_NUMBER}/settings/fields"
  echo "   e configure manualmente as 5 colunas listadas acima."
fi

# Reler os IDs das colunas após atualização
FIELD_INFO_UPDATED=$(gh api graphql -f query="
{
  node(id: \"${PROJECT_ID}\") {
    ... on ProjectV2 {
      fields(first: 20) {
        nodes {
          ... on ProjectV2SingleSelectField {
            id
            name
            options {
              id
              name
            }
          }
        }
      }
    }
  }
}")

# Construir mapeamento de coluna -> option_id
declare -A COL_OPTION_ID
while IFS= read -r line; do
  if [[ -n "$line" ]]; then
    NAME="${line%%::*}"
    ID="${line##*::}"
    COL_OPTION_ID["$NAME"]="$ID"
  fi
done < <(echo "$FIELD_INFO_UPDATED" | python3 -c "
import json, sys
data = json.load(sys.stdin)
fields = data['data']['node']['fields']['nodes']
for f in fields:
    if f.get('name') == 'Status':
        for opt in f.get('options', []):
            print(opt['name'] + '::' + opt['id'])
")

# ---------------------------------------------------------------------------
# 5. Criar labels
# ---------------------------------------------------------------------------
echo ""
echo "🏷️  Criando labels..."

create_label() {
  local NAME="$1"
  local COLOR="$2"
  local DESC="$3"
  gh label create "$NAME" --color "$COLOR" --description "$DESC" \
    --repo "${OWNER}/${REPO}" 2>/dev/null && \
    echo "   ✅ Label criada: ${NAME}" || \
    echo "   ℹ️  Label já existe: ${NAME}"
}

create_label "planejamento"   "0075ca" "Definição de tema, RQs, hipótese, proposta"
create_label "pesquisa"       "7057ff" "RSL, fichamentos, análise de dados"
create_label "implementação"  "e4e669" "Protótipo, experimento, scripts"
create_label "escrita"        "0e8a16" "Artigo, relatório, apresentação"
create_label "documentação"   "cfd3d7" "README, METODO-DE-TRABALHO, configurações"
create_label "bloqueado"      "d93f0b" "Issue dependente de outra não concluída"

# ---------------------------------------------------------------------------
# 6. Definição das issues
# ---------------------------------------------------------------------------
# Formato: TITULO::CORPO::LABELS::COLUNA
ISSUES=(
  # ── CONCLUÍDO ──────────────────────────────────────────────────────────
  "[PLANEJAMENTO] Definir método de trabalho e estrutura do repositório::[x] Criação do \`METODO-DE-TRABALHO.md\` com abordagem híbrida (Método Científico + Scrum Acadêmico + Kanban).\n[x] Estrutura de pastas do repositório definida.\n\n**Entregável:** \`METODO-DE-TRABALHO.md\` e esqueleto de diretórios do repositório.::planejamento,documentação::✅ Concluído"
  "[PESQUISA] Fichamento — Artigo 1 (artigo científico)::[x] Leitura e fichamento estruturado do primeiro artigo científico relacionado ao tema do projeto.\n\n**Entregável:** \`docs/fichamentos/fichamento_artigo1.pdf\`::pesquisa::✅ Concluído"
  "[PESQUISA] Fichamento — Clean Code (Robert C. Martin)::[x] Leitura e fichamento do livro *Clean Code*, mapeando contribuições relevantes ao tema de pesquisa.\n\n**Entregável:** \`docs/fichamentos/fichamento_clean_code.pdf\`::pesquisa::✅ Concluído"

  # ── EM ANDAMENTO ───────────────────────────────────────────────────────
  "[PESQUISA] Revisão bibliográfica — levantamento inicial de fontes::Busca e seleção de artigos em bases científicas (ACM, IEEE, Google Scholar etc.) relacionados ao tema.\n\n**Entregável:** Lista de fontes candidatas em \`referencias/pdfs/\` e início do arquivo \`.bib\` em \`referencias/bibtex/\`.::pesquisa::🔄 Em Andamento"
  "[PLANEJAMENTO] Configurar gestão de referências no Zotero ou Mendeley::Criar biblioteca no Zotero ou Mendeley, importar as referências levantadas e exportar o arquivo \`.bib\` para o repositório em \`referencias/bibtex/\`.\n\n**Referência:** \`METODO-DE-TRABALHO.md\` (ferramentas utilizadas)\n\n**Entregável:** Arquivo \`.bib\` em \`referencias/bibtex/\`.::planejamento,documentação::🔄 Em Andamento"

  # ── A FAZER ────────────────────────────────────────────────────────────
  "[PLANEJAMENTO] Definir tema e problema de pesquisa::Estabelecer formalmente o tema de pesquisa da IC e redigir o enunciado do problema científico.\n\n**Entregável:** Seção \"Tema e Problema\" no \`README.md\` ou documento dedicado em \`docs/\`.::planejamento::📚 A Fazer"
  "[PLANEJAMENTO] Formular hipótese de pesquisa::Com base no problema definido, formular a hipótese principal (H₀/H₁ ou equivalente) que guiará o experimento.\n\n**Entregável:** Hipótese documentada em \`docs/\` ou \`README.md\`.::planejamento::📚 A Fazer"
  "[PLANEJAMENTO] Definir objetivos geral e específicos::Desdobrar o problema em um objetivo geral e 3–5 objetivos específicos mensuráveis.\n\n**Entregável:** Seção de objetivos documentada em \`docs/\`.::planejamento::📚 A Fazer"
  "[PLANEJAMENTO] Definir Questões de Pesquisa (RQs)::Formular as Research Questions (RQs) que estruturarão a revisão sistemática e o experimento, alinhadas ao problema e hipótese.\n\n**Entregável:** Lista de RQs documentada.::planejamento::📚 A Fazer"
  "[PLANEJAMENTO] Elaborar proposta/projeto de IC::Redigir a proposta formal da IC (ou relatório de início), incluindo tema, problema, hipótese, objetivos, RQs, justificativa e cronograma.\n\n**Entregável:** Documento em \`docs/relatorios/\`.::planejamento,escrita::📚 A Fazer"
  "[PESQUISA] Definir protocolo de revisão sistemática da literatura (RSL)::Criar o protocolo da RSL definindo critérios de inclusão/exclusão, strings de busca, bases de dados e formulário de extração de dados.\n\n**Entregável:** Protocolo documentado em \`docs/\`.::pesquisa::📚 A Fazer"
  "[PESQUISA] Executar revisão sistemática da literatura (RSL)::Aplicar o protocolo, realizar buscas, selecionar e fichar os artigos elegíveis.\n\n**Entregável:** Planilha de seleção + fichamentos em \`docs/fichamentos/\`.::pesquisa::📚 A Fazer"
  "[PESQUISA] Sintetizar referencial teórico::Consolidar as leituras da RSL e fichamentos em um referencial teórico coeso para embasar a metodologia e o experimento.\n\n**Entregável:** Rascunho de seção de referencial teórico em \`docs/artigos/\`.::pesquisa,escrita::📚 A Fazer"
  "[PLANEJAMENTO] Definir metodologia científica do experimento::Escolher e documentar a abordagem metodológica do experimento (ex.: estudo de caso, experimento controlado, survey, análise estática).\n\n**Referência:** \`METODO-DE-TRABALHO.md\` (etapa 4 do Método Científico)\n\n**Entregável:** Documento de metodologia em \`docs/\`.::planejamento::📚 A Fazer"
  "[IMPLEMENTAÇÃO] Projetar e implementar protótipo::Desenvolver o artefato ou protótipo que viabiliza o experimento.\n\n**Entregável:** Código em \`src/prototipo/\`.::implementação::📚 A Fazer"
  "[IMPLEMENTAÇÃO] Planejar e executar experimento::Definir o design experimental, executar os testes/medições e registrar os resultados brutos.\n\n**Entregável:** Scripts em \`src/experimentos/\` e dados em \`data/bruto/\`.::implementação::📚 A Fazer"
  "[PESQUISA] Coletar e tratar dados do experimento::Aplicar limpeza, transformação e pré-processamento nos dados brutos coletados.\n\n**Entregável:** Dados processados em \`data/tratado/\`.::pesquisa::📚 A Fazer"
  "[PESQUISA] Analisar dados e validar resultados::Realizar análise estatística/qualitativa dos dados tratados e validar (ou refutar) a hipótese.\n\n**Referência:** \`METODO-DE-TRABALHO.md\` (etapas 6–7 do Método Científico)\n\n**Entregável:** Relatório de análise em \`docs/relatorios/\`.::pesquisa::📚 A Fazer"
  "[ESCRITA] Redigir artigo científico (rascunho)::Escrever o artigo científico completo (Introdução, Trabalhos Relacionados, Metodologia, Resultados, Discussão, Conclusão).\n\n**Entregável:** Rascunho em \`docs/artigos/\` (preferencialmente Overleaf/LaTeX).::escrita::📚 A Fazer"
  "[ESCRITA] Preparar apresentação final / defesa::Produzir os slides e demais materiais para apresentação da IC ao orientador e banca.\n\n**Entregável:** Slides em \`docs/apresentacoes/\`.::escrita::📚 A Fazer"
  "[ESCRITA] Redigir relatório final de IC::Compor o relatório final institucional da IC, seguindo o formato exigido pela instituição.\n\n**Entregável:** Relatório em \`docs/relatorios/\`.::escrita::📚 A Fazer"
  "[PUBLICAÇÃO] Submeter artigo para publicação::Escolher o venue (conferência ou periódico) e submeter o artigo, acompanhando o processo de revisão.\n\n**Referência:** \`METODO-DE-TRABALHO.md\` (etapa 8 do Método Científico)::escrita::📚 A Fazer"
)

# ---------------------------------------------------------------------------
# 7. Criar issues e adicioná-las ao projeto
# ---------------------------------------------------------------------------
echo ""
echo "📝 Criando issues e adicionando ao projeto..."
echo ""

for ISSUE_DEF in "${ISSUES[@]}"; do
  IFS='::' read -r TITLE BODY LABELS COLUNA <<< "$ISSUE_DEF"

  # Criar a issue
  ISSUE_URL=$(gh issue create \
    --repo "${OWNER}/${REPO}" \
    --title "$TITLE" \
    --body "$(echo -e "$BODY")" \
    --label "$LABELS" \
    2>&1)

  if echo "$ISSUE_URL" | grep -q "https://github.com"; then
    ISSUE_NUMBER=$(echo "$ISSUE_URL" | grep -oP '(?<=/issues/)\d+')
    echo "   ✅ Issue #${ISSUE_NUMBER} criada: ${TITLE}"

    # Obter node ID da issue
    ISSUE_NODE_ID=$(gh api "repos/${OWNER}/${REPO}/issues/${ISSUE_NUMBER}" \
      --jq '.node_id')

    # Adicionar ao projeto
    ITEM_ID=$(gh api graphql -f query="
mutation {
  addProjectV2ItemById(input: {
    projectId: \"${PROJECT_ID}\"
    contentId: \"${ISSUE_NODE_ID}\"
  }) {
    item {
      id
    }
  }
}" --jq '.data.addProjectV2ItemById.item.id' 2>/dev/null) || ITEM_ID=""

    if [[ -n "$ITEM_ID" ]]; then
      # Definir a coluna (Status) do item
      COL_OPT_ID="${COL_OPTION_ID[$COLUNA]:-}"
      if [[ -n "$COL_OPT_ID" ]]; then
        gh api graphql -f query="
mutation {
  updateProjectV2ItemFieldValue(input: {
    projectId: \"${PROJECT_ID}\"
    itemId: \"${ITEM_ID}\"
    fieldId: \"${STATUS_FIELD_ID}\"
    value: { singleSelectOptionId: \"${COL_OPT_ID}\" }
  }) {
    projectV2Item {
      id
    }
  }
}" > /dev/null 2>&1 && \
          echo "      📌 Adicionado ao projeto na coluna: ${COLUNA}" || \
          echo "      ⚠️  Não foi possível definir a coluna. Defina manualmente: ${COLUNA}"
      else
        echo "      ⚠️  ID da coluna '${COLUNA}' não encontrado. Verifique se a coluna foi criada."
      fi
    else
      echo "      ⚠️  Não foi possível adicionar ao projeto. Adicione manualmente."
    fi
  else
    echo "   ❌ Falha ao criar issue: ${TITLE}"
    echo "      Erro: ${ISSUE_URL}"
  fi

  sleep 0.5
done

# ---------------------------------------------------------------------------
# 8. Resumo final
# ---------------------------------------------------------------------------
echo ""
echo "=============================================="
echo "  ✅ Setup concluído!"
echo "=============================================="
echo ""
echo "  Projeto: https://github.com/users/${OWNER}/projects/${PROJECT_NUMBER}"
echo "  Issues:  https://github.com/${OWNER}/${REPO}/issues"
echo ""
echo "  Colunas configuradas:"
echo "    📚 A Fazer"
echo "    🔄 Em Andamento"
echo "    👀 Em Revisão"
echo "    ✅ Concluído"
echo "    📑 Submetido/Publicado"
echo ""
echo "  Se algum item não foi adicionado automaticamente ao projeto,"
echo "  acesse a URL acima e arraste os cards para a coluna correta."
echo "=============================================="
