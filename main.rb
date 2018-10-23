require 'json'
require 'net/http'
investimenti = []

file = File.read 'bondora.json'
config = JSON.parse(file)

def do_bid_secondario (config, investimento) 
  uri = URI('https://api.bondora.com/api/v1/secondarymarket/buy')
  uri.port = 443
  headers = {
    'Authorization' => config['AuthorizationCode'],
    'Content-Type' => 'application/json',
    'Accept' => 'application/json, text/json, application/xml, text/xml'
  }
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  req = { ItemIds: [investimento]}.to_json
  res = http.post(uri.path, req, headers)
  if res.code == '202'
    puts "Investimento effettuato"
  else
    puts JSON.pretty_generate(JSON.parse(res.body))
  end
end

def getloans_secondario (config, investimenti)
  uri = URI('https://api.bondora.com/api/v1/secondarymarket?request.Countries=' << config['country'] << '&request.ShowMyItems=' << config['showmyitems'] << '&request.Ratings=' << config['ratings'] << '&request.CreditScoreMin=' << config['creditScoreMin'] << '&request.incomeVerificationStatus=' << config['incomeVerificationStatus'] << '&request.PriceMax=' << config['pricemax'] << '&request.LoanStatusCode=' << config['LoanStatusCode'])
  uri.port=443
  req = Net::HTTP::Get.new(uri)
  req['Authorization'] = config["AuthorizationCode"]
  res = Net::HTTP.start(uri.hostname, uri.port, :use_ssl => uri.scheme == 'https') {|http|
    http.request(req)
  }
  if res.code == '200' 
    infoloans = JSON.parse(res.body)
      infoloans['Payload'].each do |child|
        if child['Xirr'] > 10 && child['TotalCost'] < 1 && child['NrOfScheduledPayments'] <= 36 
          investimenti.push(child['Id'])
  
        end
      end
   return 0
  else
    puts JSON.pretty_generate(JSON.parse(res.body))
    return 1
  end
end


def get_balance(config)
  uri = URI('https://api.bondora.com/api/v1/account/balance')
  uri.port = 443
  req = Net::HTTP::Get.new(uri)
  req['Authorization'] = config["AuthorizationCode"]
  res = Net::HTTP.start(uri.hostname, uri.port, :use_ssl => uri.scheme == 'https') {|http|
  http.request(req)
}

  if res.code == '200'
    data2 = JSON.parse(res.body)
    return data2['Payload']['Balance']
  else
    puts JSON.pretty_generate(JSON.parse(res.body))
    return 1
  end
end

#puts get_balance(config)
getloans_secondario(config, investimenti)

investimenti.each do |investimento|
  do_bid_secondario(config, investimento)
  if get_balance(config) < 1
    puts "Errore bilancio troppo basso"
    exit
  end
  #Avoid API calls quota exceeded
  sleep(2)
end

