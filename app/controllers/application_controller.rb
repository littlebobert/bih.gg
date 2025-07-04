require_relative "../services/open_ai_client.rb"

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
		
		answer = OpenAiClient.new.chat(
			[{role: "system", content: "Try to keep answers brief (under 1 or 2 paragraphs)."},
			{role: "user", content: query}]
		)
		
		@answer = markdown(answer)
		
		render "answer"
	end
end
