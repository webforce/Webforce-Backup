def time_ago(time) 
  seconds = Time.now - time
  puts seconds
  minutes = seconds / 60
  hours = minutes / 60 
  days = hours / 24
  weeks = days / 7
  years = weeks / 52
  "#{days.round} days / #{hours.round} hours / #{minutes.round} minutes"

end
