require 'open-uri'
require_relative "../services/open_ai_client"

def download_audio(url, dest_path)
  URI.open(url, "rb") do |remote|
	File.open(dest_path, "wb") { |f| f.write(remote.read) }
  end
  dest_path
rescue OpenURI::HTTPError, SocketError, Timeout::Error => e
  Rails.logger.error("Failed to download #{url}: #{e}")
  nil
end

class CallController < ActionController::Base
	protect_from_forgery with: :null_session
	
	def index
		twiml = Twilio::TwiML::VoiceResponse.new do |r|
		  r.say(message: "Hello, ask your question and press the pound key.")
		  r.record(timeout: 5, finishOnKey: "#", recordingStatusCallbackEvent: "completed")
		end
		render xml: twiml.to_s
	end
	
	def answer_query
		recording_url = params["RecordingUrl"]
		local_file_name = Rails.root.join("tmp", File.basename(URI.parse(recording_url).path + ".wav"))
		sleep 3.0
		file = download_audio(recording_url, local_file_name)
		transcription = OpenAIClient.new.transcribe(file)
		File.delete(local_file_name) if File.exist?(local_file_name)
		prompt = """
		#{transcription}
		===
		Answer with 2 sentences max.
		"""
		answer = OpenAIClient.new.chat(
			[
				{ role: "user", content: prompt }
			]
		)
		twiml = Twilio::TwiML::VoiceResponse.new do |r|
			r.say(message: answer)
			r.hangup
		end
		render xml: twiml.to_s
	end
end