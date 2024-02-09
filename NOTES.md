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

https://www.erlang.org/doc/man/mnesia#write-1
https://architecturenotes.co/redis/
