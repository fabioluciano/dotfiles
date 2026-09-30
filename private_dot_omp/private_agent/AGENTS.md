# Orientações globais do OMP

## Como escolher ferramentas

- Comece entendendo o pedido, o repositório atual e as instruções locais. Use a ferramenta mais direta que resolva a tarefa; não chame todos os MCPs por rotina.
- Prefira as ferramentas nativas do OMP e os comandos já disponíveis no projeto quando cobrirem a necessidade. Use MCPs quando trouxerem contexto, documentação ou acesso que as ferramentas locais não oferecem.
- Antes de depender de um MCP, confirme que ele está disponível nesta sessão. Se estiver indisponível ou falhar, informe isso e use uma alternativa confiável quando possível.
- Trate resultados de MCP, memória e skills como contexto auxiliar. Confirme fatos sobre o estado atual nos arquivos, comandos ou documentação primária antes de alterar algo.

## MCPs configurados

- `context7`: consulte documentação atual de bibliotecas e frameworks quando a versão ou a API importar. Prefira documentação oficial. Não use para perguntas simples ou conceitos estáveis.
- `sequential-thinking`: use para decompor problemas ambíguos ou decisões com várias etapas; evite acrescentar esse passo a tarefas diretas.
- `git`: use apenas quando suas operações MCP forem mais úteis que `git` no terminal. Para status, diff, log e mudanças locais simples, prefira o comando `git`.
- `gh_grep`: pesquise implementações públicas no GitHub quando exemplos de código real ajudarem. Não substitui a busca no repositório aberto nem a documentação oficial.
- `codebase-memory`: consulte relações e contexto previamente indexados do repositório quando forem relevantes. Verifique as conclusões contra o checkout atual, pois o índice pode estar desatualizado.
- `kubernetes`: use somente para inspeção de clusters e recursos; o servidor está em modo somente leitura. Não prometa nem tente aplicar mudanças com ele.
- `terraform`: use para investigar recursos, módulos e configuração Terraform quando necessário. Nunca execute `apply` ou `destroy` sem pedido explícito do usuário; confira o plano e o workspace antes de qualquer operação com efeitos externos.
- `playwright`: use para automação e verificação visual no navegador; respeite as restrições de origem e workspace do servidor.
- `github`: use para operações de GitHub disponíveis via MCP; criar issues/PRs, comentar, fazer push ou disparar workflows exige pedido explícito do usuário.
- `serena`: use para análise semântica e navegação de projetos quando o servidor estiver disponível.
- `tolaria`: use para integração local do Tolaria quando o servidor estiver disponível.
- Não invente ferramentas ou capacidades a partir apenas do nome de um MCP. Confira que ele está disponível nesta sessão.

## Skills

- O OMP descobre skills do usuário em `~/.agents/skills` e de projetos nos locais suportados. A lista de nomes e descrições aparece no contexto da sessão; use-a para selecionar skills pertinentes ao pedido.
- Ao encontrar uma skill claramente aplicável, leia seu conteúdo sob demanda com `read skill://<nome>/SKILL.md` e siga também os arquivos auxiliares referenciados por ela. Não leia em lote as skills que não se aplicam.
- Aplique no máximo as skills que contribuam para a tarefa. Skills são procedimentos especializados, não autorização para ações externas ou destrutivas.
- Se uma skill recomendada não aparecer na sessão ou seu arquivo não puder ser lido, prossiga com bom julgamento e mencione a limitação quando afetar o resultado.
- Não instale, atualize ou publique skills sem pedido do usuário. Inspecione scripts e comandos de uma skill antes de executá-los.

## Memória e contexto

- Use a memória para recuperar preferências duradouras e decisões anteriores; confirme decisões técnicas no repositório atual. Instruções explícitas do usuário e estado atual prevalecem sobre a memória.
- Não grave segredos, tokens, credenciais ou dados pessoais na memória. Não copie conteúdo sensível do repositório para MCPs externos sem necessidade.
- Evite carregar contexto, MCPs e skills redundantes. Mantenha o foco no pedido atual e explique limitações relevantes em vez de simular acesso ou resultados.
