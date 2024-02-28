require "bundler/setup"
Bundler.require(:default)

class ConnectionManager
  @pool = nil

  class << self
    def connection_pool
      @pool || create_pool
    end

    private

    def create_pool
      @pool = ConnectionPool.new(size: 30, timeout: 30) do
        PG.connect(ENV["DATABASE_URL"])
      end
    end
  end
end

class Rinha2024Application
  def call(env)
    request = Rack::Request.new(env)
    path = request.path
    method = request.request_method
    body = request.body.read
    headers = { "Content-Type" => "application/json" }
    status = 200
    response_body = ''

    first_path = path.split("/")[1]
    third_path = path.split("/")[3]
    account_id = path.split("/")[2].to_i
    status = 404 if account_id.zero?
    return [status, headers, [response_body]] if status != 200

    ConnectionManager.connection_pool.with do |conn|
      account = get_balance(conn, account_id)
      status = 404 if account.nil?
      return [status, headers, [response_body]] if status != 200

      balance = account["balance"].to_i
      credit_limit = account["credit_limit"].to_i

      if method == "GET" && first_path == "clientes" && third_path == "extrato"
        last_transactions = get_last_10_transactions(conn, account_id).map do |transaction|
          {
            valor: transaction["amount"].to_i,
            tipo: transaction["kind"],
            descricao: transaction["description"],
            realizada_em: transaction["created_at"]
          }
        end

        response_body = {
          saldo: {
            total: balance,
            limite: credit_limit
          },
          ultimas_transacoes: last_transactions
        }.to_json
      end

      if method == "POST" && first_path == "clientes" && third_path == "transacoes"
        parsed_body = JSON.parse(body)

        unless valid_transaction?(parsed_body)
          return [422, headers, [{ error: "Corpo da requisição inválido" }.to_json]]
        end

        if balance - parsed_body["valor"].to_i < -1 * credit_limit && parsed_body["tipo"] == "d"
          return [422, headers, [{ error: "Crédito insuficiente" }.to_json]]
        end

        conn.transaction do
          create_transaction(conn, account_id, parsed_body)
          account = get_balance(conn, account_id)

          response_body = { saldo: account["balance"].to_i, limite: account["credit_limit"].to_i }.to_json
        end
      end
    end

    [status, headers, [response_body]]
  end

  private

  def create_transaction(conn, account_id, body)
    query = "INSERT INTO ledgers (account_id, amount, kind, description) VALUES ($1, $2, $3, $4)"
    conn.exec_params(query, [account_id, body["valor"], body["tipo"], body["descricao"]])
  end

  def get_balance(conn, account_id)
    query = "SELECT balance, credit_limit FROM accounts WHERE id = $1 LIMIT 1"
    conn.exec_params(query, [account_id]).first
  end

  def valid_transaction?(transaction)
    if transaction["valor"].nil? || transaction["tipo"].nil? || transaction["descricao"].nil?
      return false
    end

    return false unless transaction["valor"].respond_to?(:to_f)

    amount = transaction["valor"].to_f

    return false if amount.numerator > amount.to_i

    amount.to_i.positive? &&
      %w[d c].include?(transaction["tipo"]) &&
      transaction["descricao"].is_a?(String) &&
      transaction["descricao"].length.positive? && transaction["descricao"].length <= 10
  end

  def get_last_10_transactions(conn, account_id)
    query = "SELECT * FROM ledgers WHERE account_id = $1 ORDER BY created_at DESC LIMIT 10"
    conn.exec_params(query, [account_id]).to_a
  end
end
