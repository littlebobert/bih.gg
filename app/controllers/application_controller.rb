require "net/http"
require "json"
require "uri"

class OpenAIClient
  ENDPOINT = URI("https://api.openai.com/v1/responses")

  def initialize(api_key: ENV.fetch("OPENAI_API_KEY"))
	@api_key = api_key
  end

  def chat(input, model: "o4-mini", tools: [{"type": "web_search_preview"}])
	http   = Net::HTTP.new(ENDPOINT.host, ENDPOINT.port)
	http.use_ssl = true

	request = Net::HTTP::Post.new(ENDPOINT.request_uri, default_headers)
	request.body = { model:, input:, tools: }.to_json

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

class CustomRender < Redcarpet::Render::HTML
  def paragraph(text)
	text
  end
end

class ApplicationController < ActionController::Base
	
	def markdown(text)
		options = {
		  filter_html: true,
		  hard_wrap: true,
		  link_attributes: { rel: 'nofollow', target: "_blank" },
		  space_after_headers: true,
		  fenced_code_blocks: true
		}
		renderer = CustomRender.new(options)
		markdown = Redcarpet::Markdown.new(renderer, extensions = {})
		markdown.render(text).html_safe
    end
	
	def home
		render 'home'
	end
	
	def answer
		query = params[:query]
		
		answer = OpenAIClient.new.chat(
			[{role: "system", content: "Try to keep answers brief (under 1 or 2 paragraphs)."},
			{role: "user", content: query}]
		)
		
		@answer = markdown(answer)
		
		render "answer"
	end
end
