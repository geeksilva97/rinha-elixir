starta primeiro node
    NODE_NAME=b@localhost iex --sname a@localhost mnesia_demo.ex

starta seuno node
    iex --sname b@localhost mnesia_demo.ex


Em qualquer node:

- MnesiaDemo.run()
- MnesiaDemo.create_mnesia_schema()
- MnesiaDemo.do_some_writes()
- MnesiaDemo.do_some_reads_in_the_other_node()
