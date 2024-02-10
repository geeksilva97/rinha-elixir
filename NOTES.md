# Só um journal

- quero mesmo é fazer um cluster erlang com os dois nós que vao subir
- minha ideia é ver isso funcionando e poder rodar um teste primeiro ento vou fazer single node com Mnesia distribuído
- nao tenho ideia de como faz essa desgraça, mas vamos que vamos
    - uma outra ideia que tive foi de ter uma tabela de eventos pra cada client, assim as escritas/leituras ficam
        distrbuídas, pode ser uma boa, mas tenho que testar

- endpoint de POST funciona o caso mais trivial. Vou seguir com a ideia do cluster Erlang e deixar que o mnesia se vire
    com condicoes de corrida. Vou evitar dirty_writes pelo menos pra tentar manter uma consistencia


- concluí os endpoints
- o estado nos genservers nao vai ter como ficar como está, vou criar uma tabela no mesnia só para projecoes, assim ela
    fica distribuida
- to lembrando agora que eu realmente comecei assim pra fazer funcionar e a que a ideia é se valer da distrbuicao do
    mnesia mesmo
- Penso em algo como
    - tabela em disco para armazenar os logs 
    - tabela em memoria que fica com a projecao
        - aqui penso em uma tabela por cliente pra evitar ainda mais as condicoes de corrida

- A vida de vez em quando te bate com o tijolo na cabeça. Desgraca do mnesia nao tava funcionando, nao criava os schemas
    nem as tabelas
- Depois de um tempo descobri que era porque, devido à configuração do mix, o :mnesia já começava startado - deve ter um
    jeito de por na lista, mas sem iniciar.
- Pra resolver garanti que o mnesia estava parado, fazendo um :rpc.multicall(cluster_nodes(), :mnesia, :stop, [])
- Deixando esse link só pra caso eu precise setar o diretorio do Mnesia
    -[https://stackoverflow.com/questions/40357730/how-to-start-an-iex-session-with-cookie-and-erl-options](https://stackoverflow.com/questions/40357730/how-to-start-an-iex-session-with-cookie-and-erl-options)


- Funcionou! o mnesia ta distribuido entre os nodes
- Os endpoints foram reescritos para usar o mnesia
-   - ainda preciso centralizar, tem muito codigo do tipo Mnesia.write por aí. Isso pode ficar uma abstracao como
      BalanceAggregatMnesia.add_saldo(id)
- agora pretendo fazer uns testes iniciais com as restricoes dadas. 
-
- Antes de enviar tenho de lembrar de:
    - remover os logs
    - remover o observer das deps
    - Gerar imagem como release
- Ainda, imagino que tenho de ajustar os volumes do docker... tirar aquele binding
- Será que vale a pena usar unix sockets no nginx?... vamo ver

https://www.erlang.org/doc/man/mnesia#write-1
https://architecturenotes.co/redis/
