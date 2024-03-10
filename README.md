# Rinha de Backend Q1 2024 - Ruby

Projeto criado para participar da rinha de backend do Q1 2024.

Tecnologias:

- Ruby
- Rack
- Nginx
- PostgreSQL

Requisitos:

- Docker

Como rodar:

```bash
docker-compose up
```

A aplicação estará disponível para requisições na URL http://localhost:9999 com os seguintes endpoints:

```
GET /clientes/:id/extrato
```

```
POST /clientes/:id/transacoes

{
    "valor": 100000,
    "tipo" : "c",
    "descricao" : "descricao"
}
```
