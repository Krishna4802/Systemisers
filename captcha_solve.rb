require 'net/http'
require 'json'
require 'base64'

API_KEY = '3dd8cf07c2d4a7bf40f1510b587dd390'

def create_task(image_path)
  image_data = Base64.strict_encode64(File.read(image_path))

  request_payload = {
    clientKey: API_KEY,
    task: {
      type: 'ImageToTextTask',
      body: image_data
    }
  }.to_json

  uri = URI('https://freecaptchabypass.com/createTask')
  response = Net::HTTP.post(uri, request_payload, 'Content-Type' => 'application/json')
  
  result = JSON.parse(response.body)
  
  if result['errorId'] != 0
    puts "Error creating task: #{result['errorDescription']}"
    return nil
  end
  
  result['taskId']
end

def get_task_result(task_id, retries = 3)
  uri = URI('https://freecaptchabypass.com/getTaskResult')
  request_payload = { clientKey: API_KEY, taskId: task_id }.to_json
  attempt = 0

  loop do
    attempt += 1
    response = Net::HTTP.post(uri, request_payload, 'Content-Type' => 'application/json')
    
    puts "Response body: #{response.body}"
    
    begin
      result = JSON.parse(response.body)
    rescue JSON::ParserError => e
      puts "Failed to parse JSON on attempt #{attempt}: #{e.message}"
      if attempt < retries
        sleep(5) 
        next
      else
        puts "Max retries reached. Could not get task result."
        return nil
      end
    end

    if result['errorId'] != 0
      puts "Error getting task result: #{result['errorDescription']}"
      return nil
    end

    return result['solution']['text'] if result['status'] == 'ready'

    sleep(5)
  end
end


image_path = '/Users/krishnaprasath/Systemisers/Learnings/captcha.png'
task_id = create_task(image_path)

if task_id
  puts "Task created successfully with ID: #{task_id}"
  solution = get_task_result(task_id)
  
  if solution
    puts "CAPTCHA solved: #{solution}"
  else
    puts "Failed to solve CAPTCHA."
  end
else
  puts "Failed to create CAPTCHA task."
end
