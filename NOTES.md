# Só um journal

- quero mesmo é fazer um cluster erlang com os dois nós que vao subir
- minha ideia é ver isso funcionando e poder rodar um teste primeiro ento vou fazer single node com Mnesia distribuído
- nao tenho ideia de como faz essa desgraça, mas vamos que vamos
    - uma outra ideia que tive foi de ter uma tabela de eventos pra cada client, assim as escritas/leituras ficam
        distrbuídas, pode ser uma boa, mas tenho que testar

- endpoint de POST funciona o caso mais trivial. Vou seguir com a ideia do cluster Erlang e deixar que o mnesia se vire
    com condicoes de corrida. Vou evitar dirty_writes pelo menos pra tentar manter uma consistencia

https://www.erlang.org/doc/man/mnesia#write-1
https://architecturenotes.co/redis/
