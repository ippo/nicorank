#!/usr/bin/env ruby

min5  = 60 * 5
min30 = 60 * 30
hour8 = 60 * 60 * 8
hour9 = 60 * 60 * 9
hour_shift = 60 * 60 * 3 # 9:00 + 3:00 = 12:00(or 20:00 or 4:00)
flag = false
flag = true if ARGV[0] == 'force'

loop{
  now = Time.now
  $stderr.puts "now  #{now.to_s}"
  step = Time.at ((now - hour_shift).to_f / hour8).round * hour8 + hour_shift
  flag = true if (now - step).abs <= min30

  if flag
    system "./bin/day_count.rb"
    flag = false
  end
  now = Time.now
  next_step = Time.at ((now - hour_shift).to_f / hour8).ceil * hour8 + hour_shift + min5
  $stderr.puts "now  #{now.to_s}"
  $stderr.puts "next #{next_step.to_s}"
  $stderr.puts "sleep #{(next_step - now).to_i / 60}min."
  sleep (next_step - now).to_i
}
