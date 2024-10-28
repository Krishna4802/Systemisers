require 'net/http'
require 'json'
require 'base64'

API_KEY = '3dd8cf07c2d4a7bf40f1510b587dd390'

# Function to create a task
def create_task(image_path)
  # Read the image file and convert it to Base64
  image_data = Base64.strict_encode64(File.read(image_path))

  # Prepare the request payload
  request_payload = {
    clientKey: API_KEY,
    task: {
      type: 'ImageToTextTask',
      body: image_data
    }
  }.to_json

  # Make the HTTP POST request to create the task
  uri = URI('https://freecaptchabypass.com/createTask')
  response = Net::HTTP.post(uri, request_payload, 'Content-Type' => 'application/json')
  
  # Parse the response JSON
  result = JSON.parse(response.body)
  
  # Check if there was an error
  if result['errorId'] != 0
    puts "Error creating task: #{result['errorDescription']}"
    return nil
  end
  
  # Return the task ID
  result['taskId']
end

# Function to get the task result
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
        sleep(5) # Wait before retrying
        next
      else
        puts "Max retries reached. Could not get task result."
        return nil
      end
    end

    # Check if there's an error in the response
    if result['errorId'] != 0
      puts "Error getting task result: #{result['errorDescription']}"
      return nil
    end

    # If the status is 'ready', return the solution
    return result['solution']['text'] if result['status'] == 'ready'

    # Wait before checking again
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
