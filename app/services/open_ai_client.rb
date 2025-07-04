require "net/http"
require "json"
require "uri"

class OpenAIClient
  ENDPOINT = URI("https://api.openai.com/v1/responses")
  TRANSCRIPTIONS_ENDPOINT = URI("https://api.openai.com/v1/audio/transcriptions")

  def initialize(api_key: ENV.fetch("OPENAI_API_KEY"))
	@api_key = api_key
  end
  
  def transcribe(file, model: "gpt-4o-transcribe")
	request = Net::HTTP::Post.new(TRANSCRIPTIONS_ENDPOINT.request_uri)
	request["Authorization"] = "Bearer #{ENV.fetch('OPENAI_API_KEY')}"
	request["Content-Type"] = "Content-Type: multipart/form-data"
	form_data = [
		["file",  File.open(file, "rb")],
		["model", model]
	  ]
  	request.set_form(form_data, "multipart/form-data")
	response = Net::HTTP.start(TRANSCRIPTIONS_ENDPOINT.hostname, TRANSCRIPTIONS_ENDPOINT.port, use_ssl: true) do |http|
	  http.request(request)
	end
	body = JSON.parse(response.body)
	return body.dig("text")
  end

  def chat(input, model: "gpt-4.1", tools: [{"type": "web_search_preview"}], temperature: 0.5)
	http   = Net::HTTP.new(ENDPOINT.host, ENDPOINT.port)
	http.use_ssl = true

	request = Net::HTTP::Post.new(ENDPOINT.request_uri, default_headers)
	request.body = { 
		model:,
		input:, 
		tools:,
		temperature:
	}.to_json

	response = http.request(request)
	handle_response(response)
  end

  private

  def default_headers
	{
	  "Content-Type"  => "application/json",
	  "Authorization" => "Bearer #{@api_key}"
	}
  end

  def handle_response(response)
	body = JSON.parse(response.body)

	case response
	when Net::HTTPSuccess
	  array = body.dig("output")
	  array.each do |item|
		  if item.dig("content", 0, "text")
			  return item.dig("content", 0, "text")
		  end
	  end
	  return "An error occurred."
	else
	  raise OpenAIError.new(body["error"]["messages"], response.code)
	end
  end

  class OpenAIError < StandardError
	attr_reader :status
	def initialize(message, status) = super(message).tap { @status = status }
  end
end