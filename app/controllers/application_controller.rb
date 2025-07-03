require "bundler/setup"
require "openai"

class ApplicationController < ActionController::Base
	def home
		render 'home'
	end
	
	def answer
		query = params[:q]
		
		openai = OpenAI::Client.new(
		  api_key: ENV["OPENAI_API_KEY"]
		)
		
		@completion = openai.chat.completions.create(
		  messages: [{role: "system", content: "try to keep answers brief (under 1 or 2 paragraphs)."}, {role: "user", content: query}],
		  model: :"o3-mini"
		)
		
		puts @completion
		
		if @completion && @completion.choices && @completion.choices[0] && @completion.choices[0].message && @completion.choices[0].message.content
			@answer = @completion.choices[0].message.content
		end
		
		render 'answer'
	end
end
